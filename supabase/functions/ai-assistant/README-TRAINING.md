# 🧠 Guide d'entraînement d'Arteïa Muse

## Architecture d'amélioration continue

```
Sites web / RSS ──▶ daily-learner (quotidien) ──▶ Base de connaissances
  (Colossal,           Edge Function + Groq          (ai_knowledge_base)
   Creative Boom,      résumé automatique)               │
   Poetry Mag, ...)                                       │
                                                          ▼
Connaissances expertes ──▶ Base de connaissances ──▶ RAG (context injection)
                              (ai_knowledge_base)        │
                                                          ▼
Utilisateurs ──▶ Conversations ──▶ Training Data ──▶ Fine-tuning (futur)
                (ai_conversations)  (ai_training_data)
                      │
                      ▼
              Feedback (ai_feedback)
                      │
                      ▼
        Amélioration des prompts système
              (ai_system_prompts)
```

## 📊 Pipeline d'entraînement

### 1. Collecte de données (automatique)
Chaque conversation est automatiquement sauvegardée :
- `ai_conversations` → historique complet
- `ai_training_data` → paires Q/R marquées pour entraînement
- `ai_feedback` → notes et avis utilisateurs

### 2. Apprentissage web quotidien (automatique)

Une Edge Function `daily-learner` s'exécute chaque jour à 6h (via GitHub Actions) :

1. Sélectionne aléatoirement **2 flux RSS** parmi 8 sources artistiques
2. Parse les 3 derniers articles de chaque flux
3. Envoie le contenu à **Groq (Llama 3)** pour résumer en fiche de connaissance
4. Vérifie les doublons par titre
5. Insère les nouveaux articles dans `ai_knowledge_base` avec la source `web:rss:*`
6. Met à jour `ai_web_sources` (date dernier fetch, stats)

Sources RSS incluses : Colossal, Creative Boom, Booooooom, Lines and Colors, Open Culture Art, Poetry Magazine, Guitar World, ARTnews.

```bash
# Déployer la fonction
supabase functions deploy daily-learner --no-verify-jwt

# Définir le secret CRON (partagé avec GitHub Actions)
supabase secrets set CRON_SECRET=votre_secret_ici
```

### 3. Seed de connaissances (manuel)
```bash
# 1. Exécuter le schéma web sources
# Copier database/schema-web-sources.sql dans SQL Editor

# 2. Activer pgvector sur Supabase
CREATE EXTENSION IF NOT EXISTS vector;

# 3. Insérer les connaissances expertes
# Copier le contenu de seed-knowledge.ts dans les seeds
```

### 4. Amélioration continue

#### A. Apprentissage supervisé (via feedback)
```sql
-- Voir les réponses les mieux notées
SELECT q.question, a.answer, f.rating
FROM ai_training_data q
JOIN ai_feedback f ON f.conversation_id = (
    SELECT id FROM ai_conversations 
    WHERE user_message = q.question LIMIT 1
)
WHERE f.rating >= 4
ORDER BY f.rating DESC;
```

#### B. Fine-tuning du système prompt
```sql
-- Voir les prompts les plus performants
SELECT version, category, performance_score
FROM ai_system_prompts
WHERE is_active = true
ORDER BY performance_score DESC;
```

#### C. Détection des lacunes
```sql
-- Questions fréquentes sans bonne réponse
SELECT question, COUNT(*) as freq
FROM ai_training_data
WHERE quality_score < 3
GROUP BY question
HAVING COUNT(*) > 3
ORDER BY freq DESC;
```

### 5. Ajouter des connaissances

```sql
-- Insérer un nouvel article dans la base de connaissances
INSERT INTO ai_knowledge_base (category, title, content, tags)
VALUES (
    'visual',
    'Aquarelle : techniques de base',
    'Contenu détaillé ici...',
    ARRAY['aquarelle', 'technique', 'débutant']
);
```

### 6. Métriques de performance
```sql
-- Dashboard de performance
SELECT * FROM ai_daily_performance LIMIT 7;
```

## 🎯 Stratégies d'amélioration

### Phase 1 : Data Collection (immédiate)
- ✅ Sauvegarde automatique des conversations
- ✅ Feedback utilisateur
- ✅ Collecte des Q/R dans training_data

### Phase 2 : Apprentissage web automatique ✅
- [x] Edge Function `daily-learner` avec 8 flux RSS
- [x] Résumé via Groq (Llama 3) en fiches de connaissance
- [x] GitHub Actions cron quotidien (6h UTC)
- [x] Détection des doublons
- [x] Table `ai_web_sources` pour tracking

### Phase 3 : Knowledge Base (cette semaine)
- [x] Ajouter contenu expert (11 articles déjà présents)
- [ ] Ajouter tutoriels artistiques
- [ ] Ajouter FAQ Arteïa
- [ ] Ajouter techniques avancées

### Phase 4 : Fine-tuning (quand assez de données)
- [ ] ~1000+ paires Q/R de qualité (rating ≥ 4)
- [ ] Exporter au format JSONL pour OpenAI
- [ ] Fine-tuner un modèle custom
- [ ] Déployer le modèle fine-tuné

### Phase 5 : Auto-apprentissage avancé
- [ ] Système de recommandation de contenu
- [ ] Détection des tendances artistiques
- [ ] Suggestions proactives

## 📝 Format pour fine-tuning OpenAI

Quand tu auras assez de données, exporte-les avec :
```sql
SELECT 
    json_build_object(
        'messages', json_build_array(
            json_build_object('role', 'system', 'content', 'Tu es Arteïa Muse...'),
            json_build_object('role', 'user', 'content', question),
            json_build_object('role', 'assistant', 'content', answer)
        )
    )
FROM ai_training_data
WHERE is_approved = true AND quality_score >= 4;
```
Puis utilise `openai fine_tunes.create` sur le fichier JSONL.

## 🔧 Déploiement continu

```bash
# 1. Déployer la Edge Function
supabase functions deploy ai-assistant

# 2. Ajouter la clé OpenAI
supabase secrets set OPENAI_API_KEY=sk-...

# 3. Activer pgvector
# Dans Supabase Dashboard > Database > Extensions

# 4. Exécuter les migrations SQL
# Copier schema-ai-training.sql dans SQL Editor

## 🚀 Déploiement du daily-learner

```bash
# 1. Déployer la fonction
supabase functions deploy daily-learner --no-verify-jwt

# 2. Définir le CRON_SECRET (même valeur que dans GitHub Secrets)
supabase secrets set CRON_SECRET=mon-secret-super-secret

# 3. Ajouter GROQ_API_KEY si pas déjà fait
supabase secrets set GROQ_API_KEY=gsk_...

# 4. Exécuter le schéma des sources web
# Copier database/schema-web-sources.sql dans SQL Editor

# 5. Seed les sources RSS
# Copier la section "SOURCES WEB" de database/seed-all.sql dans SQL Editor

# 6. Configurer GitHub Secrets
# Dans Settings > Secrets and variables > Actions :
# - SUPABASE_EDGE_FUNCTIONS_URL: https://votre-projet.supabase.co/functions/v1
# - CRON_SECRET: mon-secret-super-secret
```