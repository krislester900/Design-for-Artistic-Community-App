"""
Train SDXL LoRA — tout en fp16, 8-bit Adam, gradient clipping.
"""
import json, os, requests, gc
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

SUPABASE_URL = "https://wzewlweghntnqyfvhgan.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6ZXdsd2VnaG50bnF5ZnZoZ2FuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTAwOTgzMSwiZXhwIjoyMDk2NTg1ODMxfQ.9dK3ytQBBulDTx0MHdD5qY5M0BGpCJ6wOw-V3Oh5pEM"

def fetch_references(style_slug: str):
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    mapping = {"masashi-kishimoto": 4, "tite-kubo": 1, "akira-toriyama": 5, "junji-ito": 7}
    sid = mapping.get(style_slug)
    if sid is None: raise ValueError(f"Unknown style: {style_slug}")
    q = f"/rest/v1/ai_manga_references?select=id,image_url,style_id&style_id=eq.{sid}&limit=500"
    r = requests.get(SUPABASE_URL + q, headers=headers); r.raise_for_status()
    return r.json()

def download_images(refs, out_dir: Path):
    os.makedirs(out_dir, exist_ok=True)
    captions, downloaded = [], 0
    def dl_one(ref):
        url = ref["image_url"]
        ext = url.split(".")[-1].split("?")[0][:4]
        if ext not in ("png", "jpg", "jpeg", "webp"): ext = "jpg"
        fname = f"{ref['id']:05d}.{ext}"
        path = out_dir / fname
        if path.exists(): return fname, True
        try:
            r = requests.get(url, timeout=30); r.raise_for_status()
            with open(path, "wb") as f: f.write(r.content)
            return fname, True
        except: return fname, False
    with ThreadPoolExecutor(max_workers=8) as ex:
        futures = {ex.submit(dl_one, r): r for r in refs}
        for f in as_completed(futures):
            fname, ok = f.result()
            if ok:
                downloaded += 1
                captions.append(f'{{"image": "{fname}", "caption": "masterpiece, best quality, naruto manga panel art style by Masashi Kishimoto, manga panel, monochrome, lineart, screentone"}}')
    with open(out_dir / "metadata.jsonl", "w") as f: f.write("\n".join(captions))
    return downloaded

