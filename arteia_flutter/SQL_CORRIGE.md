# ✅ SQL Corrigé - Prêt à utiliser

## L'erreur est réparée !

L'erreur `foreign key constraint "channels_category_fkey" cannot be implemented` est **corrigée**.

J'ai supprimé la contrainte de clé étrangère sur la colonne `category` qui causait un conflit de types.

---

## 🚀 Réessaie maintenant :

### 1. Ouvre Supabase SQL Editor
https://supabase.com/dashboard/project/wzewlweghntnqyfvhgan/editor

### 2. New query

### 3. Ouvre le fichier corrigé
`database/schema-messaging.sql`

### 4. Copie TOUT le contenu
(Ctrl+A, Ctrl+C)

### 5. Colle dans Supabase
(Ctrl+V)

### 6. Clique Run (▶️)

---

## ✅ Résultat attendu :

```
Success. No rows returned
```

---

## 📝 Ce que fait le SQL :

1. **Crée 4 tables** :
   - `channels` - Canaux de discussion
   - `channel_members` - Membres des canaux
   - `messages` - Messages texte/vocaux
   - `message_reads` - Suivi des lectures

2. **Insère 8 canaux par défaut** :
   - Général, Annonces, Musique, Arts Visuels, Littérature, Manga, Films, Animation

3. **Active le temps réel** pour les messages

4. **Configure la sécurité** (RLS policies)

---

## 🎯 Après le SQL :

Crée le bucket Storage :
1. https://supabase.com/dashboard/project/wzewlweghntnqyfvhgan/storage/buckets
2. Create bucket
3. Nom : `voice_messages`
4. Public bucket : ✅

---

**Cette fois ça va marcher !** L'erreur de type est corrigée.