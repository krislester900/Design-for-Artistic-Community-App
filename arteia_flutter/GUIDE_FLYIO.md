# 🚀 Déploiement Ollama sur Fly.io (100% Gratuit)

## 📋 Vue d'ensemble

Ce guide vous explique comment déployer **Ollama avec Qwen 2.5 Coder 7B** sur Fly.io.

**Avantages :**
- ✅ **100% gratuit** (500h/mois)
- ✅ Pas de carte bancaire requise
- ✅ Open source
- ✅ Simple à déployer
- ✅ 24/7 (si vous gardez la VM allumée)

**Inconvénients :**
- ⚠️ 500h/mois seulement (~20 jours par mois)
- ⚠️ 1GB RAM (nécessite du swap pour Qwen 2.5 Coder 7B)

---

## ⚡ Étape 1 : Installer Fly CLI (2 minutes)

### Windows (PowerShell)

```powershell
# Installer Fly CLI
iwr https://fly.io/install.ps1 -useb | iex
```

### Mac / Linux

```bash
# Installer Fly CLI
curl -L https://fly.io/install.sh | sh
```

### Vérifier l'installation

```bash
fly --version
```

---

## 🔐 Étape 2 : Créer un compte Fly.io (1 minute)

```bash
# Se connecter
fly auth login
```

Cela va ouvrir un navigateur pour vous authentifier.

**Options d'authentification :**
- GitHub (recommandé)
- Google
- Email

**Pas de carte bancaire requise pour commencer !**

---

## 🚀 Étape 3 : Déployer Ollama (5 minutes)

### ⚠️ IMPORTANT : Pas de template Static !

**Fly.io va vous demander de choisir un template. VOUS N'EN AVEZ PAS BESOIN.**

Répondez simplement aux questions et utilisez l'image Ollama directement.

### Option A : Déploiement automatique (RECOMMANDÉ)

```bash
# Aller dans le dossier arteia_flutter
cd arteia_flutter

# Lancer le déploiement avec région explicite
fly launch --image ollama/ollama:latest --region iad
```

**Répondre aux questions :**

```
? App Name: arteia-ollama
? Organization: personal
? Region: iad (Washington DC - proche)
? PostgreSQL: No
? Redis: No
? Deploy now: Yes
```

**Si on vous demande "Choose a Static template" :**
- ❌ **NE CHOISISSEZ PAS** de template Static
- ✅ Utilisez simplement l'image Docker : `ollama/ollama:latest`
- ✅ La commande `fly launch --image ollama/ollama:latest` le fait automatiquement

### Option B : Déploiement manuel

Si le déploiement automatique ne fonctionne pas :

```bash
# Créer l'app
fly apps create arteia-ollama

# Créer un volume de 10GB
fly volumes create ollama_data --size 10 --region iad

# Déployer
fly deploy --image ollama/ollama:latest
```

---

## ⚙️ Étape 4 : Configurer le service (2 minutes)

### 4.1 Configurer les variables d'environnement

```bash
fly secrets set OLLAMA_HOST=0.0.0.0 OLLAMA_PORT=11434
```

### 4.2 Vérifier le volume

```bash
fly volumes list
```

Vous devriez voir :
```
NAME          SIZE  REGION  ATTACHED
ollama_data   10GB  iad     arteia-ollama
```

---

## 📦 Étape 5 : Télécharger le modèle (5-10 minutes)

### 5.1 Se connecter au serveur

```bash
fly ssh console
```

### 5.2 Installer Ollama et télécharger le modèle

```bash
# Installer Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull le modèle Qwen 2.5 Coder 7B
ollama pull qwen2.5-coder:7b

# Vérifier
ollama list
```

### 5.3 Quitter le SSH

```bash
exit
```

---

## 🌐 Étape 6 : Récupérer l'URL (1 minute)

```bash
fly status
```

Vous verrez :
```
App Name: arteia-ollama
URL: https://arteia-ollama.fly.dev
```

**Copiez cette URL !**

---

## ✅ Étape 7 : Tester le serveur (2 minutes)

### Test 1 : Vérifier que le serveur répond

```bash
curl https://arteia-ollama.fly.dev/api/tags
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
curl https://arteia-ollama.fly.dev/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [
    {"role": "user", "content": "Bonjour, qui es-tu ?"}
  ],
  "stream": false
}'
```

---

## 📱 Étape 8 : Configurer l'application (2 minutes)

### 8.1 Mettre à jour le code

Ouvrir : `arteia_flutter/lib/services/ai_assistant_service.dart`

