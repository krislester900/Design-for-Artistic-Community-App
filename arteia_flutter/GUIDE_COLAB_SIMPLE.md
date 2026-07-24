# 🚀 Google Colab - Guide ULTRA SIMPLE (Pas à pas avec images)

## 📋 Vue d'ensemble

Vous allez créer un **nouveau notebook** et ajouter 7 cells de code.

**Temps total :** 15 minutes

---

## ⚡ ÉTAPE 1 : Créer un nouveau notebook (30 secondes)

### 1.1 Aller sur Colab

**Ouvrir ce lien :** https://colab.research.google.com/notebooks/intro.ipynb

Vous voyez cette page :

```
┌─────────────────────────────────────────┐
│  Welcome to Colaboratory                 │
│                                          │
│  [New Notebook]                          │
│                                          │
│  Recent Files:                           │
│  - intro.ipynb                           │
│  - Untitled0.ipynb                       │
└─────────────────────────────────────────┘
```

### 1.2 Créer un nouveau notebook

**Cliquer sur :** `New Notebook` (en haut à gauche)

**OU**

**Menu :** File → New notebook

**Résultat :** Un nouveau notebook s'ouvre avec une cellule vide

---

## 💻 ÉTAPE 2 : Comprendre l'interface (10 secondes)

### Vous voyez maintenant :

```
┌─────────────────────────────────────────┐
│  Untitled0.ipynb                    [─][□][×] │
├─────────────────────────────────────────┤
│                                         │
│  [ ] ← Cellule vide (avec un bouton [+] │
│      à gauche)                           │
│                                         │
│                                         │
│  [▶️ Run] ← Bouton pour exécuter        │
│                                         │
└─────────────────────────────────────────┘
```

### Les éléments importants :

1. **Cellule vide** : `[ ]` avec un `[+]` à gauche
2. **Bouton Play** : `[▶️]` pour exécuter
3. **Menu +** : En haut à gauche pour ajouter des cells

---

## 📝 ÉTAPE 3 : Ajouter la Cell 1 (1 minute)

### 3.1 Cliquer sur le `[+]`

**Vous voyez :** Une nouvelle cellule vide apparaît

```
┌─────────────────────────────────────────┐
│  Untitled0.ipynb                    [─][□][×] │
├─────────────────────────────────────────┤
│                                         │
│  [+] ← Cliquez ICI                      │
│                                         │
│  [ ] Cellule vide                       │
│                                         │
└─────────────────────────────────────────┘
```

### 3.2 Coller le code

**Copier ce code :**
```bash
!apt-get update && apt-get install -y zstd
```

**Coller dans la cellule** (Ctrl+V)

**Vous voyez :**
```
┌─────────────────────────────────────────┐
│  Untitled0.ipynb                    [─][□][×] │
├─────────────────────────────────────────┤
│                                         │
│  [1] [+]                                │
│                                         │
│  !apt-get update && apt-get install -y zstd │
│                                         │
│                    [▶️ Run]              │
│                                         │
└─────────────────────────────────────────┘
```

### 3.3 Exécuter la cellule

**Cliquer sur :** `[▶️ Run]`

**Attendre :** ~30 secondes

**Résultat :** Installation de zstd

---

## 📝 ÉTAPE 4 : Ajouter la Cell 2 (30 secondes)

### 4.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 4.2 Coller le code

```bash
!curl -fsSL https://ollama.com/install.sh | sh
```

### 4.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Attendre :** ~30 secondes

**Résultat :** Installation d'Ollama

---

## 📝 ÉTAPE 5 : Ajouter la Cell 3 (30 secondes)

### 5.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 5.2 Coller le code

```bash
!ollama serve &
```

### 5.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Attendre :** ~5 secondes

---

## 📝 ÉTAPE 6 : Ajouter la Cell 4 (20 secondes)

### 6.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 6.2 Coller le code

```python
import time
time.sleep(10)
print("Ollama devrait être prêt...")
```

### 6.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Attendre :** 10 secondes

---

## 📝 ÉTAPE 7 : Ajouter la Cell 5 (30 secondes)

### 7.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 7.2 Coller le code

```bash
!ollama pull qwen2.5-coder:7b
```

### 7.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Attendre :** 5-10 minutes (4.7GB)

**Vous voyez :**
```
pulling manifest
pulling 60e05f210007: 100% ▕███████████████████████████████████████████████████████▏ 4.7 GB
```

---

## 📝 ÉTAPE 8 : Ajouter la Cell 6 (30 secondes)

### 8.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 8.2 Coller le code

```bash
!pip install pyngrok
```

### 8.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Attendre :** ~30 secondes

