#!/bin/bash

# 🚀 Script de déploiement automatique d'Ollama pour Arteïa
# Ce script déploie Ollama sur Railway.app (gratuit)

echo "========================================="
echo "🚀 Déploiement Ollama pour Arteïa"
echo "========================================="
echo ""

# Vérifier que Railway CLI est installé
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI n'est pas installé"
    echo "📦 Installation de Railway CLI..."
    npm install -g @railway/cli
fi

# Vérifier la connexion Railway
echo "🔐 Vérification de la connexion Railway..."
if ! railway whoami &> /dev/null; then
    echo "❌ Vous n'êtes pas connecté à Railway"
    echo "📝 Veuillez vous connecter :"
    railway login
fi

echo "✅ Connecté à Railway"
echo ""

# Créer un nouveau projet Railway
echo "📦 Création du projet Railway 'arteia-ollama'..."
railway init arteia-ollama

echo ""
echo "========================================="
echo "✅ Projet créé !"
echo "========================================="
echo ""
echo "📋 Étapes suivantes :"
echo ""
echo "1. Allez sur https://railway.app/project/arteia-ollama"
echo "2. Cliquez sur 'New' → 'Docker'"
echo "3. Utilisez l'image : ollama/ollama:latest"
echo "4. Ajoutez un volume de 10GB nommé 'ollama_data'"
echo "5. Dans les variables d'environnement, ajoutez :"
echo "   - OLLAMA_HOST = 0.0.0.0"
echo "   - OLLAMA_PORT = 11434"
echo ""
echo "6. Attendez le déploiement (2-3 minutes)"
echo "7. Récupérez l'URL du service (ex: https://arteia-ollama.up.railway.app)"
echo ""
echo "8. Mettez à jour l'URL dans le code Flutter :"
echo "   arteia_flutter/lib/services/ai_assistant_service.dart"
echo ""
echo "9. Rebuild l'APK :"
echo "   cd arteia_flutter && flutter build apk --release"
echo ""
echo "========================================="
echo ""

# Créer un fichier railway.json pour la configuration
cat > railway.json << 'EOF'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "numReplicas": 1,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
EOF

echo "✅ Fichier railway.json créé"
echo ""
echo "📝 Pour déployer manuellement :"
echo "   railway up"
echo ""