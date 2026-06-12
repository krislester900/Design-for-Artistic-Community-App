import { Moon, Sun } from "lucide-react";
import { useTheme } from "next-themes";
import { useEffect, useState } from "react";

export function ThemeToggle() {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  // Avoid hydration mismatch by rendering only after mount
  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <button
        className="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-card/60 text-muted-foreground transition-colors hover:border-primary hover:text-primary"
        disabled
        aria-label="Changer le thème"
      >
        <Sun className="h-4 w-4" />
      </button>
    );
  }

  const isDark = (theme === "dark" || resolvedTheme === "dark");

  return (
    <button
      onClick={() => setTheme(isDark ? "light" : "dark")}
      className="inline-flex h-9 w-9 items-center justify-center rounded-xl border border-border bg-card/60 text-muted-foreground transition-colors hover:border-primary hover:text-primary"
      aria-label={isDark ? "Activer le mode clair" : "Activer le mode sombre"}
    >
      {isDark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
    </button>
  );
}