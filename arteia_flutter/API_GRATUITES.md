# 🆓 Solutions 100% Gratuites pour l'IA

## 📋 Vue d'ensemble

Plusieurs services offrent des APIs LLM **gratuites** sans avoir à déployer de serveur Ollama.

---

## ⭐ Option 1 : Groq (RECOMMANDÉ)

### Avantages
- ✅ **100% gratuit** (pas de limite de temps)
- ✅ **Ultra rapide** (LPU - Language Processing Unit)
- ✅ Pas de serveur à gérer
- ✅ Modèles : Llama 3.1, Mixtral, Gemma, etc.

### Inscription

1. Aller sur https://console.groq.com
2. Créer un compte (gratuit)
3. Récupérer votre API key

### Configuration

Éditer `arteia_flutter/lib/services/ai_assistant_service.dart` :

```dart
// Ajouter Groq en priorité
static const String _groqApiKey = 'VOTRE_API_KEY_GROQ';
static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
```

### Limites
- 30 requêtes/minute
- 6000 requêtes/jour
- Suffisant pour un usage personnel et petit groupe

---

## ⭐ Option 2 : Hugging Face Inference API

### Avantages
- ✅ **100% gratuit** (avec limitations)
- ✅ Beaucoup de modèles disponibles
- ✅ Pas de serveur à gérer

### Inscription

1. Aller sur https://huggingface.co
2. Créer un compte
3. Récupérer votre API token

### Configuration

```dart
static const String _hfApiKey = 'VOTRE_TOKEN_HUGGINGFACE';
static const String _hfUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3';
```

### Limites
- 1000 requêtes/jour (gratuit)
- Temps de chargement du modèle (première requête lente)

---

## ⭐ Option 3 : Google Colab + Ngrok

### Avantages
- ✅ **100% gratuit**
- ✅ GPU gratuit (Colab)
- ✅ Ollama fonctionne sur Colab

### Inconvénients
- ⚠️ Session limitée à 12h
- ⚠️ Doit être relancé manuellement

### Procédure

1. Aller sur https://colab.research.google.com
2. Créer un nouveau notebook
3. Installer Ollama :

```bash
!curl -fsSL https://ollama.com/install.sh | sh
!ollama pull qwen2.5-coder:7b
!ollama serve &
```

4. Exposer avec Ngrok :

```bash
!pip install pyngrok
from pyngrok import ngrok
ngrok.connect(11434)
```

5. Récupérer l'URL Ngrok et la mettre dans le code Flutter

---

## ⭐ Option 4 : Together AI

### Avantages
- ✅ **25$/mois de crédit gratuit**
- ✅ Modèles : Llama, Mixtral, Qwen, etc.
- ✅ Rapide

### Inscription

1. Aller sur https://api.together.xyz
2. Créer un compte
3. Récupérer votre API key

### Configuration

```dart
static const String _togetherApiKey = 'VOTRE_API_KEY';
static const String _togetherUrl = 'https://api.together.xyz/v1/chat/completions';
```

---

## ⭐ Option 5 : Replicate

### Avantages
- ✅ **Crédit gratuit** au démarrage
- ✅ Beaucoup de modèles
- ✅ Pay-as-you-go après

### Inscription

1. Aller sur https://replicate.com
2. Créer un compte
3. Récupérer votre API token

---

## 🎯 Solution Hybride (RECOMMANDÉE)

Combiner plusieurs services gratuits :

```
Question utilisateur
    ↓
1. Groq (gratuit, rapide) ← PRIORITAIRE
    ↓
2. Hugging Face (gratuit, lent)
    ↓
3. Supabase Edge Function (fallback)
    ↓
4. Réponses locales (fallback final)
```

### Avantages
- 🆓 100% gratuit
- 🚀 Rapide (Groq)
- 💪 Fiable (multi-services)
- 🔒 Pas de serveur à gérer

---

## 🔧 Configuration Rapide

### Étape 1 : Choisir un service

**Pour débuter :** Groq (le plus rapide et simple)

### Étape 2 : Récupérer l'API key

1. Aller sur https://console.groq.com
2. Créer un compte
3. Copier l'API key

### Étape 3 : Modifier le code

Éditer `arteia_flutter/lib/services/ai_assistant_service.dart` :

```dart
// Ajouter après les imports
static const String _groqApiKey = 'gsk_...'; // Votre clé
static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

// Modifier sendMessage() pour ajouter Groq en priorité
Future<String> sendMessage(...) async {
  // 1. Essayer Groq
  try {
    final groqResponse = await _tryGroq(message, history);
    if (groqResponse != null) return groqResponse;
  } catch (_) {}
  
  // 2. Fallback : Ollama (si serveur disponible)
  // ...
  
  // 3. Fallback : Supabase
  // ...
  
  // 4. Fallback : Local
  // ...
}
```

### Étape 4 : Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

---

## 📊 Comparaison des Services Gratuits

| Service | Limite | Vitesse | Modèles | Fiabilité |
|---------|--------|---------|---------|-----------|
| **Groq** | 30/min, 6000/jour | ⚡⚡⚡ Ultra rapide | Llama 3.1, Mixtral | ⭐⭐⭐⭐⭐ |
| **Hugging Face** | 1000/jour | ⚡ Lent | Tous | ⭐⭐⭐ |
| **Together AI** | 25$/mois crédit | ⚡⚡ Rapide | Tous | ⭐⭐⭐⭐ |
| **Google Colab** | 12h/session | ⚡⚡ Rapide | Tous (Ollama) | ⭐⭐ |
| **Railway** | 500h/mois | ⚡⚡ Rapide | Tous (Ollama) | ⭐⭐⭐⭐ |

---

## 🆓 Meilleure Combinaison 100% Gratuite

### Pour un usage personnel :

1. **Groq** (6000 requêtes/jour)
2. **Hugging Face** (1000 requêtes/jour)
3. **Réponses locales** (illimité)

**Total : 7000+ requêtes/jour gratuites !**

### Pour un petit groupe (5-10 personnes) :

1. **Groq** (6000/jour)
2. **Together AI** (25$ crédit = ~5000 requêtes)
3. **Réponses locales** (fallback)

**Total : 11000+ requêtes/jour gratuites !**

---

## ✅ Checklist

- [ ] Choisir un service (Groq recommandé)
- [ ] Créer un compte
- [ ] Récupérer l'API key
- [ ] Modifier le code Flutter
- [ ] Rebuild l'APK
- [ ] Tester

---

## 🆘 Dépannage

### Problème : "API key invalide"

**Solution :** Vérifier la clé dans le code

### Problème : "Rate limit exceeded"

**Solution :** Passer au service suivant (Hugging Face)

### Problème : "Timeout"

**Solution :** Augmenter le timeout dans le code :
```dart
.timeout(const Duration(seconds: 30)); // Augmenter à 60
```

---

## 📞 Liens Utiles

- **Groq :** https://console.groq.com
- **Hugging Face :** https://huggingface.co
- **Together AI :** https://api.together.xyz
- **Replicate :** https://replicate.com
- **Google Colab :** https://colab.research.google.com

---

**100% gratuit, pas de serveur à gérer ! 🎉**