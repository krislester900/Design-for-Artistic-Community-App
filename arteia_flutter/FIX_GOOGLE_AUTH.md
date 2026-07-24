# 🔧 Correction authentification Google - Instructions exactes

## ❌ Problème identifié

Le Client ID `1071743166234-quccefpqmpe8j52rrgalr7753115rdjb` que tu as créé est de type **"Desktop/Installed"** (nommé "arteia"). Ce type ne fonctionne ni avec Supabase ni avec Android.

## ✅ Ce qu'il faut faire dans Google Cloud Console

Va sur **https://console.cloud.google.com/apis/credentials**

### 1. Supprimer l'ancien Client ID "arteia" (Desktop)
- Clique sur l'icône 🗑️ (poubelle) à côté du Client ID nommé "arteia"
- Confirme la suppression

### 2. Créer le Client ID **Web application** (pour Supabase)
Clique **"+ Create Credentials" → "OAuth 2.0 Client ID"**

**Dans la liste déroulante "Application type", choisis :**
⬇️ **"Web application"** ( PAS "Desktop" )

Remplis :
- **Name** : `Arteia Web`
- **Authorized redirect URIs** : clique "+ Add URI" et ajoute :
  ```
  https://wzewlweghntnqyfvhgan.supabase.co/auth/v1/callback
  ```
- Laisse **Authorized JavaScript origins** vide
- Clique **"Create"**

👉 **IMPORTANT :** Une fenêtre apparaît avec **Client ID** et **Client Secret**. Copie-les tout de suite !

### 3. Créer le Client ID **Android** (pour l'app)
Clique à nouveau **"+ Create Credentials" → "OAuth 2.0 Client ID"**

**Dans la liste déroulante, choisis :**
⬇️ **"Android"**

Remplis :
- **Name** : `Arteia Android`
- **Package name** : `com.arteia.arteia_app`
- **SHA-1 certificate fingerprint** : 
  ```
  8C:B1:A4:8C:7F:98:E7:86:AF:6F:81:31:5B:16:64:4F:38:C9:12:12
  ```
- Clique **"Create"**

### 4. Activer Google People API
Va sur https://console.cloud.google.com/apis/library
- Recherche **"Google People API"**
- Clique **"Enable"**

### 5. Configurer Supabase
Va sur https://supabase.com/dashboard → Authentication → Providers → Google
- Active le provider (bascule verte)
- **Client ID** : colle celui du Web (étape 2)
- **Client Secret** : colle le secret du Web (étape 2)
- **Save**

### 6. Tester
```powershell
cd C:\Users\PC\Downloads\"Design for Artistic Community App"\arteia_flutter
flutter build apk --release
flutter install
```

## 📋 Récapitulatif visuel de ce que tu dois voir dans Credentials

| # | Nom | Type | Usage |
|---|-----|------|-------|
| ❌ ~~arteia~~ | ~~Desktop~~ | ~~À supprimer~~ |
| ✅ | Arteia Web | **Web application** | Client ID + Secret → Dans Supabase |
| ✅ | Arteia Android | **Android** | SHA-1 + Package → Utilisé par l'app automatiquement |

## ⚠️ Rappel important
L'erreur que tu avais, c'est d'avoir choisi **"Desktop app"** au lieu de **"Web application"** dans le menu déroulant. Ne refais pas cette erreur !