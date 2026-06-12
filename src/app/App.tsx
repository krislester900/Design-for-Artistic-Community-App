import { useState } from "react";
import { Navigation } from "./components/Navigation";
import { Hero } from "./components/Hero";
import { ArtCategories } from "./components/ArtCategories";
import { FeaturedArtists } from "./components/FeaturedArtists";
import { ArtShowcase } from "./components/ArtShowcase";
import { CommunityFeed } from "./components/CommunityFeed";
import { JoinCTA } from "./components/JoinCTA";
import { Footer } from "./components/Footer";
import { ArtisticPattern } from "./components/ArtisticPattern";
import { ScrollReveal } from "./components/ScrollReveal";
import { useCommunityData } from "./hooks/useCommunityData";
import {
  type CategorySlug,
  type SectionId,
  getCategoryLabel,
} from "./data/community";

export default function App() {
  const [selectedCategory, setSelectedCategory] = useState<CategorySlug>("all");
  const { data, source, isLoading } = useCommunityData();

  const handleNavigate = (
    sectionId: SectionId,
    category: CategorySlug = "all",
  ) => {
    setSelectedCategory(category);

    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  return (
    <div className="relative min-h-screen bg-background text-foreground">
      <ArtisticPattern />
      <div className="relative z-10">
        <Navigation
          selectedCategory={selectedCategory}
          onNavigate={handleNavigate}
        />

        <main className="pt-20">
          <Hero categories={data.categories} onNavigate={handleNavigate} />

          <div className="sticky top-20 z-40 px-6 py-4">
            <div className="street-panel mx-auto flex max-w-7xl flex-col gap-3 px-6 py-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.3em] text-primary">
                  Parcours connecté
                </p>
                <p className="mt-2 text-sm text-muted-foreground">
                  Univers actif :{" "}
                  <span className="font-semibold uppercase tracking-[0.12em] text-foreground">
                    {getCategoryLabel(selectedCategory)}
                  </span>
                </p>
                <p className="text-xs uppercase tracking-[0.16em] text-muted-foreground/80">
                  Source de données :{" "}
                  <span className="font-semibold text-foreground">
                    {source === "supabase" ? "Supabase" : "Mock local"}
                  </span>
                  {isLoading ? " · chargement..." : ""}
                </p>
              </div>

              <div className="flex flex-wrap gap-3">
                <button
                  className="rounded-xl border border-border bg-background/50 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] transition-colors hover:border-primary hover:text-primary"
                  onClick={() => handleNavigate("categories", "all")}
                >
                  Voir tous les univers
                </button>
                <button
                  className="rounded-xl border border-primary/30 bg-primary px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-primary-foreground shadow-[0_10px_28px_rgba(255,106,26,0.25)] transition-all hover:-translate-y-0.5"
                  onClick={() => handleNavigate("showcase", selectedCategory)}
                >
                  Continuer la découverte
                </button>
              </div>
            </div>
          </div>

          <ScrollReveal>
            <ArtCategories
              categories={data.categories}
              artists={data.artists}
              artworks={data.artworks}
              discussions={data.discussions}
              selectedCategory={selectedCategory}
              onNavigate={handleNavigate}
            />
          </ScrollReveal>
          <ScrollReveal delay={0.1}>
            <FeaturedArtists
              artists={data.artists}
              selectedCategory={selectedCategory}
              onNavigate={handleNavigate}
            />
          </ScrollReveal>
          <ScrollReveal delay={0.15}>
            <ArtShowcase
              artworks={data.artworks}
              selectedCategory={selectedCategory}
              onNavigate={handleNavigate}
            />
          </ScrollReveal>
          <ScrollReveal delay={0.1}>
            <CommunityFeed
              discussions={data.discussions}
              trends={data.trends}
              events={data.events}
              selectedCategory={selectedCategory}
              onNavigate={handleNavigate}
            />
          </ScrollReveal>
          <ScrollReveal delay={0.15} direction="none">
            <JoinCTA
              communityStats={data.communityStats}
              onNavigate={handleNavigate}
            />
          </ScrollReveal>
        </main>

        <Footer
          selectedCategory={selectedCategory}
          onNavigate={handleNavigate}
        />
      </div>
    </div>
  );
}
