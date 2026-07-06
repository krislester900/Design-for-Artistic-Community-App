import { useState, useRef, useEffect } from "react";
import { Upload, Check, Image, Music, Pen } from "lucide-react";
import { categories, type CategorySlug } from "../data/community";
import { submitArtwork, submitArtistProfile, submitDiscussion, saveUserProfile, getProfile, type SubmissionItem } from "./ProfileUploadService";
import { ImageUploader } from "../components/ImageUploader";

type UploadTab = "artwork" | "artist" | "discussion";

type FormState = {
  email: string;
  displayName: string;
  bio: string;
  univers: string[];
};

export function ArtworkUploadForm() {
  const [activeTab, setActiveTab] = useState<UploadTab>("artwork");
  const [profile, setProfile] = useState<FormState>(() => {
    const existing = getProfile();
    return {
      email: existing?.email || "",
      displayName: existing?.displayName || "",
      bio: existing?.bio || "",
      univers: existing?.univers || [],
    };
  });
  const [message, setMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const [artworkTitle, setArtworkTitle] = useState("");
  const [artworkCategory, setArtworkCategory] = useState<string>("music");
  const [artworkMedium, setArtworkMedium] = useState("");
  const [artworkImage, setArtworkImage] = useState("");

  const [artistName, setArtistName] = useState("");
  const [artistRole, setArtistRole] = useState("");
  const [artistCategory, setArtistCategory] = useState<string>("music");
  const [artistImage, setArtistImage] = useState("");
  const [artistWork, setArtistWork] = useState("");

  const [discussionTitle, setDiscussionTitle] = useState("");
  const [discussionAuthor, setDiscussionAuthor] = useState("");
  const [discussionCategory, setDiscussionCategory] = useState<string>("music");
  const [discussionTime, setDiscussionTime] = useState("Aujourd'hui");

  const messageTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    return () => {
      if (messageTimerRef.current) clearTimeout(messageTimerRef.current);
    };
  }, []);

  function showMessage(type: "success" | "error", text: string) {
    if (messageTimerRef.current) clearTimeout(messageTimerRef.current);
    setMessage({ type, text });
    messageTimerRef.current = setTimeout(() => setMessage(null), 4000);
  }

  function handleProfileSave() {
    if (!profile.email.trim()) {
      showMessage("error", "Email requis pour soumettre du contenu.");
      return;
    }
    saveUserProfile(profile);
    showMessage("success", "Profil enregistré !");
  }

  function handleArtworkSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!profile.email.trim() || !artworkTitle.trim()) {
      showMessage("error", "Email et titre requis.");
      return;
    }
    setSubmitting(true);
    try {
      submitArtwork(
        {
          title: artworkTitle.trim(),
          artist: profile.displayName || "Anonyme",
          category: artworkCategory,
          medium: artworkMedium.trim() || "Numérique",
          image: artworkImage.trim() || "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800",
          height: "aspect-square",
        },
        profile.email,
      );
      showMessage("success", "Œuvre soumise ! En attente de validation par l'admin.");
      setArtworkTitle("");
      setArtworkMedium("");
      setArtworkImage("");
    } catch {
      showMessage("error", "Erreur lors de la soumission.");
    } finally {
      setSubmitting(false);
    }
  }

  function handleArtistSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!profile.email.trim() || !artistName.trim()) {
      showMessage("error", "Email et nom requis.");
      return;
    }
    setSubmitting(true);
    try {
      submitArtistProfile(
        {
          name: artistName.trim(),
          category: artistCategory,
          role: artistRole.trim() || "Artiste",
          image: artistImage.trim() || "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800",
          featuredWork: artistWork.trim() || "Œuvre à venir",
        },
        profile.email,
      );
      showMessage("success", "Profil artiste soumis ! En attente de validation.");
      setArtistName("");
      setArtistRole("");
      setArtistImage("");
      setArtistWork("");
    } catch {
      showMessage("error", "Erreur lors de la soumission.");
    } finally {
      setSubmitting(false);
    }
  }

  function handleDiscussionSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!profile.email.trim() || !discussionTitle.trim()) {
      showMessage("error", "Email et titre requis.");
      return;
    }
    setSubmitting(true);
    try {
      submitDiscussion(
        {
          title: discussionTitle.trim(),
          author: discussionAuthor.trim() || profile.displayName || "Anonyme",
          category: discussionCategory,
          time: discussionTime.trim(),
          trending: false,
        },
        profile.email,
      );
      showMessage("success", "Discussion soumise ! En attente de validation.");
      setDiscussionTitle("");
      setDiscussionAuthor("");
    } catch {
      showMessage("error", "Erreur lors de la soumission.");
    } finally {
      setSubmitting(false);
    }
  }

  const tabs: { id: UploadTab; label: string; icon: React.ReactNode }[] = [
    { id: "artwork", label: "Œuvre", icon: <Image className="h-4 w-4" /> },
    { id: "artist", label: "Artiste", icon: <Music className="h-4 w-4" /> },
    { id: "discussion", label: "Discussion", icon: <Pen className="h-4 w-4" /> },
  ];

  return (
    <div className="space-y-6">
      {message && (
        <div
          className={`rounded-xl border px-5 py-4 text-sm backdrop-blur ${
            message.type === "success"
              ? "border-primary/30 bg-primary/10 text-primary"
              : "border-red-500/30 bg-red-500/10 text-red-300"
          }`}
        >
          {message.text}
        </div>
      )}

      <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
        <h3 className="mb-4 text-lg font-semibold text-foreground">
          Ton profil créateur
        </h3>
        <div className="grid gap-4 md:grid-cols-2">
          <input
            className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary"
            placeholder="Email *"
            type="email"
            value={profile.email}
            onChange={(e) => setProfile({ ...profile, email: e.target.value })}
            required
          />
          <input
            className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary"
            placeholder="Nom d'artiste"
            value={profile.displayName}
            onChange={(e) => setProfile({ ...profile, displayName: e.target.value })}
          />
          <input
            className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none transition-colors placeholder:text-muted-foreground/50 focus:border-primary md:col-span-2"
            placeholder="Bio — Parle de toi et de ton univers créatif"
            value={profile.bio}
            onChange={(e) => setProfile({ ...profile, bio: e.target.value })}
          />
        </div>
        <button
          onClick={handleProfileSave}
          className="mt-4 inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
        >
          <Check className="h-4 w-4" />
          Enregistrer le profil
        </button>
      </div>

      <div className="flex gap-2">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`inline-flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-medium transition-colors ${
              activeTab === tab.id
                ? "border-primary bg-primary/10 text-primary"
                : "border-border text-muted-foreground hover:text-foreground"
            }`}
          >
            {tab.icon}
            {tab.label}
          </button>
        ))}
      </div>

      {activeTab === "artwork" && (
        <form onSubmit={handleArtworkSubmit} className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur space-y-4">
          <h3 className="text-lg font-semibold text-foreground flex items-center gap-2">
            <Upload className="h-4 w-4 text-primary" />
            Publier une œuvre
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Titre de l'œuvre *"
              value={artworkTitle}
              onChange={(e) => setArtworkTitle(e.target.value)}
              required
            />
            <select
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              value={artworkCategory}
              onChange={(e) => setArtworkCategory(e.target.value)}
            >
              {categories.map((c) => (
                <option key={c.slug} value={c.slug}>{c.title}</option>
              ))}
            </select>
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Medium (ex: Huile, Digital, Aquarelle)"
              value={artworkMedium}
              onChange={(e) => setArtworkMedium(e.target.value)}
            />
            <div className="md:col-span-2">
              <label className="mb-1.5 block text-xs text-muted-foreground">Image de l'œuvre</label>
              <ImageUploader
                currentUrl={artworkImage}
                onUpload={(url) => setArtworkImage(url)}
              />
            </div>
          </div>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            <Upload className="h-4 w-4" />
            {submitting ? "Envoi..." : "Soumettre l'œuvre"}
          </button>
        </form>
      )}

      {activeTab === "artist" && (
        <form onSubmit={handleArtistSubmit} className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur space-y-4">
          <h3 className="text-lg font-semibold text-foreground flex items-center gap-2">
            <Music className="h-4 w-4 text-primary" />
            Créer un profil artiste
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Nom de l'artiste *"
              value={artistName}
              onChange={(e) => setArtistName(e.target.value)}
              required
            />
            <select
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              value={artistCategory}
              onChange={(e) => setArtistCategory(e.target.value)}
            >
              {categories.map((c) => (
                <option key={c.slug} value={c.slug}>{c.title}</option>
              ))}
            </select>
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Rôle (ex: Peintre, Musicien)"
              value={artistRole}
              onChange={(e) => setArtistRole(e.target.value)}
            />
            <div className="md:col-span-2">
              <label className="mb-1.5 block text-xs text-muted-foreground">Photo de profil</label>
              <ImageUploader
                currentUrl={artistImage}
                onUpload={(url) => setArtistImage(url)}
              />
            </div>
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Œuvre mise en avant"
              value={artistWork}
              onChange={(e) => setArtistWork(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            <Upload className="h-4 w-4" />
            {submitting ? "Envoi..." : "Soumettre l'artiste"}
          </button>
        </form>
      )}

      {activeTab === "discussion" && (
        <form onSubmit={handleDiscussionSubmit} className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur space-y-4">
          <h3 className="text-lg font-semibold text-foreground flex items-center gap-2">
            <Pen className="h-4 w-4 text-primary" />
            Lancer une discussion
          </h3>
          <div className="grid gap-4 md:grid-cols-2">
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Titre de la discussion *"
              value={discussionTitle}
              onChange={(e) => setDiscussionTitle(e.target.value)}
              required
            />
            <select
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              value={discussionCategory}
              onChange={(e) => setDiscussionCategory(e.target.value)}
            >
              {categories.map((c) => (
                <option key={c.slug} value={c.slug}>{c.title}</option>
              ))}
            </select>
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Nom de l'auteur"
              value={discussionAuthor}
              onChange={(e) => setDiscussionAuthor(e.target.value)}
            />
            <input
              className="rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              placeholder="Label temps (ex: Aujourd'hui, Hier)"
              value={discussionTime}
              onChange={(e) => setDiscussionTime(e.target.value)}
            />
          </div>
          <button
            type="submit"
            disabled={submitting}
            className="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90 disabled:opacity-50"
          >
            <Upload className="h-4 w-4" />
            {submitting ? "Envoi..." : "Lancer la discussion"}
          </button>
        </form>
      )}

      <SubmissionsHistory />
    </div>
  );
}

function SubmissionsHistory() {
  const profile = getProfile();
  const submissions = profile?.submissions || [];

  if (submissions.length === 0) return null;

  const statusColors: Record<string, string> = {
    pending: "border-yellow-500/30 bg-yellow-500/10 text-yellow-400",
    approved: "border-primary/30 bg-primary/10 text-primary",
    rejected: "border-red-500/30 bg-red-500/10 text-red-300",
  };

  function getTitle(sub: SubmissionItem): string {
    const data = sub.data as any;
    return data.title || data.name || "Sans titre";
  }

  return (
    <div className="rounded-2xl border border-border bg-card/60 p-6 backdrop-blur">
      <h3 className="mb-4 text-lg font-semibold text-foreground">
        Historique des soumissions ({submissions.length})
      </h3>
      <div className="space-y-3 max-h-96 overflow-y-auto">
        {submissions.slice().reverse().map((sub) => (
          <div
            key={sub.id}
            className="rounded-xl border border-border bg-background/50 px-4 py-3"
          >
            <div className="flex items-center justify-between">
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium text-foreground truncate">
                  {getTitle(sub)}
                </p>
                <p className="text-xs text-muted-foreground">
                  {sub.type === "artist" ? "Profil artiste" : sub.type === "artwork" ? "Œuvre" : "Discussion"}
                  {" · "}
                  {new Date(sub.submittedAt).toLocaleDateString("fr-FR")}
                </p>
              </div>
              <div className="ml-3 flex items-center gap-2">
                {/* Quality score */}
                <span className="text-[10px] font-mono text-muted-foreground/60">
                  {sub.qualityScore}%
                </span>
                <span
                  className={`shrink-0 rounded-full border px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.12em] ${
                    statusColors[sub.status] || ""
                  }`}
                >
                  {sub.status === "pending" ? "En attente" : sub.status === "approved" ? "Validé" : "Refusé"}
                </span>
              </div>
            </div>
            {/* Moderation reason */}
            {sub.moderationReason && (
              <p className={`mt-1.5 text-[11px] italic ${
                sub.status === "approved" ? "text-primary/60" : "text-yellow-400/60"
              }`}>
                {sub.moderationReason}
              </p>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}