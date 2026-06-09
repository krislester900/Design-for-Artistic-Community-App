import { Navigation } from './components/Navigation';
import { Hero } from './components/Hero';
import { ArtCategories } from './components/ArtCategories';
import { FeaturedArtists } from './components/FeaturedArtists';
import { ArtShowcase } from './components/ArtShowcase';
import { CommunityFeed } from './components/CommunityFeed';
import { JoinCTA } from './components/JoinCTA';
import { Footer } from './components/Footer';
import { ArtisticPattern } from './components/ArtisticPattern';

export default function App() {
  return (
    <div className="min-h-screen bg-background text-foreground relative">
      <ArtisticPattern />
      <div className="relative z-10">
        <Navigation />
        <main className="pt-20">
          <Hero />
          <ArtCategories />
          <FeaturedArtists />
          <ArtShowcase />
          <CommunityFeed />
          <JoinCTA />
        </main>
        <Footer />
      </div>
    </div>
  );
}