**Ligne 8-10 :** Remplacer par :
```dart
static const String _ollamaUrl = 'https://arteia-ollama.fly.dev/api/chat';
static const String _ollamaUrlBackup = 'https://arteia-ollama.fly.dev/api/chat';
```

### 8.2 Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

---

## 🎮 Gestion de la VM

### Voir les logs

```bash
fly logs
```

### Redémarrer la VM

```bash
fly apps restart arteia-ollama
```

### Arrêter la VM (pour économiser des heures)

```bash
fly apps stop arteia-ollama
```

### Démarrer la VM

```bash
fly apps start arteia-ollama
```

### Voir l'utilisation des heures

```bash
fly apps list
```

---

## 📊 Gestion des 500h/mois

### Calcul

- **500h/mois** = ~20 jours par mois (24/24)
- Ou ~40 jours par mois (12h/jour)
- Ou utilisation illimitée si vous partagez avec d'autres

### Optimisation

**Arrêter la VM quand vous ne l'utilisez pas :**
```bash
fly apps stop arteia-ollama
```

**La démarrer quand vous en avez besoin :**
```bash
fly apps start arteia-ollama
```

**Vérifier le statut :**
```bash
fly status
```

---

## ⚠️ Limitations et Solutions

### 1. RAM limitée (1GB)

**Problème :** Qwen 2.5 Coder 7B nécessite 4.7GB

**Solution :** Ajouter du swap

```bash
fly ssh console

# Ajouter 4GB de swap
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Vérifier
free -h
```

### 2. Cold start

**Problème :** Si la VM est arrêtée, premier démarrage : 30-60s

**Solution :** Garder la VM allumée si vous l'utilisez souvent

### 3. Limite de requêtes

**Problème :** Pas de limite officielle, mais 1GB RAM = ~5-10 requêtes simultanées

**Solution :** Suffisant pour usage personnel ou petit groupe

---

## 🆓 Alternatives si vous dépassez 500h/mois

### Option 1 : Fly.io Payant ($5/mois)

```bash
fly auth login
fly apps create arteia-ollama
# Suivre les étapes ci-dessus
```

**Avantages :**
- 24/7 illimité
- 1GB RAM
- $5/mois

### Option 2 : Oracle Cloud (4GB RAM à vie)

Voir `SOLUTIONS_GRATUITES_ILLIMITEES.md`

**Avantages :**
- 4GB RAM
- 24/7
- 100% gratuit à vie

**Inconvénient :**
- Nécessite une carte bancaire

---

## 🆘 Dépannage

### Problème : "App not found"

**Solution :**
```bash
fly apps list
fly status arteia-ollama
```

### Problème : "Connection refused"

**Solution :**
```bash
# Vérifier que l'app tourne
fly status

# Vérifier les logs
fly logs

# Redémarrer si nécessaire
fly apps restart arteia-ollama
```

### Problème : "Out of memory"

**Solution :** Ajouter du swap (voir section 4.1)

### Problème : "Model not found"

**Solution :**
```bash
fly ssh console
ollama list
ollama pull qwen2.5-coder:7b
```

---

## ✅ Checklist

- [ ] Fly CLI installé
- [ ] Compte créé (fly auth login)
- [ ] App déployée (fly launch)
- [ ] Volume créé (10GB)
- [ ] Modèle téléchargé (ollama pull qwen2.5-coder:7b)
- [ ] Test curl réussi
- [ ] URL mise à jour dans le code Flutter
- [ ] APK rebuild
- [ ] Test depuis l'application réussi

---

## 📞 Support

- **Fly.io Docs :** https://fly.io/docs
- **Ollama Docs :** https://github.com/ollama/ollama
- **Arteïa Guide :** Consultez `SOLUTIONS_GRATUITES_ILLIMITEES.md`

---

## 🎯 Résumé

**Fly.io c'est :**
- ✅ 500h/mois gratuites
- ✅ Pas de carte bancaire
- ✅ Simple à déployer
- ✅ 24/7 (si vous gardez la VM allumée)
- ✅ Parfait pour tester et utiliser Qwen 2.5 Coder 7B

**Commandes rapides :**
```bash
# Déployer
fly launch --image ollama/ollama:latest

# Voir le statut
fly status

# Voir les logs
fly logs

# Arrêter
fly apps stop arteia-ollama

# Démarrer
fly apps start arteia-ollama
```

---

**Votre serveur Ollama avec Qwen 2.5 Coder 7B est maintenant en ligne !** 🎉

**URL :** `https://arteia-ollama.fly.dev`

**Prochaine étape :** Mettre à jour le code Flutter et rebuild l'APK !