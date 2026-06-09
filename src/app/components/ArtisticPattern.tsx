export function ArtisticPattern() {
  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden opacity-[0.08]">
      <svg className="absolute w-full h-full" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern
            id="street-pattern"
            x="0"
            y="0"
            width="140"
            height="140"
            patternUnits="userSpaceOnUse"
          >
            <path
              d="M 0 118 L 140 -22"
              stroke="currentColor"
              strokeWidth="1"
              fill="none"
              className="text-foreground"
            />
            <path
              d="M 20 140 L 140 20"
              stroke="currentColor"
              strokeWidth="0.8"
              fill="none"
              className="text-primary"
            />
            <circle cx="24" cy="32" r="4" fill="currentColor" className="text-secondary" />
            <circle cx="32" cy="38" r="1.4" fill="currentColor" className="text-secondary" />
            <circle cx="38" cy="28" r="1.8" fill="currentColor" className="text-secondary" />
            <rect
              x="88"
              y="78"
              width="26"
              height="26"
              fill="none"
              stroke="currentColor"
              strokeWidth="1"
              className="text-accent"
              transform="rotate(12 101 91)"
            />
            <path
              d="M 90 34 C 104 26 118 52 132 40"
              stroke="currentColor"
              strokeWidth="1.2"
              fill="none"
              className="text-primary"
            />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#street-pattern)" />
      </svg>

      <div
        className="absolute left-10 top-20 h-64 w-64 rounded-full bg-gradient-to-br from-primary/8 to-transparent blur-3xl animate-pulse"
        style={{ animationDuration: "8s" }}
      />
      <div
        className="absolute bottom-20 right-20 h-80 w-80 rounded-full bg-gradient-to-br from-secondary/8 to-transparent blur-3xl animate-pulse"
        style={{ animationDuration: "10s", animationDelay: "2s" }}
      />
      <div
        className="absolute left-1/3 top-1/2 h-96 w-96 rounded-full bg-gradient-to-br from-accent/8 to-transparent blur-3xl animate-pulse"
        style={{ animationDuration: "12s", animationDelay: "4s" }}
      />
    </div>
  );
}
