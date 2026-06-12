import { createRoot } from "react-dom/client";
import { useState, useEffect } from "react";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { AdminApp } from "./app/admin/AdminApp.tsx";
import { LoadingScreen } from "./app/components/LoadingScreen.tsx";

function AdminRoot() {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setReady(true), 2600);
    return () => clearTimeout(timer);
  }, []);

  if (!ready) {
    return <LoadingScreen />;
  }

  return (
    <ThemeProvider>
      <AdminApp />
    </ThemeProvider>
  );
}

createRoot(document.getElementById("root")!).render(<AdminRoot />);
