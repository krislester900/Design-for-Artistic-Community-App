# 🆓 Solutions 100% Gratuites et Open Source pour Qwen 2.5 Coder 7B

## 📋 Vue d'ensemble

Toutes ces solutions sont **100% gratuites**, **open source**, et ne nécessitent **aucun paiement**.

---

## ⭐ Option 1 : Hugging Face Spaces (RECOMMANDÉ)

### Avantages
- ✅ **100% gratuit** (pas de limite de temps)
- ✅ **Illimité** dans le temps
- ✅ Open source
- ✅ Pas de carte bancaire requise
- ✅ 1GB RAM gratuit (suffisant pour Qwen 2.5 Coder 7B avec swap)

### Inconvénients
- ⚠️ 1GB RAM seulement (nécessite du swap pour Qwen 2.5 Coder 7B)
- ⚠️ Lent au premier démarrage (cold start)
- ⚠️ Limité à 10-15 requêtes/minute

### Procédure

#### Étape 1 : Créer un compte Hugging Face
1. Aller sur https://huggingface.co
2. Cliquer sur "Sign Up"
3. Créer un compte (gratuit)

#### Étape 2 : Créer un Space Docker
1. Aller sur https://huggingface.co/spaces
2. Cliquer sur "Create new Space"
3. Nom : `arteia-ollama`
4. SDK : **Docker**
5. Visibilité : Public ou Private

#### Étape 3 : Créer le Dockerfile

Dans votre Space, créer un fichier `Dockerfile` :

```dockerfile
FROM ollama/ollama:latest

# Installer les dépendances
RUN apt-get update && apt-get install -y curl

# Exposer le port
EXPOSE 11434

# Script d'initialisation
COPY init.sh /init.sh
RUN chmod +x /init.sh

CMD ["/init.sh"]
```

#### Étape 4 : Créer le script init.sh

```bash
#!/bin/bash

# Démarrer Ollama
ollama serve &

# Attendre qu'Ollama soit prêt
sleep 5

# Pull le modèle
ollama pull qwen2.5-coder:7b

# Garder le conteneur en vie
tail -f /dev/null
```

#### Étape 5 : Commit et déployer

```bash
git add .
git commit -m "Deploy Ollama with Qwen 2.5 Coder 7B"
git push
```

#### Étape 6 : Récupérer l'URL

L'URL sera : `https://arteia-ollama.hf.space`

#### Étape 7 : Configurer l'application

```dart
static const String _ollamaUrl = 'https://arteia-ollama.hf.space/api/chat';
```

---

## ⭐ Option 2 : Oracle Cloud Free Tier (MEILLEUR - 4GB RAM)

### Avantages
- ✅ **100% gratuit à vie**
- ✅ **4GB RAM** (suffisant pour Qwen 2.5 Coder 7B)
- ✅ Open source
- ✅ Pas de limite de temps
- ✅ Serveur dédié 24/7

### Inconvénients
- ⚠️ Nécessite une carte bancaire (vérification seulement)
- ⚠️ Configuration plus technique

### Procédure

#### Étape 1 : Créer un compte Oracle Cloud
1. Aller sur https://www.oracle.com/cloud/free/
2. Cliquer sur "Start for free"
3. Créer un compte
4. Ajouter une carte bancaire (vérification $1, pas de débit)

#### Étape 2 : Créer une VM
1. Aller dans **"Compute"** → **"Instances"**
2. Cliquer sur **"Create Instance"**
3. Configuration :
   - Name : `arteia-ollama`
   - Image : **Ubuntu 22.04**
   - Shape : **VM.Standard.E2.1.Micro** (1 OCPU, 1GB RAM)
   - SSH Key : Créer ou uploader une clé SSH
4. Cliquer sur **"Create"**

#### Étape 3 : Se connecter en SSH

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@ip-publique
```

#### Étape 4 : Installer Ollama

```bash
# Installer Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull le modèle
ollama pull qwen2.5-coder:7b

# Configurer Ollama
sudo nano /etc/systemd/system/ollama.service
```

Contenu du fichier :
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
# Démarrer le service
sudo systemctl enable ollama
sudo systemctl start ollama
sudo systemctl status ollama

# Ouvrir le firewall
sudo ufw allow 11434/tcp
```

#### Étape 5 : Récupérer l'IP publique

```bash
curl ifconfig.me
```

#### Étape 6 : Configurer l'application

```dart
static const String _ollamaUrl = 'http://IP-PUBLIQUE:11434/api/chat';
```

---

## ⭐ Option 3 : Google Cloud Free Tier (1 an gratuit)

### Avantages
- ✅ **Gratuit pendant 1 an**
- ✅ **4GB RAM** (e2-standard-4)
- ✅ Open source
- ✅ Fiable

### Inconvénients
- ⚠️ Gratuit seulement 1 an
- ⚠️ Nécessite carte bancaire

### Procédure

#### Étape 1 : Créer un compte GCP
1. Aller sur https://cloud.google.com/free
2. Créer un compte
3. Ajouter une carte bancaire

#### Étape 2 : Créer une VM
1. Aller dans **"Compute Engine"** → **"VM instances"**
2. Cliquer sur **"Create Instance"**
3. Configuration :
   - Name : `arteia-ollama`
   - Machine : **e2-standard-4** (4 vCPU, 16GB RAM)
   - Boot disk : **Ubuntu 22.04**
   - Firewall : Autoriser HTTP/HTTPS
