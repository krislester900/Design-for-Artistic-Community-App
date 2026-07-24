import { Capacitor } from "@capacitor/core";

interface iTunesSearchResult {
  results: iTunesTrack[];
}

interface iTunesTrack {
  trackId: number;
  artistName: string;
  trackName: string;
  artworkUrl100: string;
}

const ITUNES_BASE = "https://itunes.apple.com/search";

// Direct fetch — works in Capacitor WebView (no CORS) and most browsers
async function directFetch(url: string): Promise<iTunesSearchResult> {
  const res = await fetch(url, {
    method: "GET",
    headers: { Accept: "application/json" },
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// CORS proxy fallback for sandboxed browser environments
// allorigins proxies the request server-side and adds CORS headers
async function proxiedFetch(url: string): Promise<iTunesSearchResult> {
  const proxyUrl = `https://api.allorigins.win/raw?url=${encodeURIComponent(url)}`;
  const res = await fetch(proxyUrl);
  if (!res.ok) throw new Error(`Proxy HTTP ${res.status}`);
  return res.json();
}

const isNative = Capacitor.isNativePlatform();

async function itunesFetch(url: string): Promise<iTunesSearchResult> {
  if (isNative) {
    return directFetch(url);
  }
  try {
    return await directFetch(url);
  } catch {
    return proxiedFetch(url);
  }
}

class FastItunesService {
  private coverCache = new Map<string, string>();

  async getAlbumCover(artist: string, track: string): Promise<string | null> {
    const cacheKey = `${artist.toLowerCase()}-${track.toLowerCase()}`;

    if (this.coverCache.has(cacheKey)) {
      return this.coverCache.get(cacheKey)!;
    }

    try {
      const query = encodeURIComponent(
        `${this.cleanTerm(artist)} ${this.cleanTerm(track)}`
      );
      const url = `${ITUNES_BASE}?term=${query}&media=music&entity=song&limit=3`;

      const data = await itunesFetch(url);

      if (data.results?.length > 0) {
        const result = data.results.find((t) => t.artworkUrl100);
        if (result) {
          const hq = result.artworkUrl100.replace("100x100bb", "600x600bb");
          this.coverCache.set(cacheKey, hq);
          return hq;
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
      if (i + maxConcurrent < requests.length) {
        await new Promise((r) => setTimeout(r, 100));
      }
    }

    return results;
  }

  private cleanTerm(term: string): string {
    return term
      .toLowerCase()
      .replace(/[^\w\s]/g, "")
      .replace(/\s+/g, " ")
      .trim();
  }

  clearCache(): void {
    this.coverCache.clear();
  }

  getCacheSize(): number {
    return this.coverCache.size;
  }
}

export const fastItunesService = new FastItunesService();
