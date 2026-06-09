import { ImageWithFallback } from "./ImageWithFallback";
import type { StaticPageId } from "../lib/page-links";

type BackdropConfig = {
  image: string;
  tint: string;
  accent: string;
  label: string;
  particles?: "music" | "visual-art" | "manga" | "film" | "literature" | "animation" | "community" | "database" | "profile" | "login" | "signup";
};

const pageBackdropConfig: Record<StaticPageId, BackdropConfig> = {
  home: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=cinematic%20punk%20creative%20district%20at%20night%2C%20artists%20moving%20through%20alleyways%2C%20graffiti%20textures%2C%20neon%20orange%20and%20cyan%20accents%2C%20high-end%20editorial%20scene%2C%20alive%20and%20atmospheric%2C%20premium%20website%20background&image_size=landscape_16_9",
    tint: "from-primary/28 via-background/38 to-accent/18",
    accent: "bg-primary/18",
    label: "Accueil",
  },
  music: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=cinematic%20punk%20music%20scene%2C%20dark%20urban%20stage%2C%20falling%20music%20notes%2C%20katana%20slash%20through%20sound%20waves%2C%20spray%20paint%20textures%2C%20dynamic%20motion%2C%20beautiful%20and%20believable%2C%20premium%20website%20background&image_size=landscape_16_9",
    tint: "from-primary/28 via-background/44 to-secondary/14",
    accent: "bg-primary/22",
    label: "Musique",
    particles: "music",
  },
  "visual-art": {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=high-end%20street%20art%20atelier%2C%20massive%20painted%20wall%2C%20floating%20pigment%20dust%2C%20ink%20bursts%2C%20urban%20creative%20chaos%2C%20punk%20editorial%20scene%2C%20premium%20website%20background&image_size=landscape_16_9",
    tint: "from-accent/20 via-background/40 to-primary/16",
    accent: "bg-accent/18",
    label: "Art visuel",
    particles: "visual-art",
  },
  manga: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=dark%20manga-inspired%20street%20scene%2C%20torn%20inked%20panels%2C%20speed%20lines%2C%20paper%20fragments%2C%20punk%20urban%20energy%2C%20editorial%20hero%20background%2C%20beautiful%20and%20grounded&image_size=landscape_16_9",
    tint: "from-foreground/12 via-background/45 to-primary/16",
    accent: "bg-foreground/12",
    label: "Manga",
    particles: "manga",
  },
  film: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=independent%20film%20set%20in%20rainy%20urban%20backstreet%2C%20projector%20light%2C%20cinematic%20fog%2C%20film%20strips%20in%20motion%2C%20punk%20grunge%20editorial%20background%2C%20premium%20website%20scene&image_size=landscape_16_9",
    tint: "from-primary/20 via-background/48 to-accent/12",
    accent: "bg-foreground/10",
    label: "Films",
    particles: "film",
  },
  literature: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=atmospheric%20punk%20literary%20scene%2C%20floating%20pages%2C%20ink%20smoke%2C%20typewriter%20keys%2C%20dark%20urban%20library%20corridor%2C%20premium%20editorial%20website%20background&image_size=landscape_16_9",
    tint: "from-secondary/18 via-background/44 to-primary/14",
    accent: "bg-secondary/18",
    label: "Litterature",
    particles: "literature",
  },
  animation: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=stylized%20animation%20studio%20space%2C%20moving%20frames%2C%20light%20trails%2C%20cel%20layers%2C%20punk%20graphic%20energy%2C%20beautiful%20premium%20website%20background%2C%20alive%20and%20dynamic&image_size=landscape_16_9",
    tint: "from-accent/22 via-background/42 to-secondary/14",
    accent: "bg-accent/18",
    label: "Animation",
    particles: "animation",
  },
  community: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=creative%20community%20hub%20at%20night%2C%20crowd%20silhouettes%2C%20chat%20symbols%20and%20light%20bursts%2C%20punk%20street%20textures%2C%20vibrant%20yet%20dark%2C%20premium%20website%20background&image_size=landscape_16_9",
    tint: "from-primary/20 via-background/44 to-accent/16",
    accent: "bg-primary/18",
    label: "Communaute",
    particles: "community",
  },
  database: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=dark%20data%20vault%20with%20glowing%20structures%2C%20abstract%20information%20streams%2C%20industrial%20punk%20tech%20space%2C%20premium%20website%20background%2C%20beautiful%20and%20immersive&image_size=landscape_16_9",
    tint: "from-accent/18 via-background/50 to-primary/14",
    accent: "bg-accent/16",
    label: "Base",
    particles: "database",
  },
  profile: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=heroic%20creative%20profile%20portrait%20scene%2C%20dark%20punk%20editorial%20background%2C%20identity%20fragments%2C%20urban%20textures%2C%20clean%20beautiful%20website%20background%2C%20premium%20and%20alive&image_size=landscape_16_9",
    tint: "from-primary/20 via-background/42 to-secondary/14",
    accent: "bg-primary/16",
    label: "Profil",
    particles: "profile",
  },
  login: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=secure%20punk%20access%20gate%2C%20dark%20urban%20corridor%2C%20glowing%20locks%2C%20light%20scanning%20lines%2C%20premium%20website%20background%2C%20beautiful%20and%20grounded&image_size=landscape_16_9",
    tint: "from-primary/18 via-background/48 to-accent/14",
    accent: "bg-primary/16",
    label: "Connexion",
    particles: "login",
  },
  signup: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=creative%20awakening%20scene%2C%20punk%20urban%20night%2C%20light%20fragments%2C%20new%20identity%20forming%2C%20beautiful%20premium%20website%20background%2C%20hopeful%20and%20alive&image_size=landscape_16_9",
    tint: "from-secondary/18 via-background/42 to-primary/20",
    accent: "bg-secondary/16",
    label: "Inscription",
    particles: "signup",
  },
  admin: {
    image:
      "https://coresg-normal.trae.ai/api/ide/v1/text_to_image?prompt=creative%20control%20room%2C%20dashboard%20walls%2C%20punk%20industrial%20design%2C%20glowing%20signals%2C%20premium%20website%20background&image_size=landscape_16_9",
    tint: "from-primary/18 via-background/45 to-accent/14",
    accent: "bg-primary/16",
    label: "Admin",
  },
};

