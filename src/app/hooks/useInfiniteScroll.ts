import { useState, useEffect, useRef, useCallback } from "react";

interface UseInfiniteScrollOptions {
  threshold?: number;
  rootMargin?: string;
}

export function useInfiniteScroll(
  onLoadMore: () => void | Promise<void>,
  hasMore: boolean,
  options: UseInfiniteScrollOptions = {}
) {
  const { threshold = 0, rootMargin = "200px" } = options;
  const [loading, setLoading] = useState(false);
  const observerRef = useRef<IntersectionObserver | null>(null);
  const sentinelRef = useCallback(
    (node: HTMLElement | null) => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }
      if (!node || !hasMore) return;

      observerRef.current = new IntersectionObserver(
        async (entries) => {
          if (entries[0].isIntersecting && !loading && hasMore) {
            setLoading(true);
            await onLoadMore();
            setLoading(false);
          }
        },
        { threshold, rootMargin }
      );

      observerRef.current.observe(node);
    },
    [hasMore, loading, onLoadMore, threshold, rootMargin]
  );

  useEffect(() => {
    return () => {
      if (observerRef.current) {
        observerRef.current.disconnect();
      }
    };
  }, []);

  return { sentinelRef, loading };
}

export function usePaginatedData<T>(
  allData: T[],
  pageSize = 12
) {
  const [visibleCount, setVisibleCount] = useState(pageSize);
  const visibleItems = allData.slice(0, visibleCount);
  const hasMore = visibleCount < allData.length;

  const loadMore = useCallback(() => {
    setVisibleCount((prev) => Math.min(prev + pageSize, allData.length));
  }, [pageSize, allData.length]);

  const reset = useCallback(() => {
    setVisibleCount(pageSize);
  }, [pageSize]);

  useEffect(() => {
    reset();
  }, [allData.length, reset]);

  return { visibleItems, hasMore, loadMore, reset };
}