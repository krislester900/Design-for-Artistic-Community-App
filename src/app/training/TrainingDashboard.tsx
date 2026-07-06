import { useState, useEffect } from "react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);

type TrainingJob = {
  id: number;
  style_id: number;
  status: string;
  instance_prompt: string;
  reference_count: number;
  progress: number;
  error_message: string | null;
  lora_url: string | null;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
};

type MangaStyle = {
  id: number;
  name: string;
  slug: string;
  mangaka: string;
  training_status: string;
  reference_count: number;
  lora_url: string | null;
  model_version: string | null;
};

type KnowledgeStat = {
  total: number;
  by_category: Record<string, number>;
};

type TrainingDataStat = {
  total_pairs: number;
  approved: number;
  avg_quality: number;
};

export function TrainingDashboard() {
  const [tab, setTab] = useState<"manga" | "knowledge" | "assistant">("manga");
  const [jobs, setJobs] = useState<TrainingJob[]>([]);
  const [styles, setStyles] = useState<MangaStyle[]>([]);
  const [knowledgeStats, setKnowledgeStats] = useState<KnowledgeStat | null>(null);
  const [trainingStats, setTrainingStats] = useState<TrainingDataStat | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 30000);
    return () => clearInterval(interval);
  }, []);

  async function loadData() {
    try {
      const [jobsRes, stylesRes, knowledgeRes, trainingRes] = await Promise.allSettled([
        supabase.from("ai_training_jobs").select("*").order("created_at", { ascending: false }).limit(20),
        supabase.from("ai_manga_styles").select("*").order("name"),
        supabase.from("ai_knowledge_base").select("category"),
        supabase.from("ai_training_data").select("id, quality_score, is_approved"),
      ]);

      if (jobsRes.status === "fulfilled") setJobs(jobsRes.value.data ?? []);
      if (stylesRes.status === "fulfilled") setStyles(stylesRes.value.data ?? []);

      if (knowledgeRes.status === "fulfilled" && knowledgeRes.value.data) {
        const cats: Record<string, number> = {};
        for (const row of knowledgeRes.value.data) {
          cats[row.category] = (cats[row.category] ?? 0) + 1;
        }
        setKnowledgeStats({ total: knowledgeRes.value.data.length, by_category: cats });
      }

      if (trainingRes.status === "fulfilled" && trainingRes.value.data) {
        const d = trainingRes.value.data;
        setTrainingStats({
          total_pairs: d.length,
          approved: d.filter((r) => r.is_approved).length,
          avg_quality: d.length > 0 ? d.reduce((s, r) => s + (r.quality_score ?? 0), 0) / d.length : 0,
        });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur inconnue");
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary/30 border-t-primary" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <p className="text-red-500 font-bold">Erreur de chargement</p>
          <p className="text-sm text-muted-foreground mt-2">{error}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="sticky top-0 z-10 bg-card/80 backdrop-blur-xl border-b border-border/30 px-6 py-4">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Arteïa Muse — Entraînement IA</h1>
            <p className="text-sm text-muted-foreground">Surveille l'évolution de l'IA en temps réel</p>
          </div>
          <button onClick={loadData} className="px-4 py-2 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90">
            Actualiser
          </button>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-6 py-6">
        <div className="flex gap-2 mb-6">
          {(["manga", "knowledge", "assistant"] as const).map((t) => (
            <button
              key={t}
              onClick={() => setTab(t)}
              className={`px-4 py-2 rounded-xl text-sm font-medium transition-all ${
                tab === t ? "bg-primary text-primary-foreground" : "bg-card/50 text-muted-foreground hover:bg-card/80"
              }`}
            >
              {{ manga: "Manga LoRA", knowledge: "Base de connaissances", assistant: "Assistant Fine-Tuning" }[t]}
            </button>
          ))}
        </div>

        {tab === "manga" && <MangaTrainingPanel styles={styles} jobs={jobs} />}
        {tab === "knowledge" && <KnowledgePanel stats={knowledgeStats} />}
        {tab === "assistant" && <AssistantPanel stats={trainingStats} />}
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pending: "bg-yellow-500/20 text-yellow-600",
    preparing: "bg-blue-500/20 text-blue-600",
    training: "bg-purple-500/20 text-purple-600 animate-pulse",
    completed: "bg-emerald-500/20 text-emerald-600",
    failed: "bg-red-500/20 text-red-600",
    collecting: "bg-gray-500/20 text-gray-600",
    ready: "bg-emerald-500/20 text-emerald-600",
  };
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${colors[status] ?? "bg-gray-500/20 text-gray-600"}`}>
      {status}
    </span>
  );
}

function MangaTrainingPanel({ styles, jobs }: { styles: MangaStyle[]; jobs: TrainingJob[] }) {
  const readyToTrain = styles.filter((s) => s.reference_count >= 5 && s.training_status !== "training" && s.training_status !== "ready");

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatCard label="Styles manga" value={styles.length} />
        <StatCard label="Prêts à entraîner" value={readyToTrain.length} color="emerald" />
        <StatCard label="En entraînement" value={jobs.filter((j) => j.status === "training").length} color="purple" />
        <StatCard label="Terminés" value={jobs.filter((j) => j.status === "completed").length} color="emerald" />
      </div>

      {readyToTrain.length > 0 && (
        <div className="rounded-2xl bg-amber-500/10 border border-amber-500/20 p-4">
          <p className="text-sm font-medium text-amber-700">
            {readyToTrain.length} style{readyToTrain.length > 1 ? "s" : ""} prêt{readyToTrain.length > 1 ? "s" : ""} à entraîner.
            Va sur GitHub → Actions → AI Training et lance avec style_slug.
          </p>
          <div className="flex flex-wrap gap-2 mt-2">
            {readyToTrain.map((s) => (
              <code key={s.id} className="px-2 py-1 rounded-lg bg-amber-500/10 text-xs font-mono">
                {s.slug} ({s.reference_count} refs)
              </code>
            ))}
          </div>
        </div>
      )}

      <div>
        <h3 className="text-lg font-semibold mb-3">Derniers jobs d'entraînement</h3>
        {jobs.length === 0 ? (
          <p className="text-sm text-muted-foreground">Aucun job pour l'instant.</p>
        ) : (
          <div className="space-y-2">
            {jobs.map((job) => (
              <div key={job.id} className="flex items-center justify-between p-3 rounded-xl bg-card/50 border border-border/30">
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="font-medium text-sm">{job.instance_prompt}</span>
                    <StatusBadge status={job.status} />
                  </div>
                  <p className="text-xs text-muted-foreground mt-1">
                    {job.reference_count} images · {new Date(job.created_at).toLocaleString("fr-FR")}
                    {job.progress > 0 && ` · ${Math.round(job.progress * 100)}%`}
                  </p>
                  {job.error_message && (
                    <p className="text-xs text-red-500 mt-1">{job.error_message}</p>
                  )}
                </div>
                {job.status === "training" && (
                  <div className="w-24 h-2 rounded-full bg-muted overflow-hidden">
                    <div className="h-full bg-primary rounded-full transition-all" style={{ width: `${job.progress * 100}%` }} />
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      <div>
        <h3 className="text-lg font-semibold mb-3">Tous les styles manga</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          {styles.map((style) => (
            <div key={style.id} className="p-3 rounded-xl bg-card/50 border border-border/30">
              <div className="flex items-center justify-between mb-1">
                <span className="font-medium text-sm">{style.name}</span>
                <StatusBadge status={style.training_status} />
              </div>
              <p className="text-xs text-muted-foreground">{style.mangaka}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {style.reference_count ?? 0} références
                {style.lora_url && " · LoRA prêt"}
              </p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function KnowledgePanel({ stats }: { stats: KnowledgeStat | null }) {
  if (!stats) {
    return <p className="text-sm text-muted-foreground">Aucune donnée.</p>;
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard label="Articles de connaissance" value={stats.total} />
        {Object.entries(stats.by_category).map(([cat, count]) => (
          <StatCard key={cat} label={cat} value={count} />
        ))}
      </div>

      <div className="rounded-2xl bg-card/50 border border-border/30 p-6">
        <h3 className="text-lg font-semibold mb-2">Apprentissage web quotidien</h3>
        <p className="text-sm text-muted-foreground">
          Le <strong>Daily Learner</strong> scrape 2 flux RSS aléatoires chaque jour à 6h UTC via GitHub Actions.
          Les articles sont résumés par Llama 3 (Groq) et ajoutés à la base de connaissances pour le RAG.
        </p>
        <p className="text-sm text-muted-foreground mt-2">
          Va sur GitHub → Actions → AI Training → <code>daily-learner</code> pour déclencher manuellement.
        </p>
      </div>
    </div>
  );
}

function AssistantPanel({ stats }: { stats: TrainingDataStat | null }) {
  const threshold = 1000;
  const remaining = stats ? Math.max(0, threshold - stats.total_pairs) : threshold;

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <StatCard label="Paires Q/R collectées" value={stats?.total_pairs ?? 0} />
        <StatCard label="Approuvées" value={stats?.approved ?? 0} />
        <StatCard label="Qualité moyenne" value={stats ? `${stats.avg_quality.toFixed(1)}/5` : "—"} />
      </div>

      <div className="rounded-2xl bg-card/50 border border-border/30 p-6">
        <h3 className="text-lg font-semibold mb-2">Fine-tuning du LLM</h3>
        {stats && stats.total_pairs >= threshold ? (
          <div className="flex items-center gap-2 text-emerald-600">
            <span className="h-2 w-2 rounded-full bg-emerald-500" />
            <span className="font-medium">Assez de données ! Prêt pour le fine-tuning.</span>
          </div>
        ) : (
          <div>
            <p className="text-sm text-muted-foreground">
              {remaining} paires Q/R supplémentaires nécessaires ({stats?.total_pairs ?? 0}/{threshold}) pour lancer le fine-tuning.
            </p>
            <div className="mt-2 h-3 rounded-full bg-muted overflow-hidden">
              <div
                className="h-full bg-primary rounded-full transition-all"
                style={{ width: `${Math.min(100, ((stats?.total_pairs ?? 0) / threshold) * 100)}%` }}
              />
            </div>
          </div>
        )}
        <p className="text-sm text-muted-foreground mt-3">
          Les conversations avec l'assistant sont automatiquement sauvegardées dans <code>ai_training_data</code>.
          Quand le seuil sera atteint, va sur GitHub → Actions → AI Training → <code>assistant-export</code>.
        </p>
      </div>

      <div className="rounded-2xl bg-card/50 border border-border/30 p-6">
        <h3 className="text-lg font-semibold mb-2">Prochaine étape</h3>
        <ol className="text-sm text-muted-foreground space-y-1 list-decimal list-inside">
          <li>Atteindre {threshold} paires Q/R de qualité (rating ≥ 4)</li>
          <li>Exporter en JSONL via le workflow GitHub</li>
          <li>Lancer <code>openai fine_tunes.create</code> ou <code>replicate fine-tunes</code></li>
          <li>Déployer le modèle fine-tuné dans l'Edge Function</li>
        </ol>
      </div>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: string | number; color?: string }) {
  const colors: Record<string, string> = {
    emerald: "bg-emerald-500/10 border-emerald-500/20 text-emerald-600",
    purple: "bg-purple-500/10 border-purple-500/20 text-purple-600",
  };
  const colorClass = color ? colors[color] ?? "" : "";
  return (
    <div className={`p-4 rounded-xl bg-card/50 border border-border/30 ${colorClass}`}>
      <p className="text-2xl font-bold">{value}</p>
      <p className="text-xs text-muted-foreground mt-1">{label}</p>
    </div>
  );
}
