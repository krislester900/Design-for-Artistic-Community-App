const CLOUD_NAME = import.meta.env.VITE_CLOUDINARY_CLOUD_NAME;
const UPLOAD_PRESET = import.meta.env.VITE_CLOUDINARY_UPLOAD_PRESET;

export const hasCloudinaryEnv = Boolean(CLOUD_NAME && UPLOAD_PRESET);

export async function uploadImage(file: File): Promise<string> {
  if (!hasCloudinaryEnv) {
    throw new Error("Cloudinary non configuré — ajoute VITE_CLOUDINARY_CLOUD_NAME et VITE_CLOUDINARY_UPLOAD_PRESET dans .env");
  }

  const formData = new FormData();
  formData.append("file", file);
  formData.append("upload_preset", UPLOAD_PRESET);

  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`,
    { method: "POST", body: formData }
  );

  if (!res.ok) {
    const err = await res.json().catch(() => ({ error: { message: res.statusText } }));
    throw new Error(err.error?.message || "Échec upload Cloudinary");
  }

  const data = await res.json();
  // Optimisation auto : q_auto pour qualité adaptative, f_auto pour format webp/avif
  return data.secure_url.replace("/upload/", "/upload/q_auto,f_auto/");
}

export function getOptimizedUrl(url: string): string {
  if (!url?.includes("cloudinary.com")) return url;
  return url.replace("/upload/", "/upload/q_auto,f_auto/");
}
