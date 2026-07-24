"""
SDXL LoRA training — clean version, PyTorch AMP, gradient scaling.
UNet fp16 + LoRA fp32 = stable training via GradScaler.
"""
import json, os, requests, gc
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

SUPABASE_URL = "https://wzewlweghntnqyfvhgan.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6ZXdsd2VnaG50bnF5ZnZoZ2FuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTAwOTgzMSwiZXhwIjoyMDk2NTg1ODMxfQ.9dK3ytQBBulDTx0MHdD5qY5M0BGpCJ6wOw-V3Oh5pEM"

def download_images(out_dir: Path, style="masashi-kishimoto"):
    os.makedirs(out_dir, exist_ok=True)
    mapping = {"masashi-kishimoto": 4, "tite-kubo": 1, "akira-toriyama": 5, "junji-ito": 7}
    sid = mapping.get(style)
    if sid is None: raise ValueError(f"Unknown style: {style}")
    headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}
    q = f"/rest/v1/ai_manga_references?select=id,image_url,style_id&style_id=eq.{sid}&limit=500"
    refs = requests.get(SUPABASE_URL + q, headers=headers).json()
    captions, downloaded = [], 0
    def dl_one(ref):
        url = ref["image_url"]
        ext = (url.split(".")[-1].split("?")[0][:4]) or "jpg"
        if ext not in ("png", "jpg", "jpeg", "webp"): ext = "jpg"
        fname = f"{ref['id']:05d}.{ext}"; path = out_dir / fname
        if path.exists(): return fname, True
        try:
            r = requests.get(url, timeout=30); r.raise_for_status()
            with open(path, "wb") as f: f.write(r.content)
            return fname, True
        except: return fname, False
    with ThreadPoolExecutor(max_workers=8) as ex:
        for f in as_completed({ex.submit(dl_one, r): r for r in refs}):
            fname, ok = f.result()
            if ok:
                downloaded += 1
                captions.append(f'{{"image":"{fname}","caption":"naruto manga panel by Masashi Kishimoto, masterpiece, best quality, monochrome, lineart, screentone"}}')
    with open(out_dir / "metadata.jsonl", "w") as f: f.write("\n".join(captions))
    print(f"Downloaded {downloaded}/{len(refs)} images")

