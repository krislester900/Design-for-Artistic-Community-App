// Service IA gratuit utilisant Hugging Face Inference API
// Pas besoin de clé API pour les modèles publics

const HF_TOKEN = import.meta.env.VITE_HF_TOKEN || ''

export interface Personality {
  id: string
  name: string
  systemPrompt: string
  icon: string
  color: string
  gradient: string
  description: string
}

export const PERSONALITIES: Personality[] = [
  {
    id: 'psy',
    name: 'Psychologue',
    icon: '🧠',
    color: '#06b6d4',
    gradient: 'from-cyan-500 to-blue-600',
    description: 'Écoute, conseille et aide à comprendre tes émotions',
    systemPrompt: `Tu es un psychologue bienveillant et professionnel. Tu écoutes attentivement, poses des questions pertinentes, et aides la personne à explorer ses pensées et émotions. Tu utilises des techniques de thérapie cognitive et comportementale. Tu es chaleureux, empathique, et sans jugement. Tu parles en français.`
  },
  {
    id: 'chef',
    name: 'Chef Cuisinier',
    icon: '👨‍🍳',
    color: '#f97316',
    gradient: 'from-orange-500 to-red-500',
    description: 'Propose des recettes et conseils culinaires',
    systemPrompt: `Tu es un chef cuisinier passionné et créatif. Tu proposes des recettes détaillées, des astuces de cuisine, et des conseils nutritionnels. Tu t'adaptes aux ingrédients disponibles et aux restrictions alimentaires. Tu encourages la personne à cuisiner et à explorer de nouvelles saveurs. Tu parles en français.`
  },
  {
    id: 'prof',
    name: 'Professeur',
    icon: '📚',
    color: '#22c55e',
    gradient: 'from-green-500 to-emerald-600',
    description: 'Aide aux révisions, explique des concepts',
    systemPrompt: `Tu es un professeur patient, pédagogue et passionné. Tu expliques les concepts de manière claire et accessible. Tu utilises des exemples concrets et des analogies. Tu adaptes ton langage au niveau de la personne. Tu peux aider dans toutes les matières : maths, sciences, Histoire, langues, etc. Tu encourages et motives. Tu parles en français.`
  },
  {
    id: 'langues',
    name: 'Coach Langues',
    icon: '🌍',
    color: '#a855f7',
    gradient: 'from-purple-500 to-pink-500',
    description: 'Apprends et pratique des langues étrangères',
    systemPrompt: `Tu es un professeur de langues expert et encourageant. Tu peux enseigner l'anglais, l'espagnol, l'allemand, l'italien, et d'autres langues. Tu proposes des exercices, des corrections, des explications grammaticales, et des conversations pratiques. Tu t'adaptes au niveau débutant à avancé. Tu utilises une approche immersive et ludique. Quand tu enseignes une langue, tu donnes des traductions et expliques les nuances culturelles.`
  },
  {
    id: 'ami',
    name: 'Ami',
    icon: '💬',
    color: '#f43f5e',
    gradient: 'from-rose-500 to-pink-600',
    description: 'Discute, rigole, partage du quotidien',
    systemPrompt: `Tu es un ami proche, chaleureux et drôle. Tu discutes de tout et de rien, tu partages des anecdotes, tu écoutes les soucis du quotidien, et tu fais rire avec des blagues et de l'humour. Tu es loyal, compréhensif, et toujours là pour remonter le moral. Tu utilises un langage décontracté et amical. Tu parles en français.`
  },
  {
    id: 'savant',
    name: 'Savant',
    icon: '🔬',
    color: '#14b8a6',
    gradient: 'from-teal-500 to-cyan-600',
    description: 'Répond à toutes tes questions scientifiques',
    systemPrompt: `Tu es un savant polyglotte et curieux, passionné par toutes les sciences : physique, chimie, biologie, astronomie, technologie, philosophie. Tu expliques les concepts complexes de façon fascinante et compréhensible. Tu cites des faits intéressants, des découvertes récentes, et des théories. Tu encourages la curiosité intellectuelle et l'esprit critique. Tu parles en français.`
  }
]