const musicSymbols = ["♪", "♫", "♩", "♬", "♪", "♩", "♫", "♬"];
const mangaSymbols = ["//", "////", "///", "/////"];
const litSymbols = ["A", "Z", "✎", "¶", "§", "A"];
const databaseSymbols = ["01", "10", "[]", "<>", "{}", "SQL"];

export function PageBackdrop({ page }: { page: StaticPageId }) {
  const config = pageBackdropConfig[page];

  return (
    <div className="pointer-events-none fixed inset-0 z-0 overflow-hidden">
      <div className="absolute inset-0">
        <ImageWithFallback
          src={config.image}
          alt={`Fond ${config.label}`}
          className="animate-hero-pan h-full w-full object-cover object-center"
        />
      </div>
      <div className={`absolute inset-0 bg-gradient-to-br ${config.tint}`} />
      <div className="hero-noise absolute inset-0 opacity-25" />
      <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(9,9,13,0.14),rgba(9,9,13,0.56),rgba(9,9,13,0.9))]" />
      <div className={`absolute left-[8%] top-[14%] h-40 w-40 rounded-full blur-3xl ${config.accent}`} />
      <div className="absolute bottom-[16%] right-[10%] h-56 w-56 rounded-full bg-accent/10 blur-3xl" />
      <div className="absolute inset-0 bg-[repeating-linear-gradient(115deg,rgba(255,255,255,0.012)_0,rgba(255,255,255,0.012)_2px,transparent_2px,transparent_18px)]" />
      <ThemeParticles page={page} type={config.particles} />
    </div>
  );
}

