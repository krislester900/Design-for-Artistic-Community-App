import { useState, useRef, useEffect } from 'react';

interface ImageWithFallbackProps extends React.ImgHTMLAttributes<HTMLImageElement> {
  src: string;
  alt: string;
  fallbackSrc?: string;
  lazy?: boolean;
}

function useIntersectionObserver(ref: React.RefObject<HTMLElement | null>) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    // If IntersectionObserver not supported, load immediately
    if (typeof IntersectionObserver === 'undefined') {
      setIsVisible(true);
      return;
    }

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          observer.disconnect();
        }
      },
      { rootMargin: '200px' }
    );

    observer.observe(el);
    return () => observer.disconnect();
  }, [ref]);

  return isVisible;
}

export function ImageWithFallback({
  src,
  alt,
  fallbackSrc = 'data:image/svg+xml,%3Csvg xmlns="http://www.w3.org/2000/svg" width="400" height="300"%3E%3Crect fill="%23dddddd" width="400" height="300"/%3E%3C/svg%3E',
  lazy = true,
  className = '',
  ...props
}: ImageWithFallbackProps) {
  const [imgSrc, setImgSrc] = useState(lazy ? '' : src);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState(false);
  const imgRef = useRef<HTMLImageElement>(null);
  const isVisible = useIntersectionObserver(imgRef);

  useEffect(() => {
    if (isVisible && lazy && !imgSrc) {
      setImgSrc(src);
    }
  }, [isVisible, lazy, imgSrc, src]);

  // Reset if src changes
  useEffect(() => {
    setImgSrc(lazy ? '' : src);
    setLoaded(false);
    setError(false);
  }, [src, lazy]);

  return (
    <div
      ref={imgRef as React.RefObject<HTMLDivElement>}
      className={`relative overflow-hidden ${className}`}
      style={{ backgroundColor: error ? '#ddd' : 'transparent' }}
    >
      {!loaded && !error && (
        <div className="absolute inset-0 animate-pulse bg-gray-800/20" />
      )}
      {imgSrc && (
        <img
          {...props}
          src={imgSrc}
          alt={alt}
          loading="lazy"
          className={`w-full h-full object-cover transition-opacity duration-300 ${loaded ? 'opacity-100' : 'opacity-0'}`}
          onLoad={() => setLoaded(true)}
          onError={() => {
            setError(true);
            setImgSrc(fallbackSrc);
          }}
        />
      )}
    </div>
  );
}
