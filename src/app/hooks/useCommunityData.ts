import { useCallback, useEffect, useState } from 'react';
import {
  type CommunityData,
  type CommunityDataSource,
  mockCommunityData,
} from '../data/community';
import { getCommunityData } from '../services/community';

interface CommunityDataState {
  data: CommunityData;
  source: CommunityDataSource;
  isLoading: boolean;
  refetch: () => Promise<void>;
}

const emptyData: CommunityData = {
  categories: [],
  artists: [],
  artworks: [],
  discussions: [],
  trends: [],
  events: [],
  communityStats: [],
};

export function useCommunityData(): CommunityDataState {
  const [state, setState] = useState<CommunityDataState>({
    data: emptyData,
    source: 'mock',
    isLoading: true,
    refetch: async () => {},
  });

  const loadCommunityData = useCallback(async () => {
    setState((current) => ({
      ...current,
      isLoading: true,
    }));

    try {
      const result = await getCommunityData();
      setState((current) => ({
        ...current,
        data: result.data,
        source: result.source,
        isLoading: false,
      }));
    } catch {
      setState((current) => ({
        ...current,
        data: emptyData,
        source: 'mock',
        isLoading: false,
      }));
    }
  }, []);

  useEffect(() => {
    loadCommunityData();
  }, [loadCommunityData]);

  return {
    ...state,
    refetch: loadCommunityData,
  };
}
