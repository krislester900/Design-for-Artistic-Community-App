
  import { createRoot } from "react-dom/client";
  import { useState, useCallback } from "react";
  import App from "./app/App.tsx";
  import "./styles/index.css";
  import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
  import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";

  function Root() {
    const [ready, setReady] = useState(false);

    const handleComplete = useCallback(() => setReady(true), []);

    if (!ready) {
      return <ArtLoadingScreen onComplete={handleComplete} />;
    }

    return (
      <ThemeProvider>
        <App />
      </ThemeProvider>
    );
  }

  createRoot(document.getElementById("root")!).render(<Root />);
  