# 🚀 Déploiement Ollama + Qwen 2.5 Coder 7B

## 📋 Vue d'ensemble

Ce guide vous explique comment déployer **Ollama avec Qwen 2.5 Coder 7B** pour que tous les utilisateurs de l'application Arteïa puissent l'utiliser.

**Architecture :**
```
Utilisateurs (APK Android)
    ↓
Serveur Ollama (Cloud)
    ↓
Qwen 2.5 Coder 7B (4.7GB)
```

---

## ⚡ Option 1 : Railway.app (RECOMMANDÉ - $5/mois)

### Pourquoi Railway ?
- ✅ Simple à déployer
- ✅ Fiable
- ✅ 500h/mois gratuites (puis $5/mois)
- ✅ Supporte Docker
- ✅ Volume persistant pour le modèle

### Étape 1 : Créer un compte

1. Aller sur https://railway.app
2. Cliquer sur "Sign Up"
3. Se connecter avec GitHub

### Étape 2 : Créer un nouveau projet

1. Cliquer sur **"New Project"**
2. Sélectionner **"Deploy from GitHub repo"**
3. Choisir votre repository `Design-for-Artistic-Community-App`
4. Sélectionner le dossier `arteia_flutter`

### Étape 3 : Configurer le service

1. Cliquer sur **"New"** → **"Docker"**
2. Railway va détecter le `Dockerfile` automatiquement
3. Attendre le build (2-3 minutes)

### Étape 4 : Ajouter un volume (IMPORTANT)

1. Cliquer sur **"New"** → **"Volume"**
2. Nom : `ollama_data`
3. Taille : **10GB** (le modèle fait 4.7GB)
4. Cliquer sur le service Ollama
5. Dans **"Volumes"**, monter le volume sur `/root/.ollama`

### Étape 5 : Variables d'environnement

Dans **"Variables"**, ajouter :
```
OLLAMA_HOST=0.0.0.0
OLLAMA_PORT=11434
```

### Étape 6 : Récupérer l'URL

1. Aller dans **"Settings"** → **"Domains"**
2. Cliquer sur **"Generate Domain"**
3. Copier l'URL (ex: `https://arteia-ollama.up.railway.app`)

### Étape 7 : Mettre à jour le code

Éditer `arteia_flutter/lib/services/ai_assistant_service.dart` :

```dart
// Ligne 8-10
static const String _ollamaUrl = 'https://arteia-ollama.up.railway.app/api/chat';
static const String _ollamaUrlBackup = 'https://arteia-ollama.up.railway.app/api/chat';
```

### Étape 8 : Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

---

## 🎯 Option 2 : Fly.io (500h/mois gratuites)

### Étape 1 : Installer Fly CLI

```bash
# Windows (PowerShell)
iwr https://fly.io/install.ps1 -useb | iex

# Mac/Linux
curl -L https://fly.io/install.sh | sh
```

### Étape 2 : Se connecter

```bash
fly auth login
```

### Étape 3 : Lancer l'app

```bash
cd arteia_flutter
fly launch --image ollama/ollama:latest
```

Répondre aux questions :
- App name : `arteia-ollama`
- Organization : `personal`
- Region : `iad` (Washington DC, proche)
- PostgreSQL : No
- Redis : No

### Étape 4 : Créer le volume

```bash
fly volumes create ollama_data --size 10 --region iad
```

### Étape 5 : Configurer le service

```bash
fly secrets set OLLAMA_HOST=0.0.0.0 OLLAMA_PORT=11434
```

### Étape 6 : Déployer

```bash
fly deploy
```

### Étape 7 : Récupérer l'URL

```bash
fly status
# L'URL sera : https://arteia-ollama.fly.dev
```

### Étape 8 : Mettre à jour le code

Même procédure que Railway (étape 7)

---

## 🎯 Option 3 : Google Colab (100% gratuit, 12h)

### Avantages
- ✅ 100% gratuit
- ✅ GPU gratuit
- ✅ Pas de limite de requêtes

### Inconvénients
- ⚠️ Session limitée à 12h
- ⚠️ Doit être relancé manuellement

### Étape 1 : Ouvrir Colab

1. Aller sur https://colab.research.google.com
2. Cliquer sur **"New Notebook"**

### Étape 2 : Installer Ollama

```bash
# Cell 1 : Installer Ollama
!curl -fsSL https://ollama.com/install.sh | sh

# Cell 2 : Démarrer Ollama
!ollama serve &

# Cell 3 : Attendre 5 secondes
import time
time.sleep(5)

# Cell 4 : Pull le modèle
!ollama pull qwen2.5-coder:7b

# Cell 5 : Vérifier
!ollama list
```

### Étape 3 : Exposer avec Ngrok

```bash
# Cell 6 : Installer Ngrok
!pip install pyngrok

# Cell 7 : Exposer le port
from pyngrok import ngrok
public_url = ngrok.connect(11434)
print(f"URL : {public_url}")
```

### Étape 4 : Récupérer l'URL

Copier l'URL Ngrok (ex: `https://abc123.ngrok.io`)

### Étape 5 : Mettre à jour le code

```dart
static const String _ollamaUrl = 'https://abc123.ngrok.io/api/chat';
static const String _ollamaUrlBackup = 'https://abc123.ngrok.io/api/chat';
```

