# 🗄️ Configuration SQL de la base de données Arteïa

## Ordre d'exécution DANS Supabase SQL Editor

Exécuter les fichiers **DANS CET ORDRE** :

### 1️⃣ Créer les tables de l'assistant IA
📄 **`database/schema-ai-assistant.sql`**
→ Crée `ai_conversations` avec RLS

### 2️⃣ Créer les tables d'entraînement
📄 **`database/schema-ai-training.sql`**
→ Crée `ai_knowledge_base`, `ai_training_data`, `ai_feedback`, `ai_performance_metrics`, `ai_system_prompts`

### 3️⃣ Créer l'ontologie artistique
📄 **`database/schema-ontology.sql`**
→ Crée `ontology_concepts`, `ontology_relations`, `ontology_taxonomy`

### 4️⃣ Créer les tables likes/commentaires (optionnel)
📄 **`database/schema-likes-comments.sql`**
→ Crée `post_likes`, `post_comments`, fonctions RPC

### 5️⃣ Remplir les données (seeder)
📄 **`database/seed-all.sql`**
→ Insère :
   - 11 articles de connaissances
   - 20 catégories taxonomiques
   - 21 concepts ontologiques
   - Les relations entre concepts
   - Les prompts système versionnés

---

## 🔗 Liens vers les fichiers sur GitHub

| Fichier | Lien |
|---------|------|
| Schéma IA assistant | [schema-ai-assistant.sql](https://github.com/krislester900/Design-for-Artistic-Community-App/blob/main/database/schema-ai-assistant.sql) |
| Schéma entraînement | [schema-ai-training.sql](https://github.com/krislester900/Design-for-Artistic-Community-App/blob/main/database/schema-ai-training.sql) |
| Schéma ontologie | [schema-ontology.sql](https://github.com/krislester900/Design-for-Artistic-Community-App/blob/main/database/schema-ontology.sql) |
| Schéma likes/comments | [schema-likes-comments.sql](https://github.com/krislester900/Design-for-Artistic-Community-App/blob/main/database/schema-likes-comments.sql) |
| **Seed complet (données)** | [seed-all.sql](https://github.com/krislester900/Design-for-Artistic-Community-App/blob/main/database/seed-all.sql) |

---

## ⚡ Exécution rapide (copier-coller)

```sql
-- 1. Créer les tables
```

Puis copier le contenu de chaque fichier dans l'ordre dans Supabase SQL Editor.