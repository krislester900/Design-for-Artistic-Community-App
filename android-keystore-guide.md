kle# Guide : Configurer Google Auth & Play Store

## 1️⃣ Google Auth (Supabase)

**Étapes sur ton compte Google Cloud :**
1. Va sur https://console.cloud.google.com
2. Crée un projet → "APIs & Services" → "Credentials"
3. Crée un "OAuth 2.0 Client ID" → Type "Web application"
4. Dans "Authorized redirect URIs", ajoute :
   ```
   https://[TON_PROJET].supabase.co/auth/v1/callback
   ```

**Étapes sur Supabase :**
1. Va sur https://supabase.com → ton projet
2. Authentication → Providers → Google
3. Active-le, colle le Client ID et Client Secret Google

## 2️⃣ Générer APK Release (Play Store)

```bash
# 1. Générer le keystore
cd "Design for Artistic Community App"
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-25.0.3.9-hotspot"
keytool -genkey -v -keystore arteia-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias arteia

# 2. Copier le keystore dans android/app/
copy arteia-release-key.jks android\app\

# 3. Build Release APK
cd android
$env:ANDROID_HOME = "C:\Users\PC\AppData\Local\Android\Sdk"
./gradlew assembleRelease

# APK signé : android/app/build/outputs/apk/release/app-release.apk
```

## 3️⃣ Play Store Console
1. Va sur https://play.google.com/console
2. Paye les frais d'inscription (25$)
3. Crée une nouvelle application
4. Télécharge l'APK release
5. Remplis les informations (description, screenshots, catégorie)