### Étape 6 : Rebuild l'APK

```bash
flutter build apk --release
```

**⚠️ Important :** L'URL Ngrok change à chaque redémarrage de Colab. Vous devez mettre à jour le code et rebuild l'APK à chaque fois.

---

## 🎯 Option 4 : Render.com (750h/mois gratuites)

### Étape 1 : Créer un compte

1. Aller sur https://render.com
2. Se connecter avec GitHub

### Étape 2 : Créer un service Docker

1. Cliquer sur **"New"** → **"Docker"**
2. Connecter le repository GitHub
3. Sélectionner `arteia_flutter/Dockerfile`
4. Plan : **Free**

### Étape 3 : Ajouter un disque

1. Cliquer sur **"Disks"** → **"Add Disk"**
2. Nom : `ollama_data`
3. Taille : **10GB**
4. Mount path : `/root/.ollama`

### Étape 4 : Variables d'environnement

```
OLLAMA_HOST=0.0.0.0
OLLAMA_PORT=11434
```

### Étape 5 : Récupérer l'URL

L'URL sera fournie après le déploiement (ex: `https://arteia-ollama.onrender.com`)

---

## ✅ Vérification

### Test 1 : Vérifier que le serveur répond

```bash
curl https://VOTRE-URL/api/tags
```

Réponse attendue :
```json
{
  "models": [
    {
      "name": "qwen2.5-coder:7b",
      "size": 4700000000
    }
  ]
}
```

### Test 2 : Tester une génération

```bash
curl https://VOTRE-URL/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [
    {"role": "user", "content": "Bonjour, qui es-tu ?"}
  ],
  "stream": false
}'
```

### Test 3 : Depuis l'application

1. Installer l'APK
2. Ouvrir l'application
3. Aller dans l'IA
4. Envoyer : "Bonjour !"
5. Vérifier la réponse

---

## 📊 Comparaison des Options

| Option | Coût | Limite | Difficulté | Fiabilité |
|--------|------|--------|-----------|-----------|
| **Railway** | $5/mois | Illimité | ⭐⭐ Facile | ⭐⭐⭐⭐⭐ |
| **Fly.io** | $5/mois | 500h/mois gratuites | ⭐⭐⭐ Moyen | ⭐⭐⭐⭐ |
| **Colab** | Gratuit | 12h/session | ⭐⭐⭐⭐ Difficile | ⭐⭐ |
| **Render** | $7/mois | 750h/mois gratuites | ⭐⭐ Facile | ⭐⭐⭐ |

**Recommandation : Railway.app à $5/mois**

---

## 🆘 Dépannage

### Problème : "Connection refused"

**Solution :**
1. Vérifier que le service est démarré
2. Vérifier l'URL dans le code Flutter
3. Tester avec curl

### Problème : "Model not found"

**Solution :**
```bash
# Se connecter au serveur
railway ssh  # ou fly ssh console

# Pull le modèle
ollama pull qwen2.5-coder:7b

# Vérifier
ollama list
```

### Problème : "Out of memory"

**Solution :**
1. Vérifier que le volume est bien monté
2. Upgrader le plan ($5/mois minimum)
3. Ou utiliser un modèle plus petit : `qwen2.5-coder:3b`

### Problème : "Timeout"

**Solution :**
Réduire `num_ctx` dans le code :
```dart
'options': {
  'temperature': 0.7,
  'num_ctx': 1024, // Réduit de 2048 à 1024
  'num_predict': 500,
},
```

---

## 💰 Coûts

### Railway.app
- **Gratuit :** 500h/mois, 512MB RAM
- **Payant :** $5/mois, 1GB RAM (suffisant pour Qwen 2.5 Coder 7B)

### Fly.io
- **Gratuit :** 500h/mois, 256MB RAM (pas suffisant)
- **Payant :** $5/mois, 1GB RAM

### Render.com
- **Gratuit :** 750h/mois, 512MB RAM (limité)
- **Payant :** $7/mois, 1GB RAM

---

## ✅ Checklist

- [ ] Compte Railway/Fly.io/Render créé
- [ ] Service Ollama déployé
- [ ] Volume de 10GB créé et monté
- [ ] Modèle `qwen2.5-coder:7b` téléchargé
- [ ] URL du serveur récupérée
- [ ] URL mise à jour dans le code Flutter
- [ ] APK rebuild
- [ ] Test de connectivité réussi
- [ ] Test depuis l'application réussi

---

## 🎯 Résumé

**Pour utiliser Qwen 2.5 Coder 7B :**

1. **Déployer Ollama** sur Railway ($5/mois) ou Fly.io ($5/mois)
2. **Récupérer l'URL** du serveur
3. **Mettre à jour le code** (ligne 8-10 de `ai_assistant_service.dart`)
4. **Rebuild l'APK**
5. **Tester**

**C'est tout ! Votre application utilise maintenant Qwen 2.5 Coder 7B !** 🚀

---

## 📞 Support

- **Ollama :** https://github.com/ollama/ollama
- **Railway :** https://docs.railway.app
- **Fly.io :** https://fly.io/docs
- **Render :** https://render.com/docs

---

**Bon déploiement ! 🚀**