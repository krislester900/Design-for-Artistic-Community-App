import { useState, useRef } from "react";
import { Upload, X, Image as ImageIcon, Loader2 } from "lucide-react";
import { uploadImage, hasCloudinaryEnv } from "../services/cloudinary";

type ImageUploaderProps = {
  onUpload: (url: string) => void;
  currentUrl?: string;
  accept?: string;
};

export function ImageUploader({ onUpload, currentUrl, accept = "image/*" }: ImageUploaderProps) {
  const [preview, setPreview] = useState<string | null>(currentUrl || null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [urlInput, setUrlInput] = useState(currentUrl || "");
  const [useUrl, setUseUrl] = useState(!hasCloudinaryEnv);
  const inputRef = useRef<HTMLInputElement>(null);

  async function handleFile(file: File | undefined) {
    if (!file) return;
    setError(null);
    setUploading(true);
    try {
      const url = await uploadImage(file);
      setPreview(url);
      onUpload(url);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Erreur upload");
    } finally {
      setUploading(false);
    }
  }

  function handleUrlSubmit() {
    if (!urlInput.trim()) return;
    setPreview(urlInput.trim());
    onUpload(urlInput.trim());
    setError(null);
  }

  function handleRemove() {
    setPreview(null);
    setUrlInput("");
    onUpload("");
  }

  return (
    <div className="space-y-2">
      {hasCloudinaryEnv && (
        <label className="inline-flex items-center gap-2 cursor-pointer">
          <input
            type="checkbox"
            checked={useUrl}
            onChange={() => setUseUrl(!useUrl)}
            className="rounded border-border"
          />
          <span className="text-xs text-muted-foreground">Saisir une URL au lieu d&apos;uploader</span>
        </label>
      )}

      {useUrl ? (
        <div className="flex gap-2">
          <input
            className="flex-1 rounded-xl border border-border bg-background px-4 py-2.5 text-sm text-foreground outline-none placeholder:text-muted-foreground/50 focus:border-primary"
            placeholder="https://exemple.com/image.jpg"
            value={urlInput}
            onChange={(e) => setUrlInput(e.target.value)}
          />
          <button
            type="button"
            onClick={handleUrlSubmit}
            className="rounded-xl bg-primary px-4 text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            OK
          </button>
        </div>
      ) : (
        <div
          onClick={() => inputRef.current?.click()}
          className="flex cursor-pointer flex-col items-center justify-center rounded-xl border-2 border-dashed border-border bg-background/50 p-6 transition-colors hover:border-primary/50"
        >
          {uploading ? (
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          ) : (
            <>
              <Upload className="mb-2 h-6 w-6 text-muted-foreground" />
              <p className="text-xs text-muted-foreground">Clique pour uploader une image</p>
            </>
          )}
          <input
            ref={inputRef}
            type="file"
            accept={accept}
            className="hidden"
            onChange={(e) => handleFile(e.target.files?.[0])}
            disabled={uploading}
          />
        </div>
      )}

      {error && <p className="text-xs text-red-400">{error}</p>}

      {preview && (
        <div className="relative inline-block">
          <img
            src={preview}
            alt="Aperçu"
            className="h-24 w-24 rounded-lg object-cover"
          />
          <button
            type="button"
            onClick={handleRemove}
            className="absolute -right-2 -top-2 flex h-5 w-5 items-center justify-center rounded-full bg-destructive text-white shadow"
          >
            <X className="h-3 w-3" />
          </button>
        </div>
      )}
    </div>
  );
}