def train():
    import torch, gc
    import torch.nn as nn
    from torch.utils.data import Dataset, DataLoader
    from torch.amp import autocast, GradScaler
    from diffusers import AutoencoderKL, DDPMScheduler, UNet2DConditionModel
    from diffusers.optimization import get_scheduler
    from peft import LoraConfig, get_peft_model_state_dict
    from PIL import Image
    from transformers import CLIPTokenizer, CLIPTextModel, CLIPTextModelWithProjection
    import numpy as np

    device = torch.device("cuda")
    gb = torch.cuda.get_device_properties(0).total_memory / 1e9
    print(f"Device: {device} | VRAM: {gb:.1f}GB")

    out = Path("C:/Users/PC/Downloads/Design for Artistic Community App/training/naruto")

    # ── Dataset ──
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
            out_d = {"px": t, "original_size": (h, w)}
            if hasattr(self, "embeds"):
                out_d["eh"] = self.embeds[idx]; out_d["pool"] = self.pooled[idx]
            return out_d

    # Download + load dataset
    if not list(out.glob("*.jpg")) and not list(out.glob("*.png")):
        download_images(out)
    dataset = MangaDataset(out, size=512)
    if len(dataset) < 10: print(f"Not enough ({len(dataset)})"); return
    print(f"Dataset: {len(dataset)} images 512x512")

    # ── Pre-encode text ──
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
        with torch.no_grad(), autocast(device_type="cuda"):
            pe = tc1(toks)[0].cpu().float()
            o2 = tc2(toks2)
            pe2 = o2.last_hidden_state.cpu().float()
            po = o2.text_embeds.cpu().float()
        embeds.append(torch.cat([pe, pe2], dim=-1)); pooled.append(po)
    dataset.embeds = torch.cat(embeds); dataset.pooled = torch.cat(pooled)
    del tc1, tc2; gc.collect(); torch.cuda.empty_cache()

    def collate_fn(batch):
        return {
            "px": torch.stack([b["px"] for b in batch]),
            "eh": torch.stack([b["eh"] for b in batch]),
            "pool": torch.stack([b["pool"] for b in batch]),
            "osz": [b["original_size"] for b in batch],
        }

    # ── Models ──
    vae = AutoencoderKL.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="vae", torch_dtype=torch.float32)
    vae.requires_grad_(False); vae.eval(); vae.to(device)

    unet = UNet2DConditionModel.from_pretrained("stabilityai/stable-diffusion-xl-base-1.0", subfolder="unet", torch_dtype=torch.float16)
    unet.requires_grad_(False)
    unet.add_adapter(LoraConfig(r=32, lora_alpha=32,
        target_modules=["to_q", "to_k", "to_v", "to_out.0", "ff.net.0.proj", "ff.net.2"],
        lora_dropout=0.1, bias="none"))
    # UNet → fp16, LoRA → fp32 (via autocast, pas de mix manuel)
    unet.enable_gradient_checkpointing()
    unet.train()
    n_t = sum(p.numel() for p in unet.parameters() if p.requires_grad)
    print(f"Trainable: {n_t} params ({n_t*4/1e6:.1f}MB)")
    for p in unet.parameters():
        if p.requires_grad: p.data = p.data.float()

    opt = torch.optim.AdamW(filter(lambda p: p.requires_grad, unet.parameters()), lr=5e-5, weight_decay=1e-2)
    scaler = GradScaler(device="cuda")
    loader = DataLoader(dataset, batch_size=4, shuffle=True, num_workers=0, collate_fn=collate_fn)
    sched = get_scheduler("constant", optimizer=opt, num_warmup_steps=50, num_training_steps=len(loader)*10)

    unet.to(device)
    print(f"VRAM: {torch.cuda.memory_allocated(0)/1e9:.2f}GB")

    # ── Train ──
    n_epochs = 10
    print(f"Starting ({n_epochs} epochs, 512px, AMP GradScaler)...")
    step = 0
    for epoch in range(n_epochs):
        for batch in loader:
            px = batch["px"].to(device, dtype=torch.float16)
            eh = batch["eh"].to(device, dtype=torch.float16)
            pool = batch["pool"].to(device, dtype=torch.float16)
            osz = batch["osz"]

            with torch.no_grad():
                latents = vae.encode(px.float()).latent_dist.sample() * vae.config.scaling_factor
                latents = latents.half()

            noise = torch.randn_like(latents)
            ts = torch.randint(0, noise_scheduler.config.num_train_timesteps, (latents.shape[0],), device=device).long()
            noisy = noise_scheduler.add_noise(latents, noise, ts)

            tid = torch.tensor([[h, w, 0, 0, 512, 512] for h, w in osz], dtype=torch.long, device=device)

            with autocast(device_type="cuda"):
                pred = unet(noisy, ts, eh, added_cond_kwargs={"text_embeds": pool, "time_ids": tid}).sample
                loss = torch.nn.functional.mse_loss(pred.float(), noise.float())

            scaler.scale(loss).backward()
            scaler.unscale_(opt)
            torch.nn.utils.clip_grad_norm_(unet.parameters(), max_norm=1.0)
            scaler.step(opt)
            scaler.update()
            opt.zero_grad()

            step += 1
            if step == 1: print(f"  First loss: {loss.item():.6f}")
            if step % 50 == 0: print(f"  step {step} | loss: {loss.item():.6f}")

        print(f"Epoch {epoch+1}/10 done")
        if (epoch + 1) % 5 == 0:
            ckpt = out / f"lora_ckpt_epoch{epoch+1}"
            ckpt.mkdir(parents=True, exist_ok=True)
            torch.save(get_peft_model_state_dict(unet), str(ckpt / "lora_weights.pth"))
            print(f"  Saved checkpoint")

    final_dir = out / "lora_final"
    final_dir.mkdir(parents=True, exist_ok=True)
    torch.save(get_peft_model_state_dict(unet), str(final_dir / "lora_weights.pth"))
    print("Done!")

if __name__ == "__main__":
    train()
