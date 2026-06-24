
  import { createRoot } from "react-dom/client";
  import { useState, useCallback } from "react";
  import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
  import "./styles/index.css";
  import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
  import { ArtLoadingScreen } from "./app/components/ArtLoadingScreen.tsx";
  import { ErrorBoundary } from "./app/components/ErrorBoundary.tsx";
  import { AppRouter } from "./app/Router.tsx";

  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60_000,
        refetchOnWindowFocus: false,
      },
    },
  });

  function Root() {
    const [ready, setReady] = useState(false);

    const handleComplete = useCallback(() => setReady(true), []);

    if (!ready) {
      return <ArtLoadingScreen onComplete={handleComplete} />;
    }

    return (
      <ErrorBoundary>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider>
            <AppRouter />
          </ThemeProvider>
        </QueryClientProvider>
      </ErrorBoundary>
    );
  }

  createRoot(document.getElementById("root")!).render(<Root />);
  