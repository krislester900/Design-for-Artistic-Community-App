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

          <div className="sticky top-20 z-40 border-y border-border bg-background/80 backdrop-blur-xl">
            <div className="mx-auto flex max-w-7xl flex-col gap-3 px-6 py-4 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.25em] text-primary">
                  Parcours connecté
                </p>
                <p className="text-sm text-muted-foreground">
                  Univers actif :{" "}
                  <span className="font-medium text-foreground">
                    {getCategoryLabel(selectedCategory)}
                  </span>
                </p>
                <p className="text-xs text-muted-foreground/80">
                  Source de données :{" "}
                  <span className="font-medium text-foreground">
                    {source === "supabase" ? "Supabase" : "Mock local"}
                  </span>
                  {isLoading ? " · chargement..." : ""}
                </p>
              </div>

              <div className="flex flex-wrap gap-3">
                <button
                  className="rounded-lg border border-border px-4 py-2 text-sm transition-colors hover:border-primary hover:text-primary"
                  onClick={() => handleNavigate("categories", "all")}
                >
                  Voir tous les univers
                </button>
                <button
                  className="rounded-lg bg-primary px-4 py-2 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
                  onClick={() => handleNavigate("showcase", selectedCategory)}
                >
                  Continuer la découverte
                </button>
              </div>
            </div>
          </div>

          <ArtCategories
            categories={data.categories}
            artists={data.artists}
            artworks={data.artworks}
            discussions={data.discussions}
            selectedCategory={selectedCategory}
            onNavigate={handleNavigate}
          />
          <FeaturedArtists
            artists={data.artists}
            selectedCategory={selectedCategory}
            onNavigate={handleNavigate}
          />
          <ArtShowcase
            artworks={data.artworks}
            selectedCategory={selectedCategory}
            onNavigate={handleNavigate}
          />
          <CommunityFeed
            discussions={data.discussions}
            trends={data.trends}
            events={data.events}
            selectedCategory={selectedCategory}
            onNavigate={handleNavigate}
          />
          <JoinCTA
            communityStats={data.communityStats}
            onNavigate={handleNavigate}
          />
        </main>

        <Footer
          selectedCategory={selectedCategory}
          onNavigate={handleNavigate}
        />
      </div>
    </div>
  );
}
