# 🚀 Déploiement Ollama sur Hugging Face Spaces

## 📋 Vue d'ensemble

Ce guide vous explique comment déployer **Ollama avec Qwen 2.5 Coder 7B** sur Hugging Face Spaces (100% gratuit).

**Temps nécessaire :** 10-15 minutes

---

## ⚡ Étape 1 : Créer le Space (2 minutes)

### 1.1 Aller sur Hugging Face Spaces

1. Ouvrir https://huggingface.co/spaces
2. Cliquer sur **"Create new Space"**

### 1.2 Configurer le Space

Remplir le formulaire :

- **Space name :** `arteia-ollama`
- **License :** `mit` (ou laissez vide)
- **Public/Private :** Choisissez `Public` ou `Private`
- **SDK :** Sélectionner **Docker** (IMPORTANT !)
- **Hardware :** `cpu basic` (gratuit)

### 1.3 Créer le Space

Cliquer sur **"Create Space"**

---

## 📁 Étape 2 : Préparer les fichiers (3 minutes)

### 2.1 Créer le Dockerfile

Dans votre Space, cliquer sur **"Files"** → **"Add file"** → **"Create new file"**

Nom du fichier : `Dockerfile`

Contenu :

```dockerfile
FROM ollama/ollama:latest

# Installer les dépendances
RUN apt-get update && apt-get install -y curl

# Exposer le port Ollama
EXPOSE 11434

# Copier le script d'initialisation
COPY init.sh /init.sh
RUN chmod +x /init.sh

# Point d'entrée
CMD ["/init.sh"]
```

### 2.2 Créer le script init.sh

Cliquer sur **"Add file"** → **"Create new file"**

Nom du fichier : `init.sh`

Contenu :

```bash
#!/bin/bash

echo "========================================="
echo "🚀 Démarrage d'Ollama - Arteïa AI"
echo "========================================="

# Démarrer Ollama en arrière-plan
ollama serve &
OLLAMA_PID=$!

# Attendre qu'Ollama soit prêt
echo "⏳ Attente du démarrage d'Ollama..."
sleep 10

# Vérifier qu'Ollama répond
for i in {1..30}; do
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "✅ Ollama est prêt !"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Timeout : Ollama n'a pas démarré"
        exit 1
    fi
    sleep 2
done

# Pull le modèle Qwen 2.5 Coder 7B
echo ""
echo "📦 Téléchargement de Qwen 2.5 Coder 7B..."
echo "   (4.7GB - cela peut prendre 5-10 minutes)"
echo ""

ollama pull qwen2.5-coder:7b

echo ""
echo "========================================="
echo "✅ Initialisation terminée !"
echo "========================================="
echo ""
echo "📊 Informations :"
echo "   - URL : https://arteia-ollama.hf.space"
echo "   - API : https://arteia-ollama.hf.space/api/chat"
echo "   - Modèle : qwen2.5-coder:7b"
echo ""

# Garder le conteneur en vie
wait $OLLAMA_PID
```

### 2.3 Commit les fichiers

1. En bas de la page, section **"Commit changes"**
2. Message : `Deploy Ollama with Qwen 2.5 Coder 7B`
3. Cliquer sur **"Commit"**

---

## ⏳ Étape 3 : Attendre le déploiement (5-10 minutes)

### 3.1 Suivre le build

1. Cliquer sur l'onglet **"Logs"**
2. Vous verrez le build en cours :
   ```
   Building Docker image...
   Pulling ollama/ollama:latest...
   Running init.sh...
   ```

### 3.2 Vérifier l'avancement

Le téléchargement du modèle (4.7GB) peut prendre 5-10 minutes.

Vous verrez dans les logs :
```
📦 Téléchargement de Qwen 2.5 Coder 7B...
pulling manifest
pulling 60e05f210007: 100% ▕███████████████████████████████████████████████████████▏ 4.7 GB
```

### 3.3 Vérifier que c'est terminé

À la fin, vous verrez :
```
✅ Initialisation terminée !
📊 Informations :
   - URL : https://arteia-ollama.hf.space
   - API : https://arteia-ollama.hf.space/api/chat
   - Modèle : qwen2.5-coder:7b
```

---

## ✅ Étape 4 : Tester le serveur (2 minutes)

### 4.1 Tester avec curl

Ouvrir un terminal et taper :

