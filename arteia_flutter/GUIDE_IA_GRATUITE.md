# 🆓 Guide Rapide - IA Gratuite pour Arteïa

## ⚡ Configuration en 2 minutes

### Option 1 : Groq (RECOMMANDÉ - Ultra Rapide)

#### Étape 1 : Créer un compte (30 secondes)
1. Aller sur https://console.groq.com
2. Cliquer sur "Sign Up"
3. Se connecter avec Google/GitHub

#### Étape 2 : Récupérer la clé API (30 secondes)
1. Aller sur https://console.groq.com/keys
2. Cliquer sur "Create API Key"
3. Copier la clé (commence par `gsk_...`)

#### Étape 3 : Configurer l'application (1 minute)

Ouvrir le fichier `arteia_flutter/lib/services/ai_assistant_service.dart`

Trouver la ligne 8 :
```dart
static const String _groqApiKey = ''; // Ajoutez votre clé Groq ici
```

Remplacer par :
```dart
static const String _groqApiKey = 'gsk_VOTRE_CLE_ICI'; // Ajoutez votre clé Groq ici
```

#### Étape 4 : Rebuild l'APK (2 minutes)
```bash
cd arteia_flutter
flutter build apk --release
```

L'APK sera dans : `arteia_flutter/build/app/outputs/flutter-apk/app-release.apk`

---

### Option 2 : Hugging Face (Gratuit, Limité)

#### Étape 1 : Créer un compte
1. Aller sur https://huggingface.co
2. Cliquer sur "Sign Up"
3. Créer un compte

#### Étape 2 : Récupérer le token
1. Aller sur https://huggingface.co/settings/tokens
2. Cliquer sur "New Token"
3. Nom : `arteia-app`
4. Type : "Read"
5. Copier le token

#### Étape 3 : Configurer
```dart
static const String _hfApiKey = 'hf_VOTRE_TOKEN_ICI';
```

#### Étape 4 : Rebuild
```bash
flutter build apk --release
```

---

## 📊 Comparaison Express

| Service | Vitesse | Limite | Difficulté |
|---------|---------|--------|-----------|
| **Groq** | ⚡⚡⚡ Ultra rapide | 6000/jour | ⭐ Facile |
| **Hugging Face** | ⚡ Lent | 1000/jour | ⭐ Facile |
| **Ollama** | ⚡⚡ Rapide | Illimité | ⭐⭐⭐ Difficile |

---

## ✅ Vérification

### Test 1 : Vérifier que Groq fonctionne

```bash
curl https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer VOTRE_CLE" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.1-8b-instant",
    "messages": [{"role": "user", "content": "Bonjour !"}]
  }'
```

### Test 2 : Depuis l'application

1. Installer l'APK
2. Ouvrir l'application
3. Aller dans l'IA
4. Envoyer "Bonjour !"
5. Vérifier la réponse

---

## 🆓 Services Gratuits Disponibles

### 1. Groq (RECOMMANDÉ)
- **URL :** https://console.groq.com
- **Limite :** 30 requêtes/minute, 6000/jour
- **Modèle :** Llama 3.1 8B (ultra rapide)
- **Avantage :** Le plus rapide, 100% gratuit

### 2. Hugging Face
- **URL :** https://huggingface.co
- **Limite :** 1000 requêtes/jour
- **Modèle :** Mistral 7B
- **Avantage :** Beaucoup de modèles disponibles

### 3. Together AI
- **URL :** https://api.together.xyz
- **Limite :** 25$/mois de crédit gratuit
- **Modèle :** Llama, Mixtral, Qwen
- **Avantage :** Modèles variés

### 4. Google Colab + Ngrok
- **URL :** https://colab.research.google.com
- **Limite :** 12h par session
- **Modèle :** Tous (via Ollama)
- **Avantage :** GPU gratuit, illimité

---

## 🎯 Architecture Finale

```
Question utilisateur
    ↓
1. Groq (gratuit, rapide) ← PRIORITAIRE
    ↓
2. Hugging Face (gratuit, lent)
    ↓
3. Ollama (si serveur disponible)
    ↓
4. Supabase Edge Function (fallback)
    ↓
5. Réponses locales (fallback final)
```

---

## 💡 Astuces

### Pour un usage personnel :
- Utiliser **Groq** (6000 requêtes/jour suffisent)

### Pour un petit groupe (5-10 personnes) :
- **Groq** (6000/jour)
- **Hugging Face** (1000/jour)
- Total : 7000 requêtes/jour gratuites

### Pour un usage intensif :
- Déployer **Ollama** sur Railway ($5/mois)
- Ou utiliser **Together AI** (25$ crédit/mois)

---

## 🆘 Dépannage

### Problème : "Invalid API Key"
**Solution :** Vérifier la clé dans le code Flutter

### Problème : "Rate Limit Exceeded"
**Solution :** Attendre 1 minute ou utiliser Hugging Face

### Problème : "Timeout"
**Solution :** Augmenter le timeout dans le code :
```dart
.timeout(const Duration(seconds: 30)); // Augmenter à 60
```

---

## 📞 Support

- **Groq Docs :** https://console.groq.com/docs
- **Hugging Face Docs :** https://huggingface.co/docs/api-inference
- **Ollama Docs :** https://github.com/ollama/ollama

---

**C'est tout ! Votre IA est maintenant gratuite et fonctionnelle ! 🎉**