import {
  type Artist,
  type Artwork,
  type Category,
  type CommunityData,
  type CommunityDataSource,
  type CommunityStat,
  type Discussion,
  type EventItem,
  type Trend,
  mockCommunityData,
} from "../data/community";
import { hasSupabaseEnv, supabase } from "../lib/supabase";

function sortCategories(items: Category[]) {
  return [...items].sort((a, b) => a.title.localeCompare(b.title, "fr"));
}

function sortArtists(items: Artist[]) {
  return [...items].sort((a, b) => b.likes - a.likes);
}

function sortArtworks(items: Artwork[]) {
  return [...items].sort((a, b) => b.views - a.views);
}

function sortDiscussions(items: Discussion[]) {
  return [...items].sort(
    (a, b) => Number(b.trending) - Number(a.trending) || b.replies - a.replies,
  );
}

function sortStats(items: CommunityStat[]) {
  return [...items].sort((a, b) => a.label.localeCompare(b.label, "fr"));
}

function getMockData(): CommunityData {
  return {
    categories: sortCategories(mockCommunityData.categories),
    artists: sortArtists(mockCommunityData.artists),
    artworks: sortArtworks(mockCommunityData.artworks),
    discussions: sortDiscussions(mockCommunityData.discussions),
    trends: [...mockCommunityData.trends],
    events: [...mockCommunityData.events],
    communityStats: sortStats(mockCommunityData.communityStats),
  };
}

export async function getCommunityData(): Promise<{
  source: CommunityDataSource;
  data: CommunityData;
}> {
  if (!hasSupabaseEnv || !supabase) {
    return { source: "mock", data: getMockData() };
  }

  try {
    const queries = [
      supabase
        .from("categories")
        .select(
          "slug, name, short_label, description, icon, color, target_section_id",
        )
        .order("sort_order", { ascending: true }),
      supabase
        .from("artists")
        .select("name, category_slug, role, image, featured_work, likes")
        .order("likes", { ascending: false }),
      supabase
        .from("artworks")
        .select(
          "image, title, artist_name, category_slug, medium, likes, views, height",
        )
        .order("views", { ascending: false }),
      supabase
        .from("forum_discussions")
        .select(
          "title, author_name, category_slug, replies, time_label, trending",
        )
        .order("trending", { ascending: false })
        .order("replies", { ascending: false }),
      supabase
        .from("trend_tags")
        .select("tag, count_label, category_slug")
        .order("sort_order", { ascending: true }),
      supabase
        .from("community_events")
        .select("title, date_label, category_slug")
        .order("sort_order", { ascending: true }),
      supabase
        .from("community_stats")
        .select("number_label, label")
        .order("sort_order", { ascending: true }),
    ];

    const results = await Promise.allSettled(queries);

    for (const r of results) {
      if (r.status === "rejected") {
        console.warn("Supabase query rejected:", r.reason);
      } else if (r.value.error) {
        console.warn("Supabase query error:", r.value.error);
      }
    }

    const fulfilled = results.map((r) =>
      r.status === "fulfilled" ? r.value : { data: null, error: null }
    );

    const [
      categoriesResult,
      artistsResult,
      artworksResult,
      discussionsResult,
      trendsResult,
      eventsResult,
      statsResult,
    ] = fulfilled;

    return {
      source: "supabase",
      data: {
        categories:
          (categoriesResult.data ?? []).length > 0
            ? (categoriesResult.data ?? []).map((item) => ({
                slug: item.slug,
                name: item.name,
                shortLabel: item.short_label,
                description: item.description,
                icon: item.icon,
                color: item.color,
                targetSectionId: item.target_section_id,
              }))
            : mockCommunityData.categories,
        artists: (artistsResult.data ?? []).map((item) => ({
          name: item.name,
          category: item.category_slug,
          role: item.role,
          image: item.image,
          featuredWork: item.featured_work,
          likes: item.likes,
        })),
        artworks: (artworksResult.data ?? []).map((item) => ({
          image: item.image,
          title: item.title,
          artist: item.artist_name,
          category: item.category_slug,
          medium: item.medium,
          likes: item.likes,
          views: item.views,
          height: item.height,
        })),
        discussions: (discussionsResult.data ?? []).map((item) => ({
          title: item.title,
          author: item.author_name,
          category: item.category_slug,
          replies: item.replies,
          time: item.time_label,
          trending: item.trending,
        })),
        trends: (trendsResult.data ?? []).map((item) => ({
          tag: item.tag,
          count: item.count_label,
          category: item.category_slug,
        })),
        events: (eventsResult.data ?? []).map((item) => ({
          title: item.title,
          date: item.date_label,
          category: item.category_slug,
        })),
        communityStats:
          (statsResult.data ?? []).length > 0
            ? (statsResult.data ?? []).map((item) => ({
                number: item.number_label,
                label: item.label,
              }))
            : mockCommunityData.communityStats,
      },
    };
  } catch (error) {
    console.error("Supabase unavailable, fallback to mock data:", error);
    return { source: "mock", data: getMockData() };
  }
}
