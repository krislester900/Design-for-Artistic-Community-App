# 🚀 Guide Google Colab - Ollama + Qwen 2.5 Coder 7B (SANS CARTE)

## ✅ Avantages

- ✅ **PAS DE CARTE BANCAIRE**
- ✅ **100% gratuit**
- ✅ GPU gratuit
- ✅ Ollama fonctionne
- ✅ Qwen 2.5 Coder 7B disponible

## ⚠️ Inconvénients

- ⚠️ 12h par session
- ⚠️ URL changeante (Ngrok)
- ⚠️ Doit être relancé manuellement

---

## 📋 Étape 1 : Ouvrir Google Colab (1 minute)

1. Aller sur https://colab.research.google.com
2. Cliquer sur **"New Notebook"**

---

## 💻 Étape 2 : Installer Ollama (Cell 1)

Cliquer sur **"+"** pour ajouter une cellule de code

Copier-coller ce code :

```bash
!curl -fsSL https://ollama.com/install.sh | sh
```

Cliquer sur **"Play"** (▶️) pour exécuter

**Temps :** ~30 secondes

---

## 🚀 Étape 3 : Démarrer Ollama (Cell 2)

Ajouter une nouvelle cellule :

```bash
!ollama serve &
```

Cliquer sur **"Play"**

**Temps :** ~5 secondes

---

## ⏳ Étape 4 : Attendre le démarrage (Cell 3)

Ajouter une nouvelle cellule :

```python
import time
time.sleep(10)
print("Ollama devrait être prêt...")
```

Cliquer sur **"Play"**

**Temps :** 10 secondes

---

## 📦 Étape 5 : Télécharger Qwen 2.5 Coder 7B (Cell 4)

Ajouter une nouvelle cellule :

```bash
!ollama pull qwen2.5-coder:7b
```

Cliquer sur **"Play"**

**Temps :** 5-10 minutes (4.7GB)

Vous verrez :
```
pulling manifest
pulling 60e05f210007: 100% ▕███████████████████████████████████████████████████████▏ 4.7 GB
```

---

## 🔌 Étape 6 : Installer Ngrok (Cell 5)

Ajouter une nouvelle cellule :

```bash
!pip install pyngrok
```

Cliquer sur **"Play"**

**Temps :** ~30 secondes

---

## 🌐 Étape 7 : Exposer Ollama avec Ngrok (Cell 6)

Ajouter une nouvelle cellule :

```python
from pyngrok import ngrok
public_url = ngrok.connect(11434)
print(f"URL: {public_url}")
```

Cliquer sur **"Play"**

**Résultat :**
```
URL: https://abc123.ngrok.io
```

**COPIEZ CETTE URL !**

---

## 📱 Étape 8 : Configurer l'application (2 minutes)

### 8.1 Mettre à jour le code

Ouvrir : `arteia_flutter/lib/services/ai_assistant_service.dart`

**Ligne 8-10 :** Remplacer par :
```dart
static const String _ollamaUrl = 'https://abc123.ngrok.io/api/chat';
static const String _ollamaUrlBackup = 'https://abc123.ngrok.io/api/chat';
```

**Remplacez `abc123.ngrok.io` par votre URL Ngrok !**

### 8.2 Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

**Temps :** ~5 minutes

---

## ✅ Étape 9 : Tester (2 minutes)

### 9.1 Tester le serveur

```bash
curl https://abc123.ngrok.io/api/tags
```

**Remplacer par votre URL Ngrok !**

### 9.2 Tester l'application

1. Installer l'APK sur votre téléphone
2. Ouvrir l'application
3. Aller dans l'IA
4. Envoyer : "Bonjour !"
5. Vérifier la réponse

---

## ⚠️ IMPORTANT : Limitations de Google Colab

### 1. Session de 12h

**Problème :** Colab coupe la session après 12h maximum

**Solution :** 
- Sauvegarder votre travail
- Relancer les cells
- Récupérer une nouvelle URL Ngrok
- Mettre à jour le code et rebuild l'APK

### 2. URL changeante

**Problème :** Ngrok change d'URL à chaque redémarrage

**Solution :**
- Noter la nouvelle URL
- Mettre à jour le code Flutter
- Rebuild l'APK

### 3. Cold start

**Problème :** Si inactif 1h, Colab se met en veille

**Solution :** Utiliser un service de ping (UptimeRobot) pour garder Colab actif

---

## 🔄 Garder Colab actif (OPTIONNEL)

### Utiliser UptimeRobot (gratuit)

1. Aller sur https://uptimerobot.com
2. Créer un compte (gratuit)
3. Ajouter un monitor :
   - URL : `https://abc123.ngrok.io/api/tags`
   - Intervalle : 5 minutes
4. Colab restera actif

---

## 📊 Gestion des sessions

### Débuter une nouvelle session

1. Aller sur https://colab.research.google.com
2. Ouvrir votre notebook
3. Exécuter toutes les cells (1-7)
4. Récupérer la nouvelle URL Ngrok
5. Mettre à jour le code Flutter
6. Rebuild l'APK

### Arrêter une session

1. Fermer l'onglet Colab
2. Ou cliquer sur **"Runtime"** → **"Disconnect and delete runtime"**

---

## 🆘 Dépannage

### Problème : "Ollama not found"

**Solution :** Vérifier que Cell 1 et 2 ont été exécutées

### Problème : "Connection refused"

**Solution :** 
- Vérifier que Cell 3 (sleep) a été exécutée
- Vérifier que Cell 7 (Ngrok) a été exécutée
- Récupérer la nouvelle URL Ngrok

### Problème : "Model not found"

**Solution :** Vérifier que Cell 4 a été exécutée
```bash
!ollama list
```

### Problème : "Timeout"

**Solution :** Colab est lent au premier démarrage. Attendre 30-60 secondes.

---

## ✅ Checklist

- [ ] Compte Google créé
- [ ] Notebook Colab créé
- [ ] Cell 1 : Ollama installé
- [ ] Cell 2 : Ollama démarré
- [ ] Cell 3 : Attente 10s
- [ ] Cell 4 : Modèle téléchargé (4.7GB)
- [ ] Cell 5 : Ngrok installé
- [ ] Cell 6 : URL Ngrok récupérée
- [ ] Code Flutter mis à jour
- [ ] APK rebuild
- [ ] Test réussi

---

## 🎯 Résumé

**Google Colab c'est :**
- ✅ 100% gratuit
- ✅ Pas de carte bancaire
- ✅ GPU gratuit
- ✅ Ollama + Qwen 2.5 Coder 7B
- ⚠️ 12h par session
- ⚠️ URL changeante

**Commandes :**
```bash
# Cell 1
!curl -fsSL https://ollama.com/install.sh | sh

# Cell 2
!ollama serve &

# Cell 3
import time; time.sleep(10)

# Cell 4
!ollama pull qwen2.5-coder:7b

# Cell 5
!pip install pyngrok

# Cell 6
from pyngrok import ngrok; print(ngrok.connect(11434))
```

---

**C'est la meilleure solution 100% gratuite SANS carte bancaire !** 🎉

**Prochaine étape :** Exécuter les cells et récupérer l'URL Ngrok !