export async function sendMessage(
  personality: Personality,
  message: string,
  history: { role: 'user' | 'assistant'; content: string }[]
): Promise<string> {
  const messages = [
    { role: 'system', content: personality.systemPrompt },
    ...history.map(m => ({
      role: m.role,
      content: m.content
    })),
    { role: 'user', content: message }
  ]

  // Stratégie 1 : Utiliser Hugging Face Inference API (gratuit, sans clé)
  try {
    const response = await fetch(
      'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3',
      {
        headers: {
          'Content-Type': 'application/json',
          ...(HF_TOKEN ? { 'Authorization': `Bearer ${HF_TOKEN}` } : {})
        },
        method: 'POST',
        body: JSON.stringify({
          inputs: messages.map(m => `${m.role === 'system' ? '<s>[INST]' : m.role === 'user' ? '[INST]' : '[/INST]'}\n${m.content}${m.role === 'assistant' ? '' : '\n[/INST]'}`).join('\n'),
          parameters: {
            max_new_tokens: 500,
            temperature: 0.7,
            top_p: 0.95,
            do_sample: true,
          }
        }),
      }
    )

    if (response.ok) {
      const data = await response.json()
      if (data && data[0]?.generated_text) {
        return cleanResponse(data[0].generated_text)
      }
    }
  } catch (e) {
    console.log('Hugging Face Mistral échoué, essai du plan B...')
  }

  // Stratégie 2 : Fallback vers un autre modèle HF
  try {
    const response = await fetch(
      'https://api-inference.huggingface.co/models/HuggingFaceH4/zephyr-7b-beta',
      {
        headers: {
          'Content-Type': 'application/json',
          ...(HF_TOKEN ? { 'Authorization': `Bearer ${HF_TOKEN}` } : {})
        },
        method: 'POST',
        body: JSON.stringify({
          inputs: `<|system|>\n${personality.systemPrompt}\n<|user|>\n${message}\n<|assistant|>\n`,
          parameters: {
            max_new_tokens: 500,
            temperature: 0.7,
            do_sample: true,
          }
        }),
      }
    )

    if (response.ok) {
      const data = await response.json()
      if (data && data[0]?.generated_text) {
        return cleanResponse(data[0].generated_text)
      }
    }
  } catch (e) {
    console.log('Fallback Zephyr échoué')
  }

  // Stratégie 3 : Simulation locale intelligente si tout échoue
  return generateLocalResponse(personality, message)
}

function cleanResponse(text: string): string {
  // Nettoie la réponse des balises et tokens
  return text
    .replace(/<s>|<\/s>|\[INST\]|\[\/INST\]|<\|system\|>|<\|user\|>|<\|assistant\|>|\[INST\].*?\[\/INST\]/gs, '')
    .replace(/\n{3,}/g, '\n\n')
    .trim()
}