---

## 📝 ÉTAPE 9 : Ajouter la Cell 7 (20 secondes)

### 9.1 Ajouter une nouvelle cellule

**Cliquer sur :** `[+]`

### 9.2 Coller le code

```python
from pyngrok import ngrok
public_url = ngrok.connect(11434)
print(f"URL: {public_url}")
```

### 9.3 Exécuter

**Cliquer sur :** `[▶️ Run]`

**Résultat :**
```
URL: https://abc123.ngrok.io
```

**COPIEZ CETTE URL !**

---

## ✅ ÉTAPE 10 : Configurer l'application (2 minutes)

### 10.1 Mettre à jour le code Flutter

**Ouvrir :** `arteia_flutter/lib/services/ai_assistant_service.dart`

**Trouver la ligne 8-10 :**
```dart
static const String _ollamaUrl = 'http://localhost:11434/api/chat';
static const String _ollamaUrlBackup = 'http://localhost:11434/api/chat';
```

**Remplacer par :**
```dart
static const String _ollamaUrl = 'https://abc123.ngrok.io/api/chat';
static const String _ollamaUrlBackup = 'https://abc123.ngrok.io/api/chat';
```

**Remplacez `abc123.ngrok.io` par votre URL !**

### 10.2 Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

**Attendre :** ~5 minutes

---

## 🎯 RÉCAPITULATIF VISUEL

### Vous devez avoir 7 cells :

```
┌─────────────────────────────────────────┐
│  Untitled0.ipynb                    [─][□][×] │
├─────────────────────────────────────────┤
│                                         │
│  [1] [+]                                │
│  !apt-get update && apt-get install -y zstd │
│                    [▶️ Run]              │
│                                         │
│  [2] [+]                                │
│  !curl -fsSL https://ollama.com/install.sh | sh │
│                    [▶️ Run]              │
│                                         │
│  [3] [+]                                │
│  !ollama serve &                        │
│                    [▶️ Run]              │
│                                         │
│  [4] [+]                                │
│  import time                            │
│  time.sleep(10)                         │
│                    [▶️ Run]              │
│                                         │
│  [5] [+]                                │
│  !ollama pull qwen2.5-coder:7b          │
│                    [▶️ Run]              │
│                                         │
│  [6] [+]                                │
│  !pip install pyngrok                   │
│                    [▶️ Run]              │
│                                         │
│  [7] [+]                                │
│  from pyngrok import ngrok              │
│  public_url = ngrok.connect(11434)      │
│  print(f"URL: {public_url}")            │
│                    [▶️ Run]              │
│                                         │
└─────────────────────────────────────────┘
```

---

## ⚠️ IMPORTANT : Ordre d'exécution

**Exécutez les cells DANS L'ORDRE :**

1. Cell 1 (installer zstd)
2. Cell 2 (installer Ollama)
3. Cell 3 (démarrer Ollama)
4. Cell 4 (attendre 10s)
5. Cell 5 (télécharger modèle)
6. Cell 6 (installer Ngrok)
7. Cell 7 (récupérer URL)

**NE PAS SAUTER D'ÉTAPES !**

---

## 🆘 Dépannage

### Problème : "Je ne vois pas le [+]"

**Solution :** Le [+] est à GAUCHE de chaque cellule

### Problème : "Je ne sais pas où coller le code"

**Solution :** Cliquez dans la cellule vide, puis Ctrl+V

### Problème : "Le bouton Run ne marche pas"

**Solution :** Vérifiez que vous avez bien collé le code dans la cellule

### Problème : "Erreur dans Cell 1"

**Solution :** Vérifiez votre connexion internet

---

## ✅ Checklist

- [ ] Nouveau notebook créé
- [ ] Cell 1 : zstd installé
- [ ] Cell 2 : Ollama installé
- [ ] Cell 3 : Ollama démarré
- [ ] Cell 4 : Attente 10s
- [ ] Cell 5 : Modèle téléchargé
- [ ] Cell 6 : Ngrok installé
- [ ] Cell 7 : URL Ngrok récupérée
- [ ] Code Flutter mis à jour
- [ ] APK rebuild

---

## 🎯 Résumé

**C'est simple :**
1. Créer un nouveau notebook
2. Ajouter 7 cells (cliquer sur [+])
3. Coller le code dans chaque cell
4. Exécuter chaque cell (bouton ▶️ Run)
5. Récupérer l'URL Ngrok
6. Mettre à jour le code Flutter
7. Rebuild l'APK

**C'est tout !** 🎉

---

**Besoin d'aide ?** Consultez `GUIDE_GOOGLE_COLAB.md` pour plus de détails.