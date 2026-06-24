import { useQuery } from "@tanstack/react-query";
import {
  type CommunityData,
  mockCommunityData,
} from "../data/community";
import { getCommunityData } from "../services/community";

const COMMUNITY_DATA_KEY = ["community", "data"];

export function useCommunityDataQuery() {
  return useQuery<CommunityData, Error>({
    queryKey: COMMUNITY_DATA_KEY,
    queryFn: async () => {
      const result = await getCommunityData();
      return result.data;
    },
    initialData: mockCommunityData,
    staleTime: 60_000, // 1 minute
    refetchOnWindowFocus: false,
  });
}

export function useCommunityDataSource() {
  // We can derive the source from the query state, but since getCommunityData
  // returns it, we keep a lightweight helper here.
  return useQuery<"mock" | "supabase", Error>({
    queryKey: ["community", "source"],
    queryFn: async () => {
      const result = await getCommunityData();
      return result.source;
    },
    initialData: "mock",
    staleTime: 60_000,
    refetchOnWindowFocus: false,
  });
}
