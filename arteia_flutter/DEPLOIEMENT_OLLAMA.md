# 🚀 Déploiement Ollama - Guide Rapide

## 📋 Résumé

L'application Arteïa utilise **Ollama** avec le modèle **Qwen 2.5 Coder 7B** pour l'IA. Ce guide explique comment déployer le serveur Ollama et configurer l'application.

---

## 🎯 Architecture

```
┌─────────────┐
│   Android   │
│   (APK)     │
└──────┬──────┘
       │
       │ HTTP
       │
┌──────▼──────────────────────────┐
│   Serveur Ollama (Cloud)        │
│   - Qwen 2.5 Coder 7B (4.7GB)  │
│   - Port 11434                  │
└─────────────────────────────────┘
```

---

## ⚡ Option 1 : Railway.app (RECOMMANDÉ - Gratuit)

### Étape 1 : Créer un compte Railway

1. Aller sur https://railway.app
2. Se connecter avec GitHub
3. Créer un nouveau projet

### Étape 2 : Déployer Ollama

1. Dans le projet, cliquer sur **"New"** → **"Docker"**
2. Connecter votre repository GitHub `Design-for-Artistic-Community-App`
3. Sélectionner le dossier `arteia_flutter`
4. Utiliser le `Dockerfile` déjà créé

### Étape 3 : Configurer le volume

1. Cliquer sur **"New"** → **"Volume"**
2. Nom : `ollama_data`
3. Taille : **10GB** (minimum 4GB)
4. Monter le volume dans `/root/.ollama`

### Étape 4 : Variables d'environnement

Dans les paramètres du service, ajouter :

```
OLLAMA_HOST=0.0.0.0
OLLAMA_PORT=11434
```

### Étape 5 : Récupérer l'URL

1. Attendre le déploiement (2-3 minutes)
2. Cliquer sur **"Settings"** → **"Domains"**
3. Copier l'URL (ex: `https://arteia-ollama.up.railway.app`)

### Étape 6 : Mettre à jour le code

Éditer `arteia_flutter/lib/services/ai_assistant_service.dart` :

```dart
// Ligne 8-10
static const String _ollamaUrl = 'https://arteia-ollama.up.railway.app/api/chat';
static const String _ollamaUrlBackup = 'https://arteia-ollama.up.railway.app/api/chat';
```

### Étape 7 : Rebuild l'APK

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

### Étape 4 : Créer le volume

```bash
fly volumes create ollama_data --size 10
```

### Étape 5 : Déployer

```bash
fly deploy
```

### Étape 6 : Récupérer l'URL

```bash
fly status
# L'URL sera affichée (ex: https://arteia-ollama.fly.dev)
```

### Étape 7 : Mettre à jour le code

Même procédure que Railway (étape 6)

---

## 🎯 Option 3 : Render.com (750h/mois gratuites)

### Étape 1 : Créer un compte

1. Aller sur https://render.com
2. Se connecter avec GitHub

### Étape 2 : Créer un service Docker

1. **"New"** → **"Docker"**
2. Connecter le repository
3. Sélectionner `arteia_flutter/Dockerfile`
4. Plan : **Free**

### Étape 3 : Ajouter un disque

1. **"Disks"** → **"Add Disk"**
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

## 🔧 Configuration de l'application

### Fichier à modifier

`arteia_flutter/lib/services/ai_assistant_service.dart`

```dart
// Ligne 8-10 : Remplacer par votre URL
static const String _ollamaUrl = 'https://VOTRE-URL-SERVEUR.com/api/chat';
static const String _ollamaUrlBackup = 'https://VOTRE-URL-SERVEUR.com/api/chat';
```

### Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

L'APK sera généré dans :
```
arteia_flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Tests

### Test 1 : Vérifier que le serveur répond

```bash
curl https://VOTRE-URL-SERVEUR.com/api/tags
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
curl https://VOTRE-URL-SERVEUR.com/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [
    {"role": "user", "content": "Bonjour, qui es-tu ?"}
  ],
  "stream": false
}'
```

### Test 3 : Depuis l'application

1. Installer l'APK sur un téléphone
2. Ouvrir l'application
3. Aller dans l'IA
4. Envoyer : "Bonjour !"
5. Vérifier la réponse

---

## 📊 Monitoring

### Voir les logs Railway

```bash
railway logs
```

### Voir les logs Fly.io

```bash
fly logs
```

### Voir les logs Render

Dans le dashboard Render → Logs

---

## 🔄 Mise à jour du modèle

### Railway

```bash
railway ssh
ollama pull qwen2.5-coder:7b
exit
```

### Fly.io

```bash
fly ssh console
ollama pull qwen2.5-coder:7b
exit
```

### Render

Redéployer le service (le modèle sera mis à jour automatiquement)

---

## 🆘 Dépannage

### Problème : "Connection refused"

**Cause :** Le serveur n'est pas démarré ou l'URL est incorrecte

**Solution :**
1. Vérifier que le service est démarré
2. Vérifier l'URL dans le code Flutter
3. Tester avec curl

### Problème : "Model not found"

**Cause :** Le modèle n'est pas téléchargé

**Solution :**
```bash
# Se connecter au serveur
railway ssh  # ou fly ssh console

# Pull le modèle
ollama pull qwen2.5-coder:7b
```

### Problème : "Out of memory"

**Cause :** Le serveur n'a pas assez de RAM

**Solution :**
1. Upgrader le plan (Railway : $5/mois, Fly.io : $5/mois)
2. Ou utiliser un modèle plus petit : `qwen2.5-coder:3b`

### Problème : "Timeout"

**Cause :** Le modèle est trop lent

**Solution :**
Réduire `num_ctx` dans le code (ligne 200) :
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

**Recommandation :** Railway.app à $5/mois pour la stabilité

---

## ✅ Checklist finale

- [ ] Compte Railway/Fly.io/Render créé
- [ ] Service Ollama déployé
- [ ] Volume de 10GB créé
- [ ] Modèle `qwen2.5-coder:7b` téléchargé
- [ ] URL du serveur récupérée
- [ ] URL mise à jour dans le code Flutter
- [ ] APK rebuild
- [ ] Test de connectivité réussi
- [ ] Test depuis l'application réussi

---

## 📞 Support

- **Ollama :** https://github.com/ollama/ollama
- **Railway :** https://docs.railway.app
- **Fly.io :** https://fly.io/docs
- **Render :** https://render.com/docs

---

**Bon déploiement ! 🚀**