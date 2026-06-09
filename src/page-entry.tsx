import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { MultiPageApp } from "./app/pages/MultiPageApp.tsx";

const page = document.body.dataset.page;

if (!page) {
  throw new Error("Missing data-page attribute on body.");
}

createRoot(document.getElementById("root")!).render(
  <MultiPageApp page={page} />,
);
