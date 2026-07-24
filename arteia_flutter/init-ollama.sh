#!/bin/bash

# 🚀 Script d'initialisation Ollama pour Arteïa
# Ce script démarre Ollama et télécharge le modèle Qwen 2.5 Coder 7B

set -e

echo "========================================="
echo "🚀 Initialisation d'Ollama - Arteïa AI"
echo "========================================="
echo ""

# Attendre qu'Ollama soit prêt
echo "⏳ Attente du démarrage d'Ollama..."
sleep 5

# Vérifier qu'Ollama répond
echo "🔍 Vérification de la connexion..."
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

echo ""
echo "📦 Téléchargement du modèle Qwen 2.5 Coder 7B..."
echo "   (4.7GB - cela peut prendre quelques minutes)"
echo ""

# Vérifier si le modèle est déjà présent
if curl -s http://localhost:11434/api/tags | grep -q "qwen2.5-coder:7b"; then
    echo "✅ Modèle déjà téléchargé !"
else
    # Pull le modèle
    ollama pull qwen2.5-coder:7b
    echo "✅ Modèle téléchargé avec succès !"
fi

echo ""
echo "========================================="
echo "✅ Initialisation terminée !"
echo "========================================="
echo ""
echo "📊 Informations du serveur :"
echo "   - URL : http://localhost:11434"
echo "   - Modèle : qwen2.5-coder:7b"
echo "   - API : http://localhost:11434/api/chat"
echo ""
echo "🧪 Test rapide :"
echo "   curl http://localhost:11434/api/generate -d '{"
echo "     \"model\": \"qwen2.5-coder:7b\","
echo "     \"prompt\": \"Bonjour !\""
echo "   }'"
echo ""
echo "========================================="

# Garder le conteneur en vie
echo "🔄 Serveur Ollama en cours d'exécution..."
tail -f /dev/null