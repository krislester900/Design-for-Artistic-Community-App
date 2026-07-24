interface iTunesSearchResult {
  results: iTunesTrack[];
}

interface iTunesTrack {
  trackId: number;
  artistName: string;
  trackName: string;
  artworkUrl100: string;
}

async function nativeFetch(url: string): Promise<iTunesSearchResult> {
  const response = await fetch(url, {
    method: "GET",
    headers: { Accept: "application/json" },
  });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

class FastItunesService {
  private readonly baseURL = "https://itunes.apple.com/search";
  private coverCache = new Map<string, string>();

  async getAlbumCover(artist: string, track: string): Promise<string | null> {
    const cacheKey = `${artist.toLowerCase()}-${track.toLowerCase()}`;

    if (this.coverCache.has(cacheKey)) {
      return this.coverCache.get(cacheKey)!;
    }

    try {
      const cleanArtist = this.cleanTerm(artist);
      const cleanTrack = this.cleanTerm(track);
      const searchQuery = encodeURIComponent(`${cleanArtist} ${cleanTrack}`);
      const url = `${this.baseURL}?term=${searchQuery}&media=music&entity=song&limit=3`;

      const data = await nativeFetch(url);

      if (data.results && data.results.length > 0) {
        const result = data.results.find((t) => t.artworkUrl100);
        if (result) {
          const highQualityArtwork = result.artworkUrl100.replace(
            "100x100bb",
            "600x600bb"
          );
          this.coverCache.set(cacheKey, highQualityArtwork);
          return highQualityArtwork;
        }
      }

      return null;
    } catch (error) {
      console.error(`Failed to fetch cover for ${artist} - ${track}:`, error);
      return null;
    }
  }

  async loadCoversBatch(
    requests: Array<{ artist: string; track: string }>,
    maxConcurrent = 3
  ): Promise<Map<string, string>> {
    const results = new Map<string, string>();

    for (let i = 0; i < requests.length; i += maxConcurrent) {
      const batch = requests.slice(i, i + maxConcurrent);

      await Promise.all(
        batch.map(async (req) => {
          const cover = await this.getAlbumCover(req.artist, req.track);
          if (cover) {
            results.set(
              `${req.artist.toLowerCase()}-${req.track.toLowerCase()}`,
              cover
            );
          }
        })
      );
    }

    return results;
  }

  private cleanTerm(term: string): string {
    return term
      .replace(/\([^)]*\)/g, "")
      .replace(/\[[^\]]*]/g, "")
      .replace(/\{[^}]*\}/g, "")
      .replace(/feat\..+$/i, "")
      .replace(/ft\..+$/i, "")
      .trim();
  }
}

export const itunesService = new FastItunesService();