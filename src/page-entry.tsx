import { createRoot } from "react-dom/client";
import { useState, useEffect } from "react";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { MultiPageApp } from "./app/pages/MultiPageApp.tsx";
import { LoadingScreen } from "./app/components/LoadingScreen.tsx";

const page = document.body.dataset.page;

if (!page) {
  throw new Error("Missing data-page attribute on body.");
}

function PageRoot() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    // Minimum 2.6s loading animation, then hide
    const timer = setTimeout(() => setReady(true), 2600);
    return () => clearTimeout(timer);
  }, []);

  if (!ready) {
    return <LoadingScreen />;
  }

  return (
    <ThemeProvider>
      <MultiPageApp page={page} />
    </ThemeProvider>
  );
}

createRoot(document.getElementById("root")!).render(<PageRoot />);
