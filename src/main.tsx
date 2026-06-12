
  import { createRoot } from "react-dom/client";
  import { useState, useCallback, lazy, Suspense } from "react";
  import "./styles/index.css";
  import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
  import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";

  // Lazy load the main App component (not needed during loading screen)
  const App = lazy(() => import("./app/App.tsx"));

  function Root() {
    const [ready, setReady] = useState(false);

    const handleComplete = useCallback(() => setReady(true), []);

    if (!ready) {
      return <ArtLoadingScreen onComplete={handleComplete} />;
    }

    return (
      <ThemeProvider>
        <Suspense fallback={<ArtLoadingScreen />}>
          <App />
        </Suspense>
      </ThemeProvider>
    );
  }

  createRoot(document.getElementById("root")!).render(<Root />);
  