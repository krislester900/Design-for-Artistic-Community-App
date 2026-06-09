import { Music, Palette, Instagram, Twitter, Youtube, Github } from 'lucide-react';

export function Footer() {
  return (
    <footer className="border-t border-border bg-card/50 backdrop-blur">
      <div className="max-w-7xl mx-auto px-6 py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
          <div>
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 bg-gradient-to-br from-primary via-secondary to-accent rounded-lg flex items-center justify-center">
                <Palette className="w-6 h-6 text-primary-foreground" />
              </div>
              <h3 className="text-2xl font-display italic tracking-wide text-primary">
                Artéïa
              </h3>
            </div>
            <p className="text-muted-foreground font-accent italic mb-6">
              L'univers où l'art prend vie. Rejoignez une communauté passionnée par la création sous toutes ses formes.
            </p>
            <div className="flex items-center gap-3">
              <SocialLink icon={<Instagram className="w-5 h-5" />} />
              <SocialLink icon={<Twitter className="w-5 h-5" />} />
              <SocialLink icon={<Youtube className="w-5 h-5" />} />
              <SocialLink icon={<Github className="w-5 h-5" />} />
            </div>
          </div>

          <div>
            <h4 className="font-display text-lg mb-4">Explorer</h4>
            <ul className="space-y-3">
              <FooterLink text="Musique" />
              <FooterLink text="Art Visuel" />
              <FooterLink text="Manga & BD" />
              <FooterLink text="Films" />
              <FooterLink text="Littérature" />
            </ul>
          </div>

          <div>
            <h4 className="font-display text-lg mb-4">Communauté</h4>
            <ul className="space-y-3">
              <FooterLink text="Forum" />
              <FooterLink text="Événements" />
              <FooterLink text="Artistes" />
              <FooterLink text="Tendances" />
              <FooterLink text="Guides" />
            </ul>
          </div>

          <div>
            <h4 className="font-display text-lg mb-4">À propos</h4>
            <ul className="space-y-3">
              <FooterLink text="Notre mission" />
              <FooterLink text="Équipe" />
              <FooterLink text="Carrières" />
              <FooterLink text="Blog" />
              <FooterLink text="Contact" />
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-border flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-muted-foreground">
            © 2026 Artéïa. Tous droits réservés. Fait avec passion pour les créateurs.
          </p>
          <div className="flex items-center gap-6 text-sm text-muted-foreground">
            <button className="hover:text-primary transition-colors">Confidentialité</button>
            <button className="hover:text-primary transition-colors">Conditions</button>
            <button className="hover:text-primary transition-colors">Cookies</button>
          </div>
        </div>
      </div>
    </footer>
  );
}

function SocialLink({ icon }: { icon: React.ReactNode }) {
  return (
    <button className="w-10 h-10 rounded-lg border border-border bg-background hover:bg-primary hover:border-primary hover:text-primary-foreground transition-all flex items-center justify-center">
      {icon}
    </button>
  );
}

function FooterLink({ text }: { text: string }) {
  return (
    <li>
      <button className="text-muted-foreground hover:text-primary transition-colors">
        {text}
      </button>
    </li>
  );
}
