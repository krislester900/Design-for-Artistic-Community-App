// Scénario (Groq), prompts SDXL, et génération des références personnage.
// Dépend de Groq (scripts) et Replicate (réfs) → isolé du reste.

import { makeLogger, withRetry } from "../logger.ts";
import { PanelScript, Character } from "../types.ts";
import { POSES } from "./pose.ts";
import { replicatePredict, SDXL, REPLICATE_API_KEY } from "../replicate.ts";

export async function generatePanelScripts(scene: string, characters: Character[], panelCount: number): Promise<PanelScript[]> {
  const log = makeLogger("generatePanelScripts");
  const groqKey = Deno.env.get("GROQ_API_KEY") ?? "";
  if (!groqKey) {
    log.warn("GROQ_API_KEY manquante, fallback scripts");
    return generateFallbackScripts(scene, panelCount);
  }

  try {
    const charSection = characters.length > 0
      ? "PERSONNAGES :\n" + characters.map((c, i) =>
        `${i + 1}. ${c.name} — ${c.appearance}`
      ).join("\n")
      : "Pas de personnages définis.";

    const poseKeys = Object.keys(POSES).filter(k => !k.startsWith("interact-")).join(", ");
    const interactKeys = Object.keys(POSES).filter(k => k.startsWith("interact-")).join(", ");

    const systemPrompt = `Tu es un **scénariste et storyboarder manga** expert (style gekiga/shonen/seinen).
Tu découpes une scène en EXACTEMENT ${panelCount} cases pour une planche de manga.

RÈGLES NARRATIVES MANGA :
- Case 1 : plan d'ensemble ou d'ambiance (établir le lieu, la météo, l'émotion)
- Cases 2 à ${panelCount - 1} : montée dramatique, alterner plans larges et gros plans
- Dernière case : climax ou cliffhanger (gros plan ou plan large poignant)
- Utiliser le rythme : 1 case = 1 action principale
- **Actions dynamiques** : varie les poses (saut, esquive, coup de poing, coup de pied, garde, etc.)
- **Perspective** : utilise low-angle et worm pour des plans dramatiques et puissants; high-angle/bird pour la vulnérabilité
- **Interactions** : si 2 personnages s'affrontent, utilise une pose d'interaction : ${interactKeys}

Pour CHAQUE case, fournis ces champs :
- scene : description visuelle du décor + action + émotion (riche, sensorielle)
- characters : nom du/des personnages présents + leur état émotionnel
- dialogue : réplique en français (vide si case muette)
- narration : texte de narration/hors-champ (vide si pas de narration)
- framing : wide | medium | close-up | extreme-close-up
- camera_angle : eye-level | high-angle | low-angle | bird | worm
- emotion : l'émotion dominante de la case
- action : l'action principale en 1 phrase courte, avec verbe d'action fort
- pose_description : choisir PARMI cette liste (la plus proche de l'action) : ${poseKeys}. Pour les combats à 2, utilise une pose d'interaction : ${interactKeys}

Retourne UNIQUEMENT un JSON array valide. Exemple :
[
  {"panel_index":0,"scene":"...","characters":"...","dialogue":"","narration":"","framing":"wide","camera_angle":"high-angle","emotion":"mélancolie","action":"...","pose_description":"neutral-stand"},
  ...
]`;

    const userPrompt = `SCÈNE À DÉCOUPER : ${scene}

${charSection}

NOMBRE DE CASES : ${panelCount}

Génère un découpage narratif professionnel avec progression dramatique et des poses d'action variées.
Chaque case doit avoir un pose_description valide. Pour les affrontements, utilise les poses interact-*.
Angles de caméra dynamiques recommandés : low-angle, worm pour l'action; high-angle, bird pour la vulnérabilité.`;

    const groqBody = {
      model: "mixtral-8x7b-32768",
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      temperature: 0.8,
      max_tokens: 4096,
    };
    const res = await withRetry(async () => {
      const r = await fetch("https://api.groq.com/openai/v1/chat/completions", {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: `Bearer ${groqKey}` },
        body: JSON.stringify(groqBody),
      });
      if (!r.ok) throw new Error(`GROQ HTTP ${r.status}`);
      return r;
    }, "groq", 2);

    if (!res) {
      log.error("GROQ échoué après retry, fallback scripts");
      return generateFallbackScripts(scene, panelCount);
    }
  } catch {
    // fallback silencieux
  }

  return generateFallbackScripts(scene, panelCount);
}

