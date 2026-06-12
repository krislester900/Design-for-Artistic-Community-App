
  import { createRoot } from "react-dom/client";
  import { useState, useEffect } from "react";
  import App from "./app/App.tsx";
  import "./styles/index.css";
  import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
  import { LoadingScreen } from "./app/components/LoadingScreen.tsx";

  function Root() {
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
        <App />
      </ThemeProvider>
    );
  }

  createRoot(document.getElementById("root")!).render(<Root />);
  