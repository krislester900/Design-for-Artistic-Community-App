import { useEffect, useState } from "react";

export function MuseCarouselPage() {
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    setLoaded(true);
  }, []);

  return (
    <div className="relative w-full h-screen bg-neutral-950">
      {!loaded && (
        <div className="absolute inset-0 flex items-center justify-center bg-neutral-950 z-10">
          <div className="text-white text-lg">Chargement de Simple Card Stack...</div>
        </div>
      )}
      <iframe
        src="/simple-card-stack/index.html"
        title="Simple Card Stack"
        className="w-full h-full border-0"
        sandbox="allow-scripts allow-same-origin allow-forms allow-presentation"
        allow="autoplay; encrypted-media"
        onLoad={() => setLoaded(true)}
      />
    </div>
  );
}