4. Cliquer sur **"Create"**

#### Étape 3 : Installer Ollama (même procédure que Oracle)

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@ip-publique

curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5-coder:7b

sudo systemctl enable ollama
sudo systemctl start ollama
```

---

## ⭐ Option 4 : AWS Free Tier (1 an gratuit)

### Avantages
- ✅ **Gratuit pendant 1 an**
- ✅ **1GB RAM** (t2.micro)
- ✅ Open source

### Inconvénients
- ⚠️ 1GB RAM seulement (nécessite swap)
- ⚠️ Gratuit seulement 1 an

### Procédure

#### Étape 1 : Créer un compte AWS
1. Aller sur https://aws.amazon.com/free/
2. Créer un compte
3. Ajouter une carte bancaire

#### Étape 2 : Lancer une instance EC2
1. Aller dans **"EC2"** → **"Instances"**
2. Cliquer sur **"Launch Instance"**
3. Configuration :
   - AMI : **Ubuntu Server 22.04 LTS**
   - Instance type : **t2.micro** (1GB RAM)
   - Security Group : Ouvrir port 11434
4. Lancer l'instance

#### Étape 3 : Installer Ollama (même procédure)

---

## ⭐ Option 5 : Fly.io (500h/mois gratuites)

### Avantages
- ✅ **500h/mois gratuites** (suffisant pour 1 mois sur 2)
- ✅ Open source
- ✅ Simple à déployer

### Inconvénients
- ⚠️ 500h/mois seulement (pas 24/7)
- ⚠️ Nécessite de stop/start la VM

### Procédure

```bash
# Installer Fly CLI
curl -L https://fly.io/install.sh | sh

# Se connecter
fly auth login

# Lancer l'app
cd arteia_flutter
fly launch --image ollama/ollama:latest

# Créer le volume
fly volumes create ollama_data --size 10

# Déployer
fly deploy

# Récupérer l'URL
fly status
```

**Note :** Avec 500h/mois, vous pouvez garder la VM allumée ~20 jours par mois.

---

## ⭐ Option 6 : Render.com (750h/mois gratuites)

### Avantages
- ✅ **750h/mois gratuites**
- ✅ Open source
- ✅ Simple

### Inconvénients
- ⚠️ 750h/mois seulement (~25 jours par mois)
- ⚠️ Cold start après inactivité

### Procédure

1. Aller sur https://render.com
2. Créer un compte
3. **"New"** → **"Docker"**
4. Connecter le repository
5. Sélectionner `arteia_flutter/Dockerfile`
6. Plan : **Free**
7. Ajouter un disque de 10GB
8. Déployer

---

## 🆓 Meilleure Combinaison 100% Gratuite

### Pour un usage personnel :

**Oracle Cloud Free Tier** (meilleur)
- 4GB RAM à vie
- Serveur 24/7
- Pas de limite de temps

### Pour un petit groupe :

**Hugging Face Spaces** (simple)
- 1GB RAM gratuit
- Illimité dans le temps
- Facile à déployer

**+ Fly.io** (complément)
- 500h/mois gratuites
- Pour les pics de charge

---

## 📊 Comparaison des Solutions Gratuites

| Solution | RAM | Durée | Fiabilité | Difficulté |
|----------|-----|-------|-----------|-----------|
| **Oracle Cloud** | 4GB | ∞ (à vie) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ Moyen |
| **Hugging Face** | 1GB | ∞ (à vie) | ⭐⭐⭐ | ⭐⭐ Facile |
| **Google Cloud** | 4GB | 1 an | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ Moyen |
| **AWS** | 1GB | 1 an | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ Moyen |
| **Fly.io** | 1GB | 500h/mois | ⭐⭐⭐⭐ | ⭐⭐ Facile |
| **Render** | 512MB | 750h/mois | ⭐⭐⭐ | ⭐⭐ Facile |

---

## 🎯 Recommandation

### Si vous avez une carte bancaire :
**Oracle Cloud Free Tier**
- 4GB RAM à vie
- Meilleure solution gratuite
- Serveur dédié 24/7

### Si vous n'avez pas de carte bancaire :
**Hugging Face Spaces**
- Pas de carte requise
- Illimité dans le temps
- Simple à déployer

---

## ✅ Checklist Oracle Cloud

- [ ] Créer un compte Oracle Cloud
- [ ] Créer une VM Ubuntu 22.04
- [ ] Se connecter en SSH
- [ ] Installer Ollama
- [ ] Pull Qwen 2.5 Coder 7B
- [ ] Configurer le firewall
- [ ] Récupérer l'IP publique
- [ ] Mettre à jour le code Flutter
- [ ] Rebuild l'APK
- [ ] Tester

---

## 🆘 Dépannage

### Problème : "Out of memory" sur Hugging Face

**Solution :** Ajouter du swap
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Problème : "Connection timeout" sur Oracle

**Solution :** Vérifier le firewall
```bash
sudo ufw allow 11434/tcp
sudo ufw status
```

### Problème : "Model not found"

**Solution :** Vérifier que le modèle est téléchargé
```bash
ollama list
ollama pull qwen2.5-coder:7b
```

---

## 📞 Support

- **Oracle Cloud :** https://docs.oracle.com/en-us/iaas/Content/home.htm
- **Hugging Face :** https://huggingface.co/docs
- **Fly.io :** https://fly.io/docs
- **Render :** https://render.com/docs

---

**Toutes ces solutions sont 100% gratuites et open source !** 🎉