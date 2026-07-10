import { useState, useEffect, useCallback, useMemo } from "react";
import {
  Search,
  GitBranch,
  Sparkles,
  Blend,
  Shuffle,
  Plus,
  Link2,
  Workflow,
  ChevronRight,
  Loader2,
  Layers,
  Tags,
  BookOpen,
  Lightbulb,
} from "lucide-react";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "../components/ui/tabs";
import { Card, CardContent, CardHeader, CardTitle } from "../components/ui/card";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "../components/ui/select";
import { Badge } from "../components/ui/badge";
import { OntologyGraph } from "../components/OntologyGraph";
import { Skeleton } from "../components/Skeleton";
import * as Ontology from "../services/ontology";
import type { OntologyConcept, OntologyRelation } from "../services/ontology";

type Props = {
  onNavigate?: (page: string) => void;
};

const CATEGORY_COLORS: Record<string, string> = {
  technique: "bg-violet-500/10 text-violet-600 border-violet-200 dark:border-violet-800",
  style: "bg-pink-500/10 text-pink-600 border-pink-200 dark:border-pink-800",
  mouvement: "bg-amber-500/10 text-amber-600 border-amber-200 dark:border-amber-800",
  medium: "bg-cyan-500/10 text-cyan-600 border-cyan-200 dark:border-cyan-800",
  outil: "bg-emerald-500/10 text-emerald-600 border-emerald-200 dark:border-emerald-800",
  theorie: "bg-indigo-500/10 text-indigo-600 border-indigo-200 dark:border-indigo-800",
  genre: "bg-orange-500/10 text-orange-600 border-orange-200 dark:border-orange-800",
  format: "bg-teal-500/10 text-teal-600 border-teal-200 dark:border-teal-800",
  artiste: "bg-red-500/10 text-red-600 border-red-200 dark:border-red-800",
  oeuvre: "bg-purple-500/10 text-purple-600 border-purple-200 dark:border-purple-800",
};

const CATEGORY_LABELS: Record<string, string> = {
  technique: "Technique", style: "Style", mouvement: "Mouvement",
  medium: "Medium", outil: "Outil", theorie: "Théorie",
  genre: "Genre", format: "Format", artiste: "Artiste", oeuvre: "Œuvre",
};

function ConceptCard({ concept, selected, onSelect }: {
  concept: OntologyConcept;
  selected: boolean;
  onSelect: (c: OntologyConcept) => void;
}) {
  const catColor = CATEGORY_COLORS[concept.category] ?? "bg-gray-500/10 text-gray-600";
  return (
    <button
      onClick={() => onSelect(concept)}
      className={`group relative overflow-hidden rounded-xl border p-4 text-left transition-all hover:scale-[1.02] hover:shadow-lg active:scale-[0.98] ${
        selected
          ? "border-violet-500/50 bg-violet-500/5 shadow-violet-500/20"
          : "border-border/30 bg-card/60"
      }`}
    >
      <div className="mb-2 flex items-start justify-between">
        <span className="text-2xl">{concept.icon}</span>
        <span className={`rounded-full border px-2 py-0.5 text-[10px] font-medium ${catColor}`}>
          {CATEGORY_LABELS[concept.category] ?? concept.category}
        </span>
      </div>
      <h3 className="mb-0.5 text-sm font-semibold text-foreground">{concept.label}</h3>
      {concept.description && (
        <p className="line-clamp-2 text-xs text-muted-foreground">{concept.description}</p>
      )}
      {concept.difficulty && (
        <span className="mt-2 inline-block text-[10px] uppercase tracking-wider text-muted-foreground">
          {concept.difficulty}
        </span>
      )}
    </button>
  );
}

function RelationChip({ label, type, weight }: { label: string; type: string; weight: number }) {
  return (
    <div className="flex items-center gap-2 rounded-lg border border-border/30 bg-card/40 px-3 py-2 text-sm">
      <Link2 className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
      <span className="font-medium text-foreground">{label}</span>
      <span className="text-xs text-muted-foreground">
        {Ontology.RELATION_LABELS[type] ?? type}
      </span>
      <span className="ml-auto text-[10px] text-muted-foreground">{(weight * 100).toFixed(0)}%</span>
    </div>
  );
}

