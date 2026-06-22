#!/bin/bash
# Script de setup automatique pour Supabase
# À exécuter APRÈS avoir créé le projet sur supabase.com

echo "🚀 Setup rapide d'Artéïa"
echo "=========================="
echo ""

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI n'est pas installé"
    echo "📦 Installation..."
    brew install supabase/tap/supabase
fi

echo "✅ Supabase CLI détecté"

# Demander les informations
echo ""
echo "📝 Configuration requise :"
read -p "Entrez votre projet Supabase (ex: abcdefghijklmnop): " PROJECT_ID
read -p "Entrez votre SUPABASE_URL: " SUPABASE_URL
read -p "Entrez votre SUPABASE_ANON_KEY: " SUPABASE_KEY

# Créer le fichier .env
echo ""
echo "📄 Création du fichier .env..."
cat > .env << EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_KEY
EOF

echo "✅ Fichier .env créé"

# Appliquer le schéma SQL
echo ""
echo "🗄️  Application du schéma de base de données..."
supabase db push --project-id $PROJECT_ID --file database/schema-messaging.sql

echo ""
echo "✅ Setup terminé !"
echo ""
echo "📱 Pour builder l'APK :"
echo "   flutter pub get"
echo "   flutter build apk --release"