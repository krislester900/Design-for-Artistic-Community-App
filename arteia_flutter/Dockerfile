# 🚀 Dockerfile pour Ollama - Arteïa AI Assistant
# Basé sur l'image officielle Ollama avec Qwen 2.5 Coder 7B

FROM ollama/ollama:latest

# Exposer le port Ollama
EXPOSE 11434

# Configuration d'Ollama
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_PORT=11434

# Créer un script d'initialisation
COPY init-ollama.sh /init-ollama.sh
RUN chmod +x /init-ollama.sh

# Point d'entrée personnalisé
ENTRYPOINT ["/init-ollama.sh"]