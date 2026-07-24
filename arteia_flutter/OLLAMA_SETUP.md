# 🚀 Guide de déploiement Ollama pour Arteïa

## 📋 Vue d'ensemble

Ce guide explique comment déployer un serveur Ollama centralisé pour que tous les utilisateurs de l'application Arteïa puissent utiliser l'IA.

**Architecture :**
```
Utilisateurs (APK Android)
    ↓
Serveur Ollama (VPS/Cloud)
    ↓
Qwen 2.5 Coder 7B (4.7GB)
```

---

## 🖥️ Option 1 : VPS / Serveur dédié

### 1.1 Prérequis
- Un VPS (Ubuntu 22.04 recommandé) : 4GB RAM minimum, 8GB recommandé
- Un nom de domaine (optionnel mais recommandé)
- Port 11434 ouvert

### 1.2 Installation d'Ollama

```bash
# Se connecter au VPS
ssh root@votre-serveur.com

# Installer Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Vérifier l'installation
ollama --version
```

### 1.3 Télécharger le modèle

```bash
# Pull le modèle Qwen 2.5 Coder 7B
ollama pull qwen2.5-coder:7b

# Vérifier que le modèle est présent
ollama list
```

### 1.4 Configurer Ollama en mode serveur

```bash
# Créer un service systemd
sudo nano /etc/systemd/system/ollama.service
```

Coller ce contenu :

```ini
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
```

```bash
# Activer et démarrer le service
sudo systemctl enable ollama
sudo systemctl start ollama
sudo systemctl status ollama
```

### 1.5 Configurer le firewall

```bash
# UFW
sudo ufw allow 11434/tcp

# Ou avec iptables
sudo iptables -A INPUT -p tcp --dport 11434 -j ACCEPT
```

### 1.6 Tester depuis l'extérieur

```bash
# Depuis votre machine locale
curl http://votre-serveur.com:11434/api/generate -d '{
  "model": "qwen2.5-coder:7b",
  "prompt": "Bonjour !"
}'
```

---

## ☁️ Option 2 : Cloud (AWS/GCP/Azure)

### 2.1 AWS EC2

```bash
# Lancer une instance EC2
# - Type : t3.large (2 vCPU, 8GB RAM)
# - OS : Ubuntu 22.04
# - Security Group : ouvrir port 11434

# Se connecter et installer Ollama
ssh -i "votre-cle.pem" ubuntu@ip-publique

curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b

# Configurer le service (même fichier que section 1.4)
sudo nano /etc/systemd/system/ollama.service
```

### 2.2 Google Cloud Platform

```bash
# Créer une VM GCP
# - Machine : e2-standard-4 (4 vCPU, 16GB RAM)
# - OS : Ubuntu 22.04
# - Firewall : autoriser port 11434

# Même procédure d'installation
```

### 2.3 Azure

```bash
# Créer une VM Azure
# - Taille : Standard_D4s_v3 (4 vCPU, 16GB RAM)
# - OS : Ubuntu 22.04
# - NSG : ouvrir port 11434
```

---

## 🔒 Sécurité

### 3.1 Authentification (recommandé)

Installer un reverse proxy avec authentification :

```bash
# Installer Nginx
sudo apt install nginx -y

# Créer un fichier de configuration
sudo nano /etc/nginx/sites-available/ollama
```

```nginx
server {
    listen 80;
    server_name api.votre-domaine.com;

    location / {
        proxy_pass http://localhost:11434;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # Authentification basique
        auth_basic "Ollama API";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

```bash
# Créer un utilisateur avec mot de passe
sudo apt install apache2-utils -y
sudo htpasswd -c /etc/nginx/.htpasswd arteia

# Activer la config
sudo ln -s /etc/nginx/sites-available/ollama /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

### 3.2 HTTPS avec Let's Encrypt

```bash
# Installer Certbot
sudo apt install certbot python3-certbot-nginx -y

# Obtenir un certificat
sudo certbot --nginx -d api.votre-domaine.com

# Le certificat se renouvelle automatiquement
```

---

## 📱 Configuration de l'application

### 4.1 Modifier l'URL dans le code

Éditer `arteia_flutter/lib/services/ai_assistant_service.dart` :

```dart
// Ligne 8-10
static const String _ollamaUrl = 'http://votre-serveur.com:11434/api/chat';
static const String _ollamaUrlBackup = 'http://api.votre-domaine.com:11434/api/chat';
```

### 4.2 Rebuild l'APK

```bash
cd arteia_flutter
flutter build apk --release
```

