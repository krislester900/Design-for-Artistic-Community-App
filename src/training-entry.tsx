import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { ThemeProvider } from "./app/components/ui/ThemeProvider.tsx";
import { TrainingDashboard } from "./app/training/TrainingDashboard.tsx";

createRoot(document.getElementById("root")!).render(
  <ThemeProvider>
    <TrainingDashboard />
  </ThemeProvider>
);
