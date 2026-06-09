import { createRoot } from "react-dom/client";
import "./styles/index.css";
import { AdminApp } from "./app/admin/AdminApp.tsx";

createRoot(document.getElementById("root")!).render(<AdminApp />);
