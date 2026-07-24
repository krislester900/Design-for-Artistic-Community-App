import { useEffect, useState } from "react";

export function VynoraPage() {
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    setLoaded(true);
  }, []);

  return (
    <div className="relative w-full h-screen bg-black">
      {!loaded && (
        <div className="absolute inset-0 flex items-center justify-center bg-black z-10">
          <div className="text-white text-lg">Chargement de Vynora...</div>
        </div>
      )}
      <iframe
        src="/vynora/index.html"
        title="Vynora Music"
        className="w-full h-full border-0"
        sandbox="allow-scripts allow-same-origin allow-forms allow-presentation"
        allow="autoplay; encrypted-media"
        onLoad={() => setLoaded(true)}
      />
    </div>
  );
}