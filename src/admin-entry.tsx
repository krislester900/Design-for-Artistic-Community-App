import { createRoot } from "react-dom/client";
import { useState, useCallback } from "react";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { AdminApp } from "./app/admin/AdminApp.tsx";
import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";

function AdminRoot() {
  const [ready, setReady] = useState(false);

  const handleComplete = useCallback(() => setReady(true), []);

  if (!ready) {
    return <ArtLoadingScreen onComplete={handleComplete} />;
  }

  return (
    <ThemeProvider>
      <AdminApp />
    </ThemeProvider>
  );
}

createRoot(document.getElementById("root")!).render(<AdminRoot />);