export function generateFallbackScripts(scene: string, panelCount: number): PanelScript[] {
  const result: PanelScript[] = [];
  for (let i = 0; i < panelCount; i++) {
    result.push({
      panel_index: i,
      scene: i === 0 ? `Plan large : ${scene}` :
             i === panelCount - 1 ? `Climax : ${scene}` :
             `Plan séquence ${i + 1} : ${scene}`,
      characters: "",
      dialogue: "",
      narration: "",
      framing: i === 0 ? "wide" : i === panelCount - 1 ? "close-up" : "medium",
      camera_angle: "eye-level",
      emotion: "neutre",
      action: "",
      pose_description: "neutral-stand",
    });
  }
  return result;
}

export function buildPanelPrompt(script: PanelScript, style: any, characters: Character[]): string {
  let prompt = style.prompt_template.replace("{prompt}", script.scene);

  // Character consistency: inject detailed appearance + name identity
  if (script.characters) {
    prompt += `, featuring ${script.characters}, consistent character design`;
  } else if (characters.length > 0) {
    const names = characters.map((c) => `${c.name}: ${c.appearance}, consistent ${c.name} design`).join(", ");
    prompt += `, featuring ${names}`;
  }

  // Add panel-specific character detail if a single character is named in scene
  if (script.characters && characters.length > 0) {
    for (const ch of characters) {
      if (script.characters.toLowerCase().includes(ch.name.toLowerCase())) {
        prompt += `, ${ch.name} portrayed with consistent facial features: ${ch.appearance}`;
        break;
      }
    }
  }

  if (script.emotion && script.emotion !== "neutre") {
    prompt += `, ${script.emotion} atmosphere`;
  }

  if (script.action) {
    prompt += `, dynamic action: ${script.action}`;
  }

  const framingMap: Record<string, string> = {
    "wide": "wide shot, establishing composition, cinematic framing",
    "medium": "medium shot, balanced composition, clear subject",
    "close-up": "close-up shot, intense expression, detailed face",
    "extreme-close-up": "extreme close-up, dramatic detail, abstract composition",
  };

  prompt += `, ${framingMap[script.framing] || "medium shot"}`;

  const angleMap: Record<string, string> = {
    "eye-level": "eye-level perspective",
    "high-angle": "high-angle shot, character looks small",
    "low-angle": "low-angle shot, dramatic upward perspective",
    "bird": "bird's eye view, overhead composition",
    "worm": "worm's eye view, ground level looking up",
  };

  prompt += `, ${angleMap[script.camera_angle] || "eye-level perspective"}`;

  if (script.narration) {
    prompt += `, text overlay area reserved for narration`;
  }

  if (script.dialogue) {
    prompt += `, dialogue scene, characters speaking`;
  }

  prompt += ", manga panel composition, black and white lineart with screentone, japanese comic style, dynamic inking";

  return prompt;
}

export async function generateCharacterRefs(ch: Character, style: any): Promise<Record<string, string> | null> {
  if (!REPLICATE_API_KEY) return null;

  const qualityTags = "masterpiece, best quality, absurdres, highres";
  const basePrompt = `${qualityTags}, ${
    style.prompt_template.replace("{prompt}", `portrait of ${ch.name}, ${ch.appearance}`)
  }, manga character portrait, clean lineart, neutral expression, bust up, highly detailed face, distinct facial features, recognizable character design, consistent features`;

  const views: [string, string][] = [
    ["front", "front facing, symmetrical, looking at viewer"],
    ["three_quarter", "three-quarter view, slightly turned, looking forward"],
    ["profile", "profile view, side facing, looking to the side"],
  ];

  const result: Record<string, string> = {};
  for (const [viewName, viewDesc] of views) {
    const prompt = `${basePrompt}, ${viewDesc}`;
    const input: Record<string, any> = {
      prompt,
      negative_prompt: style.negative_prompt || "lowres, bad anatomy, bad hands, text, error, missing finger, extra digits, fewer digits, cropped, worst quality, low quality, low score, bad score, average score, signature, watermark, username, blurry, ugly, deformed, photorealistic, 3d",
      width: 768,
      height: 768,
      num_inference_steps: 25,
      guidance_scale: 6,
      scheduler: "Euler a",
      num_outputs: 1,
    };

    if (style.lora_url) {
      input.lora_urls = [style.lora_url];
      input.lora_scale = Number(style.lora_scale ?? 0.8);
    }

    const url = await withRetry(() => replicatePredict(SDXL, input, `${ch.name}-${viewName}`), `${ch.name}-${viewName}`, 2);
    if (url) result[viewName] = url;
  }

  return Object.keys(result).length > 0 ? result : null;
}