---

## 🧪 Tests

### 5.1 Test de connectivité

```bash
# Test 1 : Vérifier qu'Ollama répond
curl http://votre-serveur.com:11434/api/tags

# Test 2 : Tester une génération
curl http://votre-serveur.com:11434/api/chat -d '{
  "model": "qwen2.5-coder:7b",
  "messages": [
    {"role": "user", "content": "Bonjour, qui es-tu ?"}
  ],
  "stream": false
}'
```

### 5.2 Test depuis l'application

1. Installer l'APK sur un téléphone
2. Ouvrir l'application
3. Aller dans l'IA
4. Envoyer un message : "Bonjour !"
5. Vérifier que la réponse vient d'Ollama

---

## 📊 Monitoring

### 6.1 Vérifier les logs Ollama

```bash
# Voir les logs en temps réel
sudo journalctl -u ollama -f

# Voir les dernières lignes
sudo journalctl -u ollama -n 100
```

### 6.2 Monitoring des ressources

```bash
# Installer htop
sudo apt install htop -y

# Voir l'utilisation CPU/RAM
htop

# Voir les processus Ollama
ps aux | grep ollama
```

### 6.3 Métriques Prometheus (optionnel)

```bash
# Ollama expose des métriques sur /metrics
curl http://localhost:11434/metrics
```

---

## 🔄 Mise à jour du modèle

```bash
# Mettre à jour Ollama
sudo systemctl stop ollama
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl start ollama

# Mettre à jour le modèle
ollama pull qwen2.5-coder:7b

# Redémarrer le service
sudo systemctl restart ollama
```

---

## 🆓 Alternatives gratuites

### 7.1 Fly.io (500h/mois gratuites)

```bash
# Installer Fly CLI
curl -L https://fly.io/install.sh | sh

# Lancer une app
fly launch --image ollama/ollama:latest

# Configurer le volume (4GB minimum)
fly volumes create ollama_data --size 10

# Déployer
fly deploy
```

### 7.2 Railway.app (500h/mois gratuites)

1. Aller sur https://railway.app
2. Créer un nouveau projet
3. Déployer depuis Docker : `ollama/ollama:latest`
4. Ajouter un volume de 10GB
5. Configurer les variables d'environnement

### 7.3 Render.com (750h/mois gratuites)

1. Aller sur https://render.com
2. Créer un service Docker
3. Image : `ollama/ollama:latest`
4. Plan : Free
5. Ajouter un disque de 10GB

---

## 🐳 Option 3 : Docker (recommandé pour le déploiement)

### 8.1 Docker simple

```bash
# Lancer Ollama avec Docker
docker run -d \
  --name ollama \
  --gpus all \
  -p 11434:11434 \
  -v ollama_data:/root/.ollama \
  ollama/ollama:latest

# Pull le modèle
docker exec -it ollama ollama pull qwen2.5-coder:7b
```

### 8.2 Docker Compose

Créer un fichier `docker-compose.yml` :

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    restart: always

volumes:
  ollama_data:
```

```bash
# Démarrer
docker-compose up -d

# Pull le modèle
docker exec -it ollama ollama pull qwen2.5-coder:7b
```

---

## ✅ Checklist de déploiement

- [ ] VPS/Cloud créé (4GB RAM minimum)
- [ ] Ollama installé
- [ ] Modèle `qwen2.5-coder:7b` téléchargé
- [ ] Service Ollama démarré
- [ ] Port 11434 ouvert
- [ ] Test de connectivité réussi
- [ ] (Optionnel) HTTPS configuré
- [ ] (Optionnel) Authentification activée
- [ ] URL mise à jour dans le code Flutter
- [ ] APK rebuild et testé

---

## 🆘 Dépannage

### Problème : "Connection refused"

```bash
# Vérifier qu'Ollama tourne
sudo systemctl status ollama

# Vérifier le port
sudo netstat -tlnp | grep 11434

# Redémarrer le service
sudo systemctl restart ollama
```

### Problème : "Out of memory"

```bash
# Vérifier la RAM disponible
free -h

# Ajouter du swap (temporaire)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Problème : "Model not found"

```bash
# Lister les modèles
ollama list

# Pull le modèle
ollama pull qwen2.5-coder:7b
```

---

## 📞 Support

- Documentation Ollama : https://github.com/ollama/ollama
- Discord Ollama : https://discord.gg/ollama
- Issues : https://github.com/ollama/ollama/issues

---

**Bon déploiement ! 🚀**