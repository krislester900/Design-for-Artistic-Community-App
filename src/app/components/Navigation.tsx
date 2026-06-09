import { Music, Film, BookOpen, Palette, MessageCircle, User } from 'lucide-react';

export function Navigation() {
  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-background/80 backdrop-blur-xl border-b border-border">
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-primary via-secondary to-accent rounded-lg flex items-center justify-center">
              <Palette className="w-6 h-6 text-primary-foreground" />
            </div>
            <h1 className="text-2xl font-display italic tracking-wide text-primary">
              Artéïa
            </h1>
          </div>

          <div className="hidden md:flex items-center gap-8">
            <NavLink icon={<Music className="w-4 h-4" />} label="Musique" />
            <NavLink icon={<Palette className="w-4 h-4" />} label="Art" />
            <NavLink icon={<BookOpen className="w-4 h-4" />} label="Manga" />
            <NavLink icon={<Film className="w-4 h-4" />} label="Films" />
            <NavLink icon={<MessageCircle className="w-4 h-4" />} label="Forum" />
          </div>

          <button className="flex items-center gap-2 px-4 py-2 bg-primary text-primary-foreground rounded-lg hover:opacity-90 transition-opacity">
            <User className="w-4 h-4" />
            <span>Profil</span>
          </button>
        </div>
      </div>
    </nav>
  );
}

function NavLink({ icon, label }: { icon: React.ReactNode; label: string }) {
  return (
    <button className="flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors group">
      <span className="group-hover:text-primary transition-colors">{icon}</span>
      <span className="font-medium">{label}</span>
    </button>
  );
}