```bash
curl https://arteia-ollama.hf.space/api/tags
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

### 4.2 Tester une génération

```bash
curl https://arteia-ollama.hf.space/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [
    {"role": "user", "content": "Bonjour, qui es-tu ?"}
  ],
  "stream": false
}'
```

Vous devriez recevoir une réponse en français.

---

## 📱 Étape 5 : Configurer l'application (2 minutes)

### 5.1 Mettre à jour le code

Ouvrir le fichier `arteia_flutter/lib/services/ai_assistant_service.dart`

Trouver les lignes 8-10 :

```dart
static const String _ollamaUrl = 'http://localhost:11434/api/chat';
static const String _ollamaUrlBackup = 'http://localhost:11434/api/chat';
```

Remplacer par :

```dart
static const String _ollamaUrl = 'https://arteia-ollama.hf.space/api/chat';
static const String _ollamaUrlBackup = 'https://arteia-ollama.hf.space/api/chat';
```

### 5.2 Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

L'APK sera généré dans :
```
arteia_flutter/build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Étape 6 : Tester l'application (2 minutes)

### 6.1 Installer l'APK

1. Transférer l'APK sur votre téléphone Android
2. Installer l'APK
3. Ouvrir l'application

### 6.2 Tester l'IA

1. Aller dans l'IA (assistant)
2. Envoyer un message : "Bonjour !"
3. Vérifier que la réponse vient de Qwen 2.5 Coder 7B

---

## 📊 Vérification

### Test 1 : Vérifier que le Space fonctionne

```bash
# Test de connectivité
curl https://arteia-ollama.hf.space/api/tags

# Test de génération
curl https://arteia-ollama.hf.space/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [{"role": "user", "content": "Bonjour !"}],
  "stream": false
}'
```

### Test 2 : Vérifier les logs

Dans Hugging Face Spaces :
1. Aller dans l'onglet **"Logs"**
2. Vous devriez voir les requêtes en temps réel

---

## ⚠️ Limitations de Hugging Face Spaces

### RAM limitée (1GB)
- Qwen 2.5 Coder 7B nécessite 4.7GB
- Hugging Face utilise du **swap** (disque)
- **Résultat :** Plus lent que sur un serveur normal
- **Solution :** Ajouter du swap dans le script

### Cold start
- Si le Space est inactif 1h, il se met en veille
- Premier démarrage : 30-60 secondes
- **Solution :** Utiliser un service de ping (UptimeRobot) pour garder le Space actif

### Limite de requêtes
- ~10-15 requêtes/minute
- Suffisant pour un usage personnel ou petit groupe
- **Solution :** Mettre en cache les réponses

---

## 🔧 Améliorations possibles

### Ajouter du swap (recommandé)

Modifier le `init.sh` :

```bash
#!/bin/bash

# Ajouter du swap (4GB)
echo "📦 Ajout de swap (4GB)..."
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Démarrer Ollama
ollama serve &
OLLAMA_PID=$!

# ... reste du script
```

### Garder le Space actif

Utiliser un service de ping gratuit :
1. Aller sur https://uptimerobot.com
2. Créer un compte (gratuit)
3. Ajouter un monitor :
   - URL : `https://arteia-ollama.hf.space/api/tags`
   - Intervalle : 5 minutes
4. Le Space ne se mettra plus en veille

---

## 🆘 Dépannage

### Problème : "Out of memory"

**Solution :** Ajouter du swap (voir ci-dessus)

### Problème : "Connection timeout"

**Cause :** Le Space est en veille (cold start)

**Solution :** Attendre 30-60 secondes et réessayer

### Problème : "Model not found"

**Solution :** Vérifier les logs
```bash
# Dans Hugging Face Spaces, onglet Logs
ollama list
```

### Problème : "Slow responses"

**Cause :** Swap lent (disque au lieu de RAM)

**Solution :** C'est normal sur Hugging Face Spaces. Pour plus de vitesse, utilisez Oracle Cloud.

---

## ✅ Checklist

- [ ] Space créé sur Hugging Face
- [ ] Dockerfile uploadé
- [ ] init.sh uploadé
- [ ] Build terminé (5-10 minutes)
- [ ] Modèle téléchargé (4.7GB)
- [ ] Test curl réussi
- [ ] URL mise à jour dans le code Flutter
- [ ] APK rebuild
- [ ] Test depuis l'application réussi

---

## 📞 Support

- **Hugging Face Docs :** https://huggingface.co/docs/hub/spaces-sdks-docker
- **Ollama Docs :** https://github.com/ollama/ollama
- **Arteïa Guide :** Consultez `SOLUTIONS_GRATUITES_ILLIMITEES.md`

---

**Félicitations ! Votre serveur Ollama avec Qwen 2.5 Coder 7B est maintenant en ligne !** 🎉

**URL :** `https://arteia-ollama.hf.space`

**Prochaine étape :** Mettre à jour le code Flutter et rebuild l'APK !