def train():
    import torch, gc
    from accelerate import Accelerator
    from accelerate.utils import ProjectConfiguration
    from diffusers import AutoencoderKL, DDPMScheduler, UNet2DConditionModel
    from diffusers.optimization import get_scheduler
    from peft import LoraConfig
    from torch.utils.data import Dataset, DataLoader
    from PIL import Image
    from transformers import CLIPTokenizer, CLIPTextModel, CLIPTextModelWithProjection
    import numpy as np
    import bitsandbytes as bnb

    device = torch.device("cuda")
    gb = torch.cuda.get_device_properties(0).total_memory / 1e9
    print(f"Device: {device} | VRAM: {gb:.1f}GB")

    out = Path("C:/Users/PC/Downloads/Design for Artistic Community App/training/naruto")

    class MangaDataset(Dataset):
        def __init__(self, img_dir, size=512):
            self.img_dir = Path(img_dir); self.size = size; self.images = []
            cf = self.img_dir / "metadata.jsonl"
            if cf.exists():
                with open(cf) as f:
                    for line in f:
                        e = json.loads(line); p = self.img_dir / e["image"]
                        if p.exists():
                            try: Image.open(p).verify(); self.images.append((str(p), e["caption"]))
                            except: pass
            else:
                for f in sorted(self.img_dir.glob("*.*")):
                    if f.suffix.lower() in (".png", ".jpg", ".jpeg", ".webp"):
                        try: Image.open(str(f)).verify(); self.images.append((str(f), ""))
                        except: pass
        def __len__(self): return len(self.images)
        def __getitem__(self, idx):
            p, cap = self.images[idx]
            img = Image.open(p).convert("RGB")
            w, h = img.size; s = min(w, h)
            img = img.crop(((w-s)//2, (h-s)//2, (w+s)//2, (h+s)//2))
            img = img.resize((self.size, self.size), Image.LANCZOS)
            arr = np.array(img).astype(np.float32) / 127.5 - 1.0
            t = torch.from_numpy(arr).permute(2, 0, 1).float()
            out = {"pixel_values": t, "original_size": (h, w)}
            if hasattr(self, "prompt_embeds"):
                out["prompt_embeds"] = self.prompt_embeds[idx]
                out["pooled_embeds"] = self.pooled_embeds[idx]
            return out

    # ── Download if missing ──
    if not list(out.glob("*.jpg")) and not list(out.glob("*.png")):
        print("Downloading images from Supabase...")
        refs = fetch_references("masashi-kishimoto")
        n = download_images(refs, out)
        print(f"Downloaded {n} images")
    else:
        print(f"Images already present in {out}")

    dataset = MangaDataset(out, size=512)
    if len(dataset) < 10: print(f"Not enough ({len(dataset)})"); return
    print(f"Dataset: {len(dataset)} images")

    # ── Pre-encode captions ──
    tokenizer = CLIPTokenizer.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="tokenizer")
    tokenizer_2 = CLIPTokenizer.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="tokenizer_2")
    noise_scheduler = DDPMScheduler.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="scheduler")

    tc1 = CLIPTextModel.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="text_encoder", torch_dtype=torch.float16).to(device)
    tc2 = CLIPTextModelWithProjection.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="text_encoder_2", torch_dtype=torch.float16).to(device)
    print("Pre-encoding captions...")
    caps = [dataset.images[i][1] for i in range(len(dataset))]
    embeds, pooled = [], []
    for i in range(0, len(caps), 8):
        bc = caps[i:i+8]
        toks = tokenizer(bc, padding="max_length", max_length=77, truncation=True, return_tensors="pt").input_ids.to(device)
        toks2 = tokenizer_2(bc, padding="max_length", max_length=77, truncation=True, return_tensors="pt").input_ids.to(device)
        with torch.no_grad():
            pe = tc1(toks)[0].cpu().float()
            o2 = tc2(toks2)
            pe2 = o2.last_hidden_state.cpu().float()
            po = o2.text_embeds.cpu().float()
        embeds.append(torch.cat([pe, pe2], dim=-1)); pooled.append(po)
    dataset.prompt_embeds = torch.cat(embeds)
    dataset.pooled_embeds = torch.cat(pooled)
    del tc1, tc2; gc.collect(); torch.cuda.empty_cache()

    def collate_fn(batch):
        return {
            "pixel_values": torch.stack([b["pixel_values"] for b in batch]),
            "prompt_embeds": torch.stack([b["prompt_embeds"] for b in batch]),
            "pooled_embeds": torch.stack([b["pooled_embeds"] for b in batch]),
            "original_size": [b["original_size"] for b in batch],
        }

    loader = DataLoader(dataset, batch_size=1, shuffle=True, num_workers=0, collate_fn=collate_fn)

    # ── VAE fp16 ──
    vae = AutoencoderKL.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="vae", torch_dtype=torch.float16)
    vae.requires_grad_(False); vae.eval()

    # ── UNet fp16 + LoRA fp16 (pas de mixing !) ──
    print("Loading UNet fp16 + LoRA...")
    unet = UNet2DConditionModel.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="unet", torch_dtype=torch.float16)
    unet.requires_grad_(False)
    unet.add_adapter(LoraConfig(r=32, lora_alpha=32,
        target_modules=["to_q", "to_k", "to_v", "to_out.0", "ff.net.0.proj", "ff.net.2"],
        lora_dropout=0.1, bias="none"))
    # LoRA reste en fp16 (identique au base model)
    unet.enable_gradient_checkpointing()
    unet.train()
    n_trainable = sum(p.numel() for p in unet.parameters() if p.requires_grad)
    print(f"Trainable: {n_trainable} params ({n_trainable*4/1e6:.1f}MB)")

    opt = bnb.optim.Adam8bit(filter(lambda p: p.requires_grad, unet.parameters()), lr=5e-5, weight_decay=1e-2)
    sched = get_scheduler("constant", optimizer=opt, num_warmup_steps=50, num_training_steps=len(loader)*15)

    accelerator = Accelerator(gradient_accumulation_steps=1,
        project_config=ProjectConfiguration(project_dir=str(out / "logs")))
    unet, opt, loader, sched = accelerator.prepare(unet, opt, loader, sched)
    vae = vae.to(accelerator.device)

    print(f"VRAM used: {torch.cuda.memory_allocated(0)/1e9:.2f}GB")
    print("Starting training (15 epochs, 512px, tout fp16)...")

    step = 0
    for epoch in range(15):
        for batch in loader:
            with accelerator.accumulate(unet):
                px = batch["pixel_values"].to(accelerator.device, dtype=torch.float16)
                eh = batch["prompt_embeds"].to(accelerator.device, dtype=torch.float16)
                pp = batch["pooled_embeds"].to(accelerator.device, dtype=torch.float16)
                osz = batch["original_size"]

                with torch.no_grad():
                    lat = vae.encode(px).latent_dist.sample() * vae.config.scaling_factor

                noise = torch.randn_like(lat)
                ts = torch.randint(0, noise_scheduler.config.num_train_timesteps, (lat.shape[0],), device=lat.device).long()
                nlat = noise_scheduler.add_noise(lat, noise, ts)

                tid = torch.tensor([[h, w, 0, 0, 512, 512] for h, w in osz], dtype=torch.long, device=accelerator.device)
                ac = {"text_embeds": pp, "time_ids": tid}

                pred = unet(nlat, ts, eh, added_cond_kwargs=ac).sample

                loss = torch.nn.functional.mse_loss(pred.float(), noise.float())

                accelerator.backward(loss)
                # Gradient clipping for stability
                torch.nn.utils.clip_grad_norm_(unet.parameters(), max_norm=1.0)
                opt.step()
                sched.step()
                opt.zero_grad()

            step += 1
            if step % 50 == 0: print(f"  step {step} | loss: {loss.item():.6f}")
            if step == 1: is_nan = "OK" if not torch.isnan(loss) else "NAN"; print(f"  First step loss: {loss.item():.6f} [{is_nan}]")

        print(f"Epoch {epoch+1}/15 done")

    save_path = out / "lora_weights"
    accelerator.unwrap_model(unet).save_pretrained(str(save_path))
    print(f"Saved to {save_path}")
    print("✅ Training complete!")

if __name__ == "__main__":
    train()
