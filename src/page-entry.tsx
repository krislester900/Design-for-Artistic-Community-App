import { createRoot } from "react-dom/client";
import { useState, useCallback } from "react";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { MultiPageApp } from "./app/pages/MultiPageApp.tsx";
import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";

const page = document.body.dataset.page;

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
      <MultiPageApp page={page} />
    </ThemeProvider>
  );
}

createRoot(document.getElementById("root")!).render(<PageRoot />);
