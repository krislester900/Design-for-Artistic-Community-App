import { useEffect, useState } from 'react';
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
}

export function useCommunityData(): CommunityDataState {
  const [state, setState] = useState<CommunityDataState>({
    data: mockCommunityData,
    source: 'mock',
    isLoading: true,
  });

  useEffect(() => {
    let isMounted = true;

    getCommunityData().then((result) => {
      if (!isMounted) {
        return;
      }

      setState({
        data: result.data,
        source: result.source,
        isLoading: false,
      });
    });

    return () => {
      isMounted = false;
    };
  }, []);

  return state;
}
