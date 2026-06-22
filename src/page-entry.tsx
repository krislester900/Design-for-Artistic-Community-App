import { createRoot } from "react-dom/client";
import { useState, useCallback, lazy, Suspense } from "react";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";

// Lazy load the secondary page shell.
const MultiPageApp = lazy(async () => {
  const mod = await import("./app/pages/MultiPageApp.tsx");
  return { default: mod.default };
});

const page = document.body.dataset.page ?? "";

if (!page) {
  throw new Error("Missing data-page attribute on body.");
}

function PageRoot() {
  const [ready, setReady] = useState(false);

  const handleComplete = useCallback(() => setReady(true), []);

  if (!ready) {
    return <ArtLoadingScreen onComplete={handleComplete} />;
  }

  return (
    <ThemeProvider>
      <Suspense fallback={<ArtLoadingScreen />}>
        <MultiPageApp page={page} />
      </Suspense>
    </ThemeProvider>
  );
}

createRoot(document.getElementById("root")!).render(<PageRoot />);
