# 🧠 Guide d'entraînement d'Arteïa Muse

## Architecture d'amélioration continue

```
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

### 2. Seed de connaissances (manuel)
```bash
# 1. Activer pgvector sur Supabase
# Dans SQL Editor :
CREATE EXTENSION IF NOT EXISTS vector;

# 2. Insérer les connaissances expertes
# Copier le contenu de seed-knowledge.ts dans les seeds
```

### 3. Amélioration continue

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

### 4. Ajouter des connaissances

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

### 5. Métriques de performance
```sql
-- Dashboard de performance
SELECT * FROM ai_daily_performance LIMIT 7;
```

## 🎯 Stratégies d'amélioration

### Phase 1 : Data Collection (immédiate)
- ✅ Sauvegarde automatique des conversations
- ✅ Feedback utilisateur
- ✅ Collecte des Q/R dans training_data

### Phase 2 : Knowledge Base (cette semaine)
- [x] Ajouter contenu expert (11 articles déjà présents)
- [ ] Ajouter tutoriels artistiques
- [ ] Ajouter FAQ Arteïa
- [ ] Ajouter techniques avancées

### Phase 3 : Fine-tuning (quand assez de données)
- [ ] ~1000+ paires Q/R de qualité (rating ≥ 4)
- [ ] Exporter au format JSONL pour OpenAI
- [ ] Fine-tuner un modèle custom
- [ ] Déployer le modèle fine-tuné

### Phase 4 : Auto-apprentissage
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