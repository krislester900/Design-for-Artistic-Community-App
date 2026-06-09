export function ArtisticPattern() {
  return (
    <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden opacity-5">
      <svg className="absolute w-full h-full" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <pattern id="victorian-pattern" x="0" y="0" width="100" height="100" patternUnits="userSpaceOnUse">
            <circle cx="50" cy="50" r="2" fill="currentColor" className="text-primary" />
            <path d="M 30 30 Q 50 20 70 30" stroke="currentColor" strokeWidth="0.5" fill="none" className="text-secondary" />
            <path d="M 30 70 Q 50 80 70 70" stroke="currentColor" strokeWidth="0.5" fill="none" className="text-accent" />
            <rect x="45" y="10" width="10" height="10" fill="none" stroke="currentColor" strokeWidth="0.5" className="text-primary" transform="rotate(45 50 15)" />
            <rect x="45" y="80" width="10" height="10" fill="none" stroke="currentColor" strokeWidth="0.5" className="text-secondary" transform="rotate(45 50 85)" />
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#victorian-pattern)" />
      </svg>

      {/* Floating decorative elements */}
      <div className="absolute top-20 left-10 w-64 h-64 bg-gradient-to-br from-primary/5 to-transparent rounded-full blur-3xl animate-pulse" style={{ animationDuration: '8s' }} />
      <div className="absolute bottom-20 right-20 w-80 h-80 bg-gradient-to-br from-secondary/5 to-transparent rounded-full blur-3xl animate-pulse" style={{ animationDuration: '10s', animationDelay: '2s' }} />
      <div className="absolute top-1/2 left-1/3 w-96 h-96 bg-gradient-to-br from-accent/5 to-transparent rounded-full blur-3xl animate-pulse" style={{ animationDuration: '12s', animationDelay: '4s' }} />
    </div>
  );
}
