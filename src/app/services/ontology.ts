import { supabase } from "../lib/supabase";

export interface OntologyConcept {
  id: number;
  slug: string;
  label: string;
  description: string | null;
  category: string;
  icon: string;
  difficulty: string | null;
  metadata: Record<string, unknown>;
  created_at: string;
}

export interface OntologyRelation {
  id: number;
  source_id: number;
  target_id: number;
  relation_type: string;
  weight: number;
  description: string | null;
  created_at: string;
  source_label?: string;
  source_slug?: string;
  source_category?: string;
  target_label?: string;
  target_slug?: string;
  target_category?: string;
}

export interface SynthesisResult {
  concept_slug: string;
  concept_label: string;
  concept_category: string;
  path: string[];
  relation_chain: string;
  composite_weight: number;
  synthesis_prompt: string;
}

export interface BlendResult {
  a_label: string;
  b_label: string;
  a_category: string;
  b_category: string;
  connection_path: string[];
  relation_types: string[];
  blend_description: string;
  difficulty: string;
}

export interface CreativePair {
  concept_a_slug: string;
  concept_a_label: string;
  concept_a_category: string;
  concept_b_slug: string;
  concept_b_label: string;
  concept_b_category: string;
  surprise_score: number;
  creative_hook: string;
}

export interface TaxonomyNode {
  id: number;
  parent_id: number | null;
  slug: string;
  label: string;
  level: number;
  path: string[];
  order_index: number;
}

const CATEGORIES = [
  "technique", "style", "mouvement", "medium",
  "outil", "theorie", "genre", "format", "artiste", "oeuvre",
] as const;

export function getConceptCategories() {
  return CATEGORIES;
}

export const RELATION_TYPES = [
  "est_un", "influence", "utilise", "requiert",
  "appartient_a", "contient", "complimente", "precede",
  "derive_de", "s_applique_a", "similaire_a", "contredit", "exemple",
] as const;

export const RELATION_LABELS: Record<string, string> = {
  est_un: "Est un",
  influence: "Influence",
  utilise: "Utilise",
  requiert: "Requiert",
  appartient_a: "Appartient à",
  contient: "Contient",
  complimente: "Complimente",
  precede: "Précède",
  derive_de: "Dérive de",
  s_applique_a: "S'applique à",
  similaire_a: "Similaire à",
  contredit: "Contredit",
  exemple: "Exemple",
};

export const DIFFICULTY_LEVELS = ["debutant", "intermediaire", "avance", "expert"] as const;

export async function getConcepts(options?: {
  category?: string;
  search?: string;
  limit?: number;
}): Promise<OntologyConcept[]> {
  if (!supabase) return [];
  let query = supabase
    .from("ontology_concepts")
    .select("*")
    .order("label");

  if (options?.category) {
    query = query.eq("category", options.category);
  }
  if (options?.search) {
    query = query.ilike("label", `%${options.search}%`);
  }
  if (options?.limit) {
    query = query.limit(options.limit);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data ?? [];
}

export async function getConceptBySlug(slug: string): Promise<OntologyConcept | null> {
  if (!supabase) return null;
  const { data, error } = await supabase
    .from("ontology_concepts")
    .select("*")
    .eq("slug", slug)
    .single();
  if (error) throw error;
  return data;
}

export async function getRelationsForConcept(conceptSlug: string): Promise<OntologyRelation[]> {
  if (!supabase) return [];
  const concept = await getConceptBySlug(conceptSlug);
  if (!concept) return [];
  const { data, error } = await supabase
    .from("ontology_relations_extended")
    .select("*")
    .or(`source_slug.eq.${conceptSlug},target_slug.eq.${conceptSlug}`);
  if (error) throw error;
  return data ?? [];
}

export async function getTaxonomy(): Promise<TaxonomyNode[]> {
  if (!supabase) return [];
  const { data, error } = await supabase
    .from("ontology_tree")
    .select("*")
    .order("path");
  if (error) throw error;
  return data ?? [];
}

export async function synthesizeStyle(
  seedConcepts: string[],
  maxDepth = 3,
  maxResults = 10,
): Promise<SynthesisResult[]> {
  if (!supabase) return [];
  const { data, error } = await supabase.rpc("synthesize_style", {
    seed_concepts: seedConcepts,
    max_depth: maxDepth,
    max_results: maxResults,
  });
  if (error) throw error;
  return data ?? [];
}

export async function blendStyles(
  conceptA: string,
  conceptB: string,
): Promise<BlendResult[]> {
  if (!supabase) return [];
  const { data, error } = await supabase.rpc("blend_styles", {
    concept_a: conceptA,
    concept_b: conceptB,
  });
  if (error) throw error;
  return data ?? [];
}

export async function discoverPairs(
  categoryFilter?: string,
  maxPairs = 8,
): Promise<CreativePair[]> {
  if (!supabase) return [];
  const { data, error } = await supabase.rpc("discover_creative_pairs", {
    category_filter: categoryFilter ?? null,
    max_pairs: maxPairs,
  });
  if (error) throw error;
  return data ?? [];
}

export async function createConcept(data: {
  slug: string;
  label: string;
  description?: string;
  category: string;
  icon?: string;
  difficulty?: string;
}): Promise<OntologyConcept> {
  if (!supabase) throw new Error("Supabase not configured");
  const { data: result, error } = await supabase
    .from("ontology_concepts")
    .insert({
      slug: data.slug,
      label: data.label,
      description: data.description ?? null,
      category: data.category,
      icon: data.icon ?? "📚",
      difficulty: data.difficulty ?? null,
    })
    .select()
    .single();
  if (error) throw error;
  return result;
}

export async function createRelation(data: {
  source_slug: string;
  target_slug: string;
  relation_type: string;
  weight?: number;
  description?: string;
}): Promise<OntologyRelation> {
  if (!supabase) throw new Error("Supabase not configured");
  const source = await getConceptBySlug(data.source_slug);
  const target = await getConceptBySlug(data.target_slug);
  if (!source || !target) throw new Error("Concept not found");
  const { data: result, error } = await supabase
    .from("ontology_relations")
    .insert({
      source_id: source.id,
      target_id: target.id,
      relation_type: data.relation_type,
      weight: data.weight ?? 1.0,
      description: data.description ?? null,
    })
    .select()
    .single();
  if (error) throw error;
  return result;
}
