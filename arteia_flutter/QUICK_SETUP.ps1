# Script de setup automatique pour Supabase (Windows PowerShell)
# À exécuter APRÈS avoir créé le projet sur supabase.com

Write-Host "🚀 Setup rapide d'Artéïa" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""

# Demander les informations
Write-Host "📝 Configuration requise :" -ForegroundColor Yellow
Write-Host ""

$projectId = Read-Host "Entrez votre projet Supabase (ex: abcdefghijklmnop)"
$supabaseUrl = Read-Host "Entrez votre SUPABASE_URL (https://xxx.supabase.co)"
$supabaseKey = Read-Host "Entrez votre SUPABASE_ANON_KEY"

# Créer le fichier .env
Write-Host ""
Write-Host "📄 Création du fichier .env..." -ForegroundColor Yellow

$envContent = @"
SUPABASE_URL=$supabaseUrl
SUPABASE_ANON_KEY=$supabaseKey
"@

$envContent | Out-File -FilePath "assets/.env" -Encoding UTF8

Write-Host "✅ Fichier assets/.env créé" -ForegroundColor Green

# Instructions pour appliquer le SQL
Write-Host ""
Write-Host "🗄️  Application du schéma de base de données..." -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  ACTION MANUELLE REQUISE :" -ForegroundColor Red
Write-Host "1. Va sur https://supabase.com/dashboard/project/$projectId/editor" -ForegroundColor White
Write-Host "2. Clique sur 'SQL Editor'" -ForegroundColor White
Write-Host "3. Ouvre le fichier database/schema-messaging.sql" -ForegroundColor White
Write-Host "4. Copie tout le contenu et colle dans l'éditeur" -ForegroundColor White
Write-Host "5. Clique sur 'Run' (▶️)" -ForegroundColor White
Write-Host ""

$createBucket = Read-Host "As-tu créé le bucket 'voice_messages' dans Storage ? (o/n)"

if ($createBucket -eq "n") {
    Write-Host ""
    Write-Host "📦 Crée le bucket :" -ForegroundColor Yellow
    Write-Host "1. Va sur https://supabase.com/dashboard/project/$projectId/storage/buckets" -ForegroundColor White
    Write-Host "2. Clique sur 'New bucket'" -ForegroundColor White
    Write-Host "3. Nom: voice_messages" -ForegroundColor White
    Write-Host "4. Coche 'Public bucket'" -ForegroundColor White
    Write-Host "5. Clique sur 'Create bucket'" -ForegroundColor White
}

Write-Host ""
Write-Host "✅ Setup terminé !" -ForegroundColor Green
Write-Host ""
Write-Host "📱 Pour builder l'APK :" -ForegroundColor Cyan
Write-Host "   cd arteia_flutter" -ForegroundColor White
Write-Host "   flutter pub get" -ForegroundColor White
Write-Host "   flutter build apk --release" -ForegroundColor White
Write-Host ""
Write-Host "🎉 L'application est prête !" -ForegroundColor Green

Read-Host "Appuie sur Entrée pour fermer"