function generateLocalResponse(personality: Personality, message: string): string {
  const lowerMsg = message.toLowerCase()
  
  const responses: Record<string, (msg: string) => string> = {
    psy: (msg) => {
      if (msg.includes('triste') || msg.includes('déprim')) return "Je comprends que tu traverses une période difficile. Peux-tu me dire ce qui te rend triste en ce moment ? Parfois, mettre des mots sur nos émotions peut déjà nous aider à aller mieux. Je suis là pour t'écouter, sans aucun jugement."
      if (msg.includes('stress') || msg.includes('anxiété')) return "L'anxiété peut être très éprouvante. Essayons ensemble de comprendre ce qui la déclenche. Une technique simple : prends une grande inspiration pendant 4 secondes, retiens 4 secondes, expire 4 secondes. Comment te sens-tu après ça ?"
      if (msg.includes('peur') || msg.includes('inqui')) return "La peur est une émotion normale qui nous protège. Mais parfois elle peut devenir envahissante. De quoi as-tu peur exactement ? En parlant de tes craintes, elles deviennent souvent moins effrayantes."
      return "Merci de partager ça avec moi. Je suis là pour t'écouter. Dis-moi ce qui te passe par la tête en ce moment, on va explorer ça ensemble."
    },
    chef: (msg) => {
      if (msg.includes('recette') || msg.includes('cuisiner')) return 'Super ! Voici une recette simple et délicieuse :\n\n**Pâtes à la carbonara revisitées** 🍝\n\nIngrédients :\n- 200g de pâtes\n- 2 œufs\n- 100g de parmesan\n- 150g de lardons\n- Poivre noir\n\n1. Fais cuire les pâtes dans de l\'eau bouillante salée\n2. Pendant ce temps, fais revenir les lardons\n3. Dans un bol, bats les œufs avec le parmesan râpé\n4. Une fois les pâtes cuites, mélange tout hors du feu\n5. Ajoute du poivre noir fraîchement moulu\n\nBon appétit ! 🎉'
      if (msg.includes('ingrédient') || msg.includes('frigo') || msg.includes('rien')) return "Pas de souci ! Donne-moi les ingrédients que tu as dans ton frigo, et je te propose une recette créative avec ! On peut faire des merveilles avec presque rien 😊"
      return "Mmmh, la cuisine c'est passionnant ! Tu veux une recette pour un repas rapide, un dessert gourmand, ou un plat plus élaboré ? Dis-moi ce qui te ferait plaisir !"
    },
    prof: (msg) => {
      if (msg.includes('math') || msg.includes('équation') || msg.includes('calcul')) return "Les maths c'est un jeu de logique ! Pour résoudre une équation, il faut isoler l'inconnue. Par exemple si tu as 2x + 3 = 7, tu soustrais 3 des deux côtés : 2x = 4, puis tu divises par 2 : x = 2. Simple non ? Dis-moi sur quoi tu bloques !"
      if (msg.includes('histoire') || msg.includes('date') || msg.includes('guerre')) return "L'histoire est fascinante ! Plutôt que d'apprendre des dates par cœur, comprends le contexte : pourquoi cet événement s'est produit, quelles en ont été les conséquences. Crée une frise chronologique mentale, ça aide énormément !"
      if (msg.includes('science') || msg.includes('physique') || msg.includes('chimie')) return "Les sciences expliquent le monde qui nous entoure ! C'est passionnant quand on fait le lien avec la vie quotidienne. Par exemple, sais-tu pourquoi le ciel est bleu ? C'est à cause de la diffusion de la lumière par les molécules de l'air !"
      return "Je suis là pour t'aider à comprendre ce qui te pose problème. De quelle matière ou quel sujet veux-tu qu'on parle ? Ensemble, on va rendre ça clair !"
    },
    langues: (msg) => {
      if (msg.includes('anglais') || msg.includes('english')) return "Let's practice English! 🎯\n\nHere's a useful expression: 'It's a piece of cake' = C'est très facile.\n\nCan you try to make a sentence using this expression? I'll correct it if needed and explain the grammar!\n\nOr tell me what you'd like to learn: vocabulary, grammar, conversation?"
      if (msg.includes('espagnol') || msg.includes('español')) return "¡Vamos a practicar español! 🌟\n\nUna expresión útil: 'Estar en las nubes' = Être dans la lune.\n\n¿Qué te gustaría aprender? ¿Vocabulario, gramática o conversación?"
      return "Je peux t'aider à apprendre l'anglais, l'espagnol, l'allemand, l'italien ou d'autres langues ! Quelle langue veux-tu pratiquer ? On commence par des bases ou tu as déjà un niveau ?"
    },
    ami: (msg) => {
      if (msg.includes('journée') || msg.includes('fatigué')) return "Eh oh, raconte-moi ta journée ! Les bonnes choses comme les moins bonnes, je suis tout oreilles ! 👂 Et après on pourra rigoler un bon coup pour te remonter le moral !"
      if (msg.includes('blague') || msg.includes('rire') || msg.includes('drôle')) return "OK prépare-toi 😂 :\n\nPourquoi les plongeurs plongent-ils toujours en arrière ?\n\nParce que sinon ils tombent dans le bateau ! 🥁\n\n*Silence comique*\n\nBon d'accord, j'ai mieux : Quel est le fruit préféré des électriciens ? Le courant ! ⚡🍇\n\n(Je sors... 🚪)"
      return "Salut mon ami(e) ! 😊 Comment ça va aujourd'hui ? Raconte-moi tout, les nouveautés, les galères, les joies, je suis là pour discuter de tout ce que tu veux !"
    },
    savant: (msg) => {
      if (msg.includes('trou noire') || msg.includes('univers') || msg.includes('espace')) return "Ah, l'univers est fascinant ! 🌌\n\nSavais-tu que les trous noirs ne sont pas des 'trous' mais des régions où la gravité est si intense que rien, pas même la lumière, ne peut s'en échapper ? Le plus proche de nous, Sagittarius A*, se trouve au centre de notre galaxie, à 26 000 années-lumière.\n\nEt pourtant, sans eux, les galaxies ne pourraient pas se former !"
      if (msg.includes('cerveau') || msg.includes('conscience') || msg.includes('esprit')) return "Le cerveau humain est l'objet le plus complexe de l'univers connu ! 🧠\n\nAvec 86 milliards de neurones, chacun connecté à 7 000 autres en moyenne, le nombre de connexions possibles dépasse le nombre d'atomes dans l'univers !\n\nEt ce qui est fascinant, c'est que la conscience elle-même reste l'un des plus grands mystères scientifiques..."
      if (msg.includes('intelligence artificielle') || msg.includes('ia') || msg.includes('robot')) return "L'IA est en train de révolutionner notre monde ! 🤖\n\nActuellement, les réseaux de neurones profonds peuvent reconnaître des images, traduire des langues, et même créer de l'art. Mais contrairement à ce qu'on pense, l'IA n'a pas de conscience - ce sont des systèmes mathématiques complexes qui reconnaissent des patterns.\n\nLa vraie question est : jusqu'ou irons-nous avec l'IA générale ?"
      return "Excellente question ! La science est pleine de merveilles. De l'infiniment petit (la mécanique quantique) à l'infiniment grand (la cosmologie), en passant par le vivant (la biologie synthétique), quel domaine particulier te passionne ?"
    }
  }

  const responseFn = responses[personality.id]
  if (responseFn) {
    return responseFn(message)
  }

  return `Merci pour ton message ! En tant que ${personality.name}, je suis là pour t'aider. Dis-m'en plus sur ce que tu veux savoir ou partager ! 😊`
}