export function OntologyPage({ onNavigate }: Props) {
  const [activeTab, setActiveTab] = useState("explorer");
  const [loading, setLoading] = useState(true);

  // ─── Explorer state ─────────────────────────────────────
  const [concepts, setConcepts] = useState<OntologyConcept[]>([]);
  const [selectedConcept, setSelectedConcept] = useState<OntologyConcept | null>(null);
  const [relations, setRelations] = useState<OntologyRelation[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("all");

  // ─── Assistant state ────────────────────────────────────
  const [synthesisSeeds, setSynthesisSeeds] = useState<string[]>([]);
  const [seedInput, setSeedInput] = useState("");
  const [synthesisResults, setSynthesisResults] = useState<Ontology.SynthesisResult[]>([]);
  const [synthesizing, setSynthesizing] = useState(false);

  const [blendA, setBlendA] = useState("");
  const [blendB, setBlendB] = useState("");
  const [blendResults, setBlendResults] = useState<Ontology.BlendResult[]>([]);
  const [blending, setBlending] = useState(false);

  const [pairsCategory, setPairsCategory] = useState<string>("all");
  const [pairsResults, setPairsResults] = useState<Ontology.CreativePair[]>([]);
  const [discovering, setDiscovering] = useState(false);

  // ─── Editor state ────────────────────────────────────────
  const [newConcept, setNewConcept] = useState({ slug: "", label: "", description: "", category: "technique", icon: "📚", difficulty: "" });
  const [newRelation, setNewRelation] = useState({ source_slug: "", target_slug: "", relation_type: "influence", weight: 1.0, description: "" });
  const [editorMessage, setEditorMessage] = useState("");
  const [editorLoading, setEditorLoading] = useState(false);

  // ─── Load concepts ───────────────────────────────────────
  const loadConcepts = useCallback(async () => {
    setLoading(true);
    try {
      const data = await Ontology.getConcepts({
        category: categoryFilter !== "all" ? categoryFilter : undefined,
        search: searchQuery || undefined,
      });
      setConcepts(data);
    } catch (err) {
      console.error("Failed to load concepts:", err);
    } finally {
      setLoading(false);
    }
  }, [categoryFilter, searchQuery]);

  useEffect(() => { loadConcepts(); }, [loadConcepts]);

  const handleSelectConcept = useCallback(async (concept: OntologyConcept) => {
    setSelectedConcept(concept);
    try {
      const rels = await Ontology.getRelationsForConcept(concept.slug);
      setRelations(rels);
    } catch (err) {
      console.error("Failed to load relations:", err);
      setRelations([]);
    }
  }, []);

  // ─── Assistant handlers ──────────────────────────────────
  const addSeed = useCallback(() => {
    const trimmed = seedInput.trim().toLowerCase();
    if (trimmed && !synthesisSeeds.includes(trimmed)) {
      setSynthesisSeeds((prev) => [...prev, trimmed]);
      setSeedInput("");
    }
  }, [seedInput, synthesisSeeds]);

  const removeSeed = useCallback((slug: string) => {
    setSynthesisSeeds((prev) => prev.filter((s) => s !== slug));
  }, []);

  const handleSynthesize = useCallback(async () => {
    if (synthesisSeeds.length === 0) return;
    setSynthesizing(true);
    try {
      const results = await Ontology.synthesizeStyle(synthesisSeeds);
      setSynthesisResults(results);
    } catch (err) {
      console.error("Synthesis failed:", err);
    } finally {
      setSynthesizing(false);
    }
  }, [synthesisSeeds]);

  const handleBlend = useCallback(async () => {
    if (!blendA || !blendB) return;
    setBlending(true);
    try {
      const results = await Ontology.blendStyles(blendA, blendB);
      setBlendResults(results);
    } catch (err) {
      console.error("Blend failed:", err);
    } finally {
      setBlending(false);
    }
  }, [blendA, blendB]);

  const handleDiscover = useCallback(async () => {
    setDiscovering(true);
    try {
      const results = await Ontology.discoverPairs(
        pairsCategory !== "all" ? pairsCategory : undefined,
      );
      setPairsResults(results);
    } catch (err) {
      console.error("Discovery failed:", err);
    } finally {
      setDiscovering(false);
    }
  }, [pairsCategory]);

  // ─── Editor handlers ─────────────────────────────────────
  const handleCreateConcept = useCallback(async () => {
    if (!newConcept.slug || !newConcept.label) return;
    setEditorLoading(true);
    setEditorMessage("");
    try {
      await Ontology.createConcept({
        slug: newConcept.slug,
        label: newConcept.label,
        description: newConcept.description || undefined,
        category: newConcept.category,
        icon: newConcept.icon,
        difficulty: newConcept.difficulty || undefined,
      });
      setEditorMessage("Concept créé !");
      setNewConcept({ slug: "", label: "", description: "", category: "technique", icon: "📚", difficulty: "" });
      loadConcepts();
    } catch (err) {
      setEditorMessage(err instanceof Error ? err.message : "Erreur");
    } finally {
      setEditorLoading(false);
    }
  }, [newConcept, loadConcepts]);

  const handleCreateRelation = useCallback(async () => {
    if (!newRelation.source_slug || !newRelation.target_slug) return;
    setEditorLoading(true);
    setEditorMessage("");
    try {
      await Ontology.createRelation({
        source_slug: newRelation.source_slug,
        target_slug: newRelation.target_slug,
        relation_type: newRelation.relation_type,
        weight: newRelation.weight,
        description: newRelation.description || undefined,
      });
      setEditorMessage("Relation créée !");
      setNewRelation({ source_slug: "", target_slug: "", relation_type: "influence", weight: 1.0, description: "" });
    } catch (err) {
      setEditorMessage(err instanceof Error ? err.message : "Erreur");
    } finally {
      setEditorLoading(false);
    }
  }, [newRelation]);

  // ─── Render ──────────────────────────────────────────────
  const selectedRelations = useMemo(() => {
    if (!selectedConcept) return [];
    return relations.filter(
      (r) => r.source_slug === selectedConcept.slug || r.target_slug === selectedConcept.slug,
    );
  }, [relations, selectedConcept]);

  return (
    <div className="mx-auto max-w-7xl px-4 py-8">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-fuchsia-500 shadow-lg">
            <Workflow className="h-5 w-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground">Ontologie Artistique</h1>
            <p className="text-sm text-muted-foreground">
              Explore, combine et enrichis la connaissance artistique
            </p>
          </div>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="mb-6">
          <TabsTrigger value="explorer">
            <Search className="h-4 w-4" />
            Explorateur
          </TabsTrigger>
          <TabsTrigger value="assistant">
            <Sparkles className="h-4 w-4" />
            Assistant créatif
          </TabsTrigger>
          <TabsTrigger value="editor">
            <Plus className="h-4 w-4" />
            Éditeur
          </TabsTrigger>
        </TabsList>

        {/* ════════════════ EXPLORER ════════════════ */}
        <TabsContent value="explorer" className="space-y-6">
          {/* Filters */}
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative flex-1 min-w-[200px]">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <input
                type="text"
                placeholder="Rechercher un concept..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full rounded-xl border border-border/50 bg-card/50 py-2.5 pl-10 pr-4 text-sm text-foreground outline-none transition-all focus:border-violet-500 focus:ring-1 focus:ring-violet-500/30"
              />
            </div>
            <Select value={categoryFilter} onValueChange={setCategoryFilter}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Catégorie" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Toutes</SelectItem>
                {Ontology.getConceptCategories().map((cat) => (
                  <SelectItem key={cat} value={cat}>
                    {CATEGORY_LABELS[cat] ?? cat}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {/* Graph */}
          {selectedConcept && (
            <div className="mb-2">
              <OntologyGraph
                concepts={concepts.slice(0, 30)}
                relations={relations}
                selectedSlug={selectedConcept.slug}
                onSelectConcept={handleSelectConcept}
              />
            </div>
          )}

          {/* Selected concept detail */}
          {selectedConcept && (
            <Card>
              <CardHeader>
                <div className="flex items-center gap-3">
                  <span className="text-3xl">{selectedConcept.icon}</span>
                  <div>
                    <CardTitle>{selectedConcept.label}</CardTitle>
                    <span className={`mt-1 inline-block rounded-full border px-2 py-0.5 text-[10px] font-medium ${
                      CATEGORY_COLORS[selectedConcept.category] ?? ""
                    }`}>
                      {CATEGORY_LABELS[selectedConcept.category] ?? selectedConcept.category}
                    </span>
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {selectedConcept.description && (
                  <p className="mb-4 text-sm text-muted-foreground">{selectedConcept.description}</p>
                )}
                {selectedConcept.difficulty && (
                  <Badge variant="outline" className="mr-1">{selectedConcept.difficulty}</Badge>
                )}
                {selectedConcept.metadata && Object.keys(selectedConcept.metadata).length > 0 && (
                  <pre className="mt-2 rounded-lg bg-muted/30 p-3 text-xs text-muted-foreground">
                    {JSON.stringify(selectedConcept.metadata, null, 2)}
                  </pre>
                )}

                {selectedRelations.length > 0 && (
                  <div className="mt-4">
                    <h4 className="mb-2 text-sm font-semibold text-foreground">
                      Relations ({selectedRelations.length})
                    </h4>
                    <div className="space-y-1.5">
                      {selectedRelations.map((r) => (
                        <RelationChip
                          key={r.id}
                          label={
                            r.source_slug === selectedConcept.slug
                              ? r.target_label ?? ""
                              : r.source_label ?? ""
                          }
                          type={r.relation_type}
                          weight={r.weight}
                        />
                      ))}
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          )}

          {/* Concept grid */}
          {loading ? (
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
              {Array.from({ length: 10 }).map((_, i) => (
                <Skeleton key={i} className="h-40 rounded-xl" />
              ))}
            </div>
          ) : concepts.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-12 text-center">
              <BookOpen className="h-12 w-12 text-muted-foreground/40" />
              <p className="text-sm text-muted-foreground">Aucun concept trouvé</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5">
              {concepts.map((concept) => (
                <ConceptCard
                  key={concept.id}
                  concept={concept}
                  selected={selectedConcept?.id === concept.id}
                  onSelect={handleSelectConcept}
                />
              ))}
            </div>
          )}
        </TabsContent>

        {/* ════════════════ ASSISTANT ════════════════ */}
        <TabsContent value="assistant" className="space-y-8">
          {/* 1. Synthesize */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <GitBranch className="h-5 w-5 text-violet-500" />
                <CardTitle>Synthèse de style</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Combine plusieurs concepts pour générer une nouvelle approche artistique.
              </p>
              <div className="flex flex-wrap items-center gap-2">
                <input
                  type="text"
                  value={seedInput}
                  onChange={(e) => setSeedInput(e.target.value)}
                  onKeyDown={(e) => { if (e.key === "Enter") addSeed(); }}
                  placeholder="Ajouter un concept (ex: hachure)..."
                  className="flex-1 min-w-[180px] rounded-xl border border-border/50 bg-card/50 px-4 py-2 text-sm text-foreground outline-none transition-all focus:border-violet-500"
                />
                <button
                  onClick={addSeed}
                  className="rounded-xl bg-violet-500/10 px-4 py-2 text-sm font-medium text-violet-600 transition-colors hover:bg-violet-500/20"
                >
                  Ajouter
                </button>
              </div>
              {synthesisSeeds.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {synthesisSeeds.map((seed) => (
                    <span
                      key={seed}
                      className="inline-flex items-center gap-1 rounded-full bg-violet-500/10 px-3 py-1 text-xs font-medium text-violet-600"
                    >
                      {seed}
                      <button onClick={() => removeSeed(seed)} className="hover:text-violet-800">&times;</button>
                    </span>
                  ))}
                </div>
              )}
              <button
                onClick={handleSynthesize}
                disabled={synthesisSeeds.length === 0 || synthesizing}
                className="flex items-center gap-2 rounded-full bg-gradient-to-r from-violet-600 to-fuchsia-600 px-6 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
              >
                {synthesizing ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
                {synthesizing ? "Synthèse en cours..." : "Synthétiser"}
              </button>
              {synthesisResults.length > 0 && (
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-foreground">Résultats ({synthesisResults.length})</h4>
                  {synthesisResults.map((r, i) => (
                    <div key={i} className="rounded-xl border border-border/30 bg-card/40 p-4">
                      <div className="mb-1 flex items-center gap-2">
                        <Badge>{r.concept_label}</Badge>
                        <span className="text-[10px] uppercase text-muted-foreground">{r.concept_category}</span>
                        <span className="ml-auto text-xs text-muted-foreground">
                          {(r.composite_weight * 100).toFixed(0)}%
                        </span>
                      </div>
                      <p className="text-xs text-muted-foreground">{r.relation_chain}</p>
                      <p className="mt-2 text-sm italic text-foreground/80">{r.synthesis_prompt}</p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* 2. Blend */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Blend className="h-5 w-5 text-pink-500" />
                <CardTitle>Fusion de concepts</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Trouve le chemin créatif entre deux concepts artistiques.
              </p>
              <div className="grid gap-3 sm:grid-cols-2">
                <input
                  type="text"
                  value={blendA}
                  onChange={(e) => setBlendA(e.target.value)}
                  placeholder="Premier concept (ex: aquarelle)..."
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-pink-500"
                />
                <input
                  type="text"
                  value={blendB}
                  onChange={(e) => setBlendB(e.target.value)}
                  placeholder="Second concept (ex: manga)..."
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-pink-500"
                />
              </div>
              <button
                onClick={handleBlend}
                disabled={!blendA || !blendB || blending}
                className="flex items-center gap-2 rounded-full bg-gradient-to-r from-pink-600 to-rose-600 px-6 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
              >
                {blending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Blend className="h-4 w-4" />}
                {blending ? "Fusion en cours..." : "Fusionner"}
              </button>
              {blendResults.length > 0 && (
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-foreground">Chemins de fusion</h4>
                  {blendResults.map((r, i) => (
                    <div key={i} className="rounded-xl border border-border/30 bg-card/40 p-4">
                      <div className="mb-2 flex items-center gap-2">
                        <Badge variant="secondary">{r.a_label}</Badge>
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                        <Badge variant="secondary">{r.b_label}</Badge>
                        <span className={`ml-auto rounded-full px-2 py-0.5 text-[10px] font-medium ${
                          r.difficulty === "debutant" ? "bg-green-500/10 text-green-600" :
                          r.difficulty === "intermediaire" ? "bg-amber-500/10 text-amber-600" :
                          "bg-red-500/10 text-red-600"
                        }`}>
                          {r.difficulty}
                        </span>
                      </div>
                      <div className="mb-2 flex flex-wrap gap-1">
                        {r.connection_path.map((step, j) => (
                          <span key={j} className="text-xs text-muted-foreground">
                            {j > 0 && <ChevronRight className="inline h-3 w-3" />}
                            {step}
                          </span>
                        ))}
                      </div>
                      <p className="text-sm text-foreground/80">{r.blend_description}</p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          {/* 3. Discover */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Shuffle className="h-5 w-5 text-amber-500" />
                <CardTitle>Découverte créative</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Découvre des paires de concepts inattendues pour stimuler ta créativité.
              </p>
              <div className="flex items-center gap-3">
                <Select value={pairsCategory} onValueChange={setPairsCategory}>
                  <SelectTrigger className="w-[200px]">
                    <SelectValue placeholder="Catégorie" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Toutes les catégories</SelectItem>
                    {Ontology.getConceptCategories().map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {CATEGORY_LABELS[cat] ?? cat}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <button
                  onClick={handleDiscover}
                  disabled={discovering}
                  className="flex items-center gap-2 rounded-full bg-gradient-to-r from-amber-600 to-orange-600 px-6 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
                >
                  {discovering ? <Loader2 className="h-4 w-4 animate-spin" /> : <Shuffle className="h-4 w-4" />}
                  {discovering ? "Recherche..." : "Découvrir"}
                </button>
              </div>
              {pairsResults.length > 0 && (
                <div className="grid gap-3 sm:grid-cols-2">
                  {pairsResults.map((p, i) => (
                    <div key={i} className="rounded-xl border border-border/30 bg-card/40 p-4">
                      <div className="mb-2 flex items-center gap-2">
                        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-amber-500/10 text-xs font-bold text-amber-600">
                          {p.surprise_score >= 0.8 ? "🔥" : "💡"}
                        </span>
                        <Badge variant="outline">{p.concept_a_label}</Badge>
                        <span className="text-xs text-muted-foreground">&</span>
                        <Badge variant="outline">{p.concept_b_label}</Badge>
                        <span className="ml-auto text-[10px] text-muted-foreground">
                          {(p.surprise_score * 100).toFixed(0)}%
                        </span>
                      </div>
                      <p className="text-sm italic text-foreground/80">{p.creative_hook}</p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* ════════════════ EDITOR ════════════════ */}
        <TabsContent value="editor" className="space-y-8">
          {/* Create concept */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Layers className="h-5 w-5 text-emerald-500" />
                <CardTitle>Nouveau concept</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                <input
                  type="text"
                  value={newConcept.slug}
                  onChange={(e) => setNewConcept((p) => ({ ...p, slug: e.target.value }))}
                  placeholder="Slug (ex: fusain)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-emerald-500"
                />
                <input
                  type="text"
                  value={newConcept.label}
                  onChange={(e) => setNewConcept((p) => ({ ...p, label: e.target.value }))}
                  placeholder="Label (ex: Fusain)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-emerald-500"
                />
              </div>
              <textarea
                value={newConcept.description}
                onChange={(e) => setNewConcept((p) => ({ ...p, description: e.target.value }))}
                placeholder="Description optionnelle..."
                rows={3}
                className="w-full rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-emerald-500"
              />
              <div className="grid gap-3 sm:grid-cols-3">
                <Select
                  value={newConcept.category}
                  onValueChange={(v) => setNewConcept((p) => ({ ...p, category: v }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Catégorie" />
                  </SelectTrigger>
                  <SelectContent>
                    {Ontology.getConceptCategories().map((cat) => (
                      <SelectItem key={cat} value={cat}>
                        {CATEGORY_LABELS[cat] ?? cat}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <input
                  type="text"
                  value={newConcept.icon}
                  onChange={(e) => setNewConcept((p) => ({ ...p, icon: e.target.value }))}
                  placeholder="Icone (emoji)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-emerald-500"
                />
                <Select
                  value={newConcept.difficulty}
                  onValueChange={(v) => setNewConcept((p) => ({ ...p, difficulty: v }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Difficulté" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="">—</SelectItem>
                    {Ontology.DIFFICULTY_LEVELS.map((d) => (
                      <SelectItem key={d} value={d}>
                        {d}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <button
                onClick={handleCreateConcept}
                disabled={!newConcept.slug || !newConcept.label || editorLoading}
                className="flex items-center gap-2 rounded-full bg-gradient-to-r from-emerald-600 to-teal-600 px-6 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
              >
                {editorLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Plus className="h-4 w-4" />}
                {editorLoading ? "Création..." : "Créer le concept"}
              </button>
            </CardContent>
          </Card>

          {/* Create relation */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Link2 className="h-5 w-5 text-blue-500" />
                <CardTitle>Nouvelle relation</CardTitle>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid gap-3 sm:grid-cols-2">
                <input
                  type="text"
                  value={newRelation.source_slug}
                  onChange={(e) => setNewRelation((p) => ({ ...p, source_slug: e.target.value }))}
                  placeholder="Concept source (slug)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-blue-500"
                />
                <input
                  type="text"
                  value={newRelation.target_slug}
                  onChange={(e) => setNewRelation((p) => ({ ...p, target_slug: e.target.value }))}
                  placeholder="Concept cible (slug)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-blue-500"
                />
              </div>
              <div className="grid gap-3 sm:grid-cols-3">
                <Select
                  value={newRelation.relation_type}
                  onValueChange={(v) => setNewRelation((p) => ({ ...p, relation_type: v }))}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Type de relation" />
                  </SelectTrigger>
                  <SelectContent>
                    {Ontology.RELATION_TYPES.map((rt) => (
                      <SelectItem key={rt} value={rt}>
                        {Ontology.RELATION_LABELS[rt] ?? rt}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <input
                  type="number"
                  min={0}
                  max={1}
                  step={0.05}
                  value={newRelation.weight}
                  onChange={(e) => setNewRelation((p) => ({ ...p, weight: parseFloat(e.target.value) || 0 }))}
                  placeholder="Poids (0-1)"
                  className="rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-blue-500"
                />
              </div>
              <input
                type="text"
                value={newRelation.description}
                onChange={(e) => setNewRelation((p) => ({ ...p, description: e.target.value }))}
                placeholder="Description optionnelle..."
                className="w-full rounded-xl border border-border/50 bg-card/50 px-4 py-2.5 text-sm text-foreground outline-none transition-all focus:border-blue-500"
              />
              <button
                onClick={handleCreateRelation}
                disabled={!newRelation.source_slug || !newRelation.target_slug || editorLoading}
                className="flex items-center gap-2 rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 px-6 py-2.5 text-sm font-medium text-white shadow-lg transition-all hover:scale-105 hover:shadow-xl disabled:opacity-50 disabled:hover:scale-100"
              >
                {editorLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Link2 className="h-4 w-4" />}
                {editorLoading ? "Création..." : "Créer la relation"}
              </button>
              {editorMessage && (
                <p className={`text-sm ${editorMessage === "Concept créé !" || editorMessage === "Relation créée !" ? "text-emerald-600" : "text-red-500"}`}>
                  {editorMessage}
                </p>
              )}
            </CardContent>
          </Card>

          {/* Categories reference */}
          <Card>
            <CardHeader>
              <div className="flex items-center gap-2">
                <Tags className="h-5 w-5 text-muted-foreground" />
                <CardTitle>Catégories disponibles</CardTitle>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                {Ontology.getConceptCategories().map((cat) => (
                  <div key={cat} className="flex items-center gap-2 rounded-lg border border-border/30 bg-card/40 px-3 py-2 text-sm">
                    <span className={`h-2.5 w-2.5 rounded-full ${
                      cat === "technique" ? "bg-violet-500" :
                      cat === "style" ? "bg-pink-500" :
                      cat === "mouvement" ? "bg-amber-500" :
                      cat === "medium" ? "bg-cyan-500" :
                      cat === "outil" ? "bg-emerald-500" :
                      cat === "theorie" ? "bg-indigo-500" :
                      cat === "genre" ? "bg-orange-500" :
                      cat === "format" ? "bg-teal-500" :
                      cat === "artiste" ? "bg-red-500" : "bg-purple-500"
                    }`} />
                    <span className="text-foreground">{CATEGORY_LABELS[cat] ?? cat}</span>
                    <code className="ml-auto text-[10px] text-muted-foreground">{cat}</code>
                  </div>
                ))}
              </div>
              <div className="mt-4">
                <h4 className="mb-2 text-sm font-semibold text-foreground">Types de relations</h4>
                <div className="grid gap-1.5 sm:grid-cols-2">
                  {Ontology.RELATION_TYPES.map((rt) => (
                    <div key={rt} className="flex items-center gap-2 rounded-lg border border-border/30 bg-card/40 px-3 py-1.5 text-xs">
                      <code className="text-muted-foreground">{rt}</code>
                      <span className="text-muted-foreground">→</span>
                      <span className="text-foreground">{Ontology.RELATION_LABELS[rt]}</span>
                    </div>
                  ))}
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
