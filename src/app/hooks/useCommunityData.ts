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

export function useCommunityData(): CommunityDataState {
  const [state, setState] = useState<CommunityDataState>({
    data: mockCommunityData,
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
        data: mockCommunityData,
        source: 'mock',
        isLoading: false,
      }));
    }
  }, []);

  useEffect(() => {
    let isMounted = true;

    getCommunityData().then((result) => {
      if (!isMounted) {
        return;
      }

      setState((current) => ({
        ...current,
        data: result.data,
        source: result.source,
        isLoading: false,
      }));
    }).catch(() => {
      if (!isMounted) {
        return;
      }

      setState((current) => ({
        ...current,
        data: mockCommunityData,
        source: 'mock',
        isLoading: false,
      }));
    });

    return () => {
      isMounted = false;
    };
  }, []);

  return {
    ...state,
    refetch: loadCommunityData,
  };
}
