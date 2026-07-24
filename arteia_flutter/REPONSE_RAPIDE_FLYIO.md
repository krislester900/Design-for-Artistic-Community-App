
# ⚡ Réponse Rapide : Fly.io - "Choose a Static template"

## ❌ NE CHOISISSEZ PAS de template Static !

**Quand Fly.io vous demande "Choose a Static template" :**

- ❌ **NE CHOISISSEZ PAS** "Static" ou un template quelconque
- ✅ **Appuyez simplement sur Entrée** pour ignorer
- ✅ **OU répondez "No"** si on vous demande

---

## ✅ La bonne commande (sans template)

```bash
fly launch --image ollama/ollama:latest
```

**Cette commande :**
- ✅ Utilise directement l'image Docker d'Ollama
- ✅ Ne demande PAS de template Static
- ✅ Déploie Ollama directement

---

## 📋 Réponses aux questions Fly.io

Quand vous lancez `fly launch --image ollama/ollama:latest`, répondez :

```
? App Name: arteia-ollama
? Organization: personal
? Region: iad
? PostgreSQL: No
? Redis: No
? Deploy now: Yes
```

**Si on vous demande "Choose a Static template" :**
- Appuyez sur **Entrée** (ignorer)
- OU répondez **"No"**

---

## 🎯 Résumé

**Template Static = ❌ PAS BESOIN**

**Utilisez simplement :**
```bash
fly launch --image ollama/ollama:latest
```

**C'est tout !** Fly.io va déployer Ollama directement sans template.

---

## 🚀 Commandes complètes

```bash
# 1. Installer Fly CLI
iwr https://fly.io/install.ps1 -useb | iex

# 2. Se connecter
fly auth login

# 3. Déployer Ollama (SANS template Static)
cd arteia_flutter
fly launch --image ollama/ollama:latest

# 4. Créer un volume
fly volumes create ollama_data --size 10 --region iad

# 5. Configurer
fly secrets set OLLAMA_HOST=0.0.0.0 OLLAMA_PORT=11434

# 6. Télécharger le modèle
fly ssh console
ollama pull qwen2.5-coder:7b
exit

# 7. Récupérer l'URL
fly status

# 8. Tester
curl https://arteia-ollama.fly.dev/api/tags
```

---

**C'est simple : NE CHOISISSEZ PAS de template Static, utilisez juste l'image Ollama !** 🎉