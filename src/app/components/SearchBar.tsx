import { useState, useMemo } from "react";
import { Search, X } from "lucide-react";

interface SearchBarProps {
  placeholder?: string;
  onSearch: (query: string) => void;
  className?: string;
}

export function SearchBar({
  placeholder = "Rechercher...",
  onSearch,
  className = "",
}: SearchBarProps) {
  const [query, setQuery] = useState("");

  function handleChange(value: string) {
    setQuery(value);
    onSearch(value);
  }

  return (
    <div className={`relative ${className}`}>
      <Search className="absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <input
        type="text"
        value={query}
        onChange={(e) => handleChange(e.target.value)}
        placeholder={placeholder}
        className="w-full rounded-xl border border-border bg-background/60 py-3 pl-11 pr-10 text-sm text-foreground outline-none backdrop-blur transition-colors placeholder:text-muted-foreground/50 focus:border-primary"
      />
      {query && (
        <button
          onClick={() => handleChange("")}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-1 text-muted-foreground hover:text-foreground"
        >
          <X className="h-4 w-4" />
        </button>
      )}
    </div>
  );
}

export function useSearch<T>(
  items: T[],
  query: string,
  keys: (keyof T)[]
): T[] {
  return useMemo(() => {
    if (!query.trim()) return items;
    const lower = query.toLowerCase();
    return items.filter((item) =>
      keys.some((key) => {
        const val = item[key];
        return typeof val === "string" && val.toLowerCase().includes(lower);
      })
    );
  }, [items, query, keys]);
}