function ThemeParticles({
  page,
  type,
}: {
  page: StaticPageId;
  type?: BackdropConfig["particles"];
}) {
  if (!type) {
    return null;
  }

  if (type === "music") {
    return (
      <>
        {musicSymbols.map((symbol, index) => (
          <span
            key={`${page}-${symbol}-${index}`}
            className="animate-theme-drift absolute text-2xl font-semibold text-foreground/30"
            style={{
              left: `${8 + index * 11}%`,
              top: `${-8 - index * 6}%`,
              animationDuration: `${10 + index}s`,
              animationDelay: `${index * -1.4}s`,
              transform: `rotate(${index % 2 === 0 ? -10 : 14}deg)`,
            }}
          >
            {symbol}
          </span>
        ))}
        <div className="animate-slice-glow absolute left-[18%] top-[24%] h-[2px] w-[28%] rotate-[-18deg] bg-gradient-to-r from-transparent via-primary to-transparent" />
        <div className="animate-slice-glow absolute right-[12%] top-[38%] h-[2px] w-[20%] rotate-[16deg] bg-gradient-to-r from-transparent via-foreground/70 to-transparent" />
      </>
    );
  }

  if (type === "visual-art") {
    return (
      <>
        {[0, 1, 2, 3, 4].map((index) => (
          <span
            key={`${page}-paint-${index}`}
            className="animate-theme-drift absolute rounded-full blur-xl"
            style={{
              left: `${6 + index * 18}%`,
              top: `${18 + (index % 3) * 14}%`,
              width: `${90 + index * 22}px`,
              height: `${40 + index * 12}px`,
              background:
                index % 2 === 0
                  ? "rgba(255, 106, 26, 0.14)"
                  : "rgba(40, 216, 255, 0.14)",
              animationDuration: `${16 + index * 2}s`,
            }}
          />
        ))}
      </>
    );
  }

  if (type === "manga") {
    return (
      <>
        {mangaSymbols.map((symbol, index) => (
          <span
            key={`${page}-manga-${index}`}
            className="animate-theme-sweep absolute text-3xl font-semibold tracking-[0.3em] text-foreground/22"
            style={{
              left: `${index * 18}%`,
              top: `${15 + index * 9}%`,
              animationDuration: `${11 + index}s`,
              animationDelay: `${index * -1.2}s`,
            }}
          >
            {symbol}
          </span>
        ))}
      </>
    );
  }

  if (type === "film") {
    return (
      <>
        {[0, 1, 2].map((index) => (
          <div
            key={`${page}-film-${index}`}
            className="animate-theme-sweep absolute border border-foreground/14"
            style={{
              left: `${12 + index * 28}%`,
              top: `${16 + index * 10}%`,
              width: `${100 + index * 40}px`,
              height: `${150 + index * 20}px`,
              animationDuration: `${18 + index * 3}s`,
            }}
          />
        ))}
      </>
    );
  }

  if (type === "literature") {
    return (
      <>
        {litSymbols.map((symbol, index) => (
          <span
            key={`${page}-lit-${index}`}
            className="animate-theme-drift absolute text-xl font-medium text-foreground/24"
            style={{
              left: `${12 + index * 13}%`,
              top: `${10 + (index % 4) * 18}%`,
              animationDuration: `${13 + index * 1.8}s`,
              animationDelay: `${index * -1.4}s`,
            }}
          >
            {symbol}
          </span>
        ))}
      </>
    );
  }

  if (type === "animation") {
    return (
      <>
        {[0, 1, 2, 3, 4].map((index) => (
          <div
            key={`${page}-frame-${index}`}
            className="animate-theme-sweep absolute border border-accent/25 bg-accent/6"
            style={{
              left: `${8 + index * 16}%`,
              top: `${16 + (index % 2) * 16}%`,
              width: `${80 + index * 12}px`,
              height: `${54 + index * 10}px`,
              animationDuration: `${12 + index * 2}s`,
            }}
          />
        ))}
      </>
    );
  }

  if (type === "community") {
    return (
      <>
        {["●", "✦", "●", "✦", "●"].map((symbol, index) => (
          <span
            key={`${page}-community-${index}`}
            className="animate-theme-drift absolute text-2xl text-primary/28"
            style={{
              left: `${15 + index * 17}%`,
              top: `${18 + (index % 3) * 20}%`,
              animationDuration: `${14 + index * 2}s`,
            }}
          >
            {symbol}
          </span>
        ))}
      </>
    );
  }

  if (type === "database") {
    return (
      <>
        {databaseSymbols.map((symbol, index) => (
          <span
            key={`${page}-db-${index}`}
            className="animate-data-rain absolute font-mono text-sm text-accent/28"
            style={{
              left: `${8 + index * 14}%`,
              top: `${-12 - index * 6}%`,
              animationDuration: `${9 + index * 1.4}s`,
              animationDelay: `${index * -1.1}s`,
            }}
          >
            {symbol}
          </span>
        ))}
      </>
    );
  }

  if (type === "profile") {
    return (
      <>
        {[0, 1, 2, 3].map((index) => (
          <div
            key={`${page}-profile-${index}`}
            className="animate-theme-drift absolute rounded-2xl border border-primary/18 bg-primary/6"
            style={{
              left: `${14 + index * 18}%`,
              top: `${18 + (index % 2) * 18}%`,
              width: `${90 + index * 16}px`,
              height: `${120 + index * 18}px`,
              animationDuration: `${18 + index * 2}s`,
            }}
          />
        ))}
      </>
    );
  }

  if (type === "login" || type === "signup") {
    return (
      <>
        {[0, 1, 2, 3, 4].map((index) => (
          <div
            key={`${page}-auth-${index}`}
            className="animate-scanline absolute h-[2px] bg-gradient-to-r from-transparent via-primary/50 to-transparent"
            style={{
              left: `${6 + index * 12}%`,
              top: `${16 + index * 13}%`,
              width: `${120 + index * 24}px`,
              animationDuration: `${8 + index * 1.2}s`,
              animationDelay: `${index * -0.8}s`,
            }}
          />
        ))}
      </>
    );
  }

  return null;
}
