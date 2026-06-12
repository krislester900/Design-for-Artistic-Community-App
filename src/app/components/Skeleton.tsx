import { cn } from "./ui/utils";

interface SkeletonProps {
  className?: string;
}

export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      className={cn(
        "animate-pulse rounded-xl bg-muted/50",
        className
      )}
    />
  );
}

export function SkeletonCard({ className }: SkeletonProps) {
  return (
    <div className={cn("overflow-hidden rounded-2xl border border-border bg-card/60", className)}>
      <Skeleton className="h-64 w-full rounded-none" />
      <div className="p-5 space-y-3">
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-6 w-3/4" />
        <Skeleton className="h-4 w-1/2" />
      </div>
    </div>
  );
}

export function SkeletonArtistCard() {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card/60">
      <Skeleton className="h-80 w-full rounded-none" />
      <div className="p-5 space-y-3">
        <Skeleton className="h-4 w-16" />
        <Skeleton className="h-6 w-2/3" />
        <Skeleton className="h-4 w-1/2" />
      </div>
    </div>
  );
}

export function SkeletonArtworkCard() {
  return (
    <div className="overflow-hidden rounded-2xl border border-border bg-card/60">
      <Skeleton className="h-64 w-full rounded-none" />
      <div className="p-5 space-y-3">
        <Skeleton className="h-4 w-20" />
        <Skeleton className="h-6 w-3/4" />
        <Skeleton className="h-4 w-1/3" />
      </div>
    </div>
  );
}