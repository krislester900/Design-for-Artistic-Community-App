import { useState } from "react";
import { X } from "lucide-react";

type CreateChannelDialogProps = {
  open: boolean;
  onClose: () => void;
  onCreate: (name: string, description: string, type: "public" | "private", categorySlug: string | null) => void;
};

export function CreateChannelDialog({ open, onClose, onCreate }: CreateChannelDialogProps) {
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [type, setType] = useState<"public" | "private">("public");
  const [categorySlug, setCategorySlug] = useState<string | null>(null);

  if (!open) return null;

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    onCreate(name.trim(), description.trim(), type, categorySlug);
    setName("");
    setDescription("");
    setType("public");
    setCategorySlug(null);
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
      <div className="w-full max-w-md rounded-2xl border border-border bg-card p-6 shadow-xl">
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-semibold text-foreground">Créer un salon</h3>
          <button onClick={onClose} className="text-muted-foreground hover:text-foreground">
            <X className="h-5 w-5" />
          </button>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs uppercase tracking-[0.15em] text-muted-foreground">Nom</label>
            <input
              className="w-full rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="mon-salon"
              required
              autoFocus
            />
          </div>
          <div>
            <label className="mb-1 block text-xs uppercase tracking-[0.15em] text-muted-foreground">Description</label>
            <input
              className="w-full rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none focus:border-primary"
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Description du salon..."
            />
          </div>
          <div>
            <label className="mb-1 block text-xs uppercase tracking-[0.15em] text-muted-foreground">Type</label>
            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setType("public")}
                className={`flex-1 rounded-xl border px-4 py-2.5 text-sm transition-colors ${
                  type === "public"
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border text-muted-foreground hover:text-foreground"
                }`}
              >
                Public
              </button>
              <button
                type="button"
                onClick={() => setType("private")}
                className={`flex-1 rounded-xl border px-4 py-2.5 text-sm transition-colors ${
                  type === "private"
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border text-muted-foreground hover:text-foreground"
                }`}
              >
                Privé
              </button>
            </div>
          </div>
          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded-xl border border-border px-5 py-2.5 text-sm text-muted-foreground transition-colors hover:text-foreground"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="rounded-xl bg-primary px-5 py-2.5 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
            >
              Créer
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}