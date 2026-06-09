import { MessageCircle, TrendingUp, Clock, CalendarDays } from "lucide-react";
import {
  getCategoryLabel,
  isCategoryMatch,
  type CategorySlug,
  type Discussion,
  type EventItem,
  type SectionId,
  type Trend,
} from "../data/community";

interface CommunityFeedProps {
  discussions: Discussion[];
  trends: Trend[];
  events: EventItem[];
  selectedCategory: CategorySlug;
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}

export function CommunityFeed({
  discussions,
  trends,
  events,
  selectedCategory,
  onNavigate,
}: CommunityFeedProps) {
  const filteredDiscussions = discussions.filter((discussion) =>
    isCategoryMatch(selectedCategory, discussion.category),
  );
  const filteredTrends = trends.filter((trend) =>
    isCategoryMatch(selectedCategory, trend.category),
  );
  const filteredEvents = events.filter((event) =>
    isCategoryMatch(selectedCategory, event.category),
  );

  return (
    <section id="forum" className="px-6 py-20 scroll-mt-28">
      <div className="mx-auto max-w-7xl">
        <div className="mb-12 flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="mb-2 text-4xl font-display italic md:text-5xl">
              Le forum créatif
            </h2>
            <p className="font-accent italic text-muted-foreground">
              {selectedCategory === "all"
                ? "Échangez, apprenez et grandissez ensemble."
                : `Sujets et tendances reliés à l'univers ${getCategoryLabel(selectedCategory).toLowerCase()}.`}
            </p>
          </div>
          <button
            className="rounded-lg bg-primary px-6 py-3 text-primary-foreground transition-opacity hover:opacity-90"
            onClick={() => onNavigate("join", selectedCategory)}
          >
            Créer un sujet
          </button>
        </div>

        <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
          <div className="space-y-4 lg:col-span-2">
            {filteredDiscussions.map((discussion) => (
              <DiscussionCard
                key={discussion.title}
                {...discussion}
                onNavigate={onNavigate}
              />
            ))}
          </div>

          <div className="space-y-6">
            <div className="rounded-xl border border-border bg-card p-6">
              <h3 className="mb-4 text-xl font-display">Tendances du moment</h3>
              <div className="space-y-3">
                {filteredTrends.map((trend) => (
                  <TrendTag
                    key={trend.tag}
                    {...trend}
                    onNavigate={onNavigate}
                  />
                ))}
              </div>
            </div>

            <div className="rounded-xl border border-border bg-card p-6">
              <h3 className="mb-4 text-xl font-display">Événements à venir</h3>
              <div className="space-y-4">
                {filteredEvents.map((event) => (
                  <EventCard
                    key={event.title}
                    {...event}
                    onNavigate={onNavigate}
                  />
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function DiscussionCard({
  title,
  author,
  category,
  replies,
  time,
  trending,
  onNavigate,
}: Discussion & {
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}) {
  return (
    <button
      className="group w-full cursor-pointer rounded-xl border border-border bg-card p-6 text-left transition-all hover:border-primary/50 hover:bg-card/80"
      onClick={() => onNavigate("showcase", category)}
    >
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1">
          <div className="mb-2 flex items-center gap-3">
            <span className="rounded-full border border-secondary/30 bg-secondary/20 px-3 py-1 text-xs text-secondary-foreground">
              {getCategoryLabel(category)}
            </span>
            {trending && (
              <span className="flex items-center gap-1 text-xs text-primary">
                <TrendingUp className="h-3 w-3" />
                Tendance
              </span>
            )}
          </div>

          <h3 className="mb-2 text-lg font-medium transition-colors group-hover:text-primary">
            {title}
          </h3>

          <div className="flex items-center gap-4 text-sm text-muted-foreground">
            <span>Par {author}</span>
            <span className="flex items-center gap-1">
              <Clock className="h-3 w-3" />
              {time}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 text-muted-foreground">
          <MessageCircle className="h-5 w-5" />
          <span className="font-medium">{replies}</span>
        </div>
      </div>
    </button>
  );
}

function TrendTag({
  tag,
  count,
  category,
  onNavigate,
}: Trend & {
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}) {
  return (
    <button
      className="flex w-full items-center justify-between rounded-lg p-3 text-left transition-colors hover:bg-muted"
      onClick={() => onNavigate("showcase", category)}
    >
      <span className="font-medium text-primary">{tag}</span>
      <span className="text-sm text-muted-foreground">{count} posts</span>
    </button>
  );
}

function EventCard({
  title,
  date,
  category,
  onNavigate,
}: EventItem & {
  onNavigate: (sectionId: SectionId, category?: CategorySlug) => void;
}) {
  return (
    <button
      className="w-full rounded-lg border border-border p-3 text-left transition-colors hover:border-primary/50"
      onClick={() => onNavigate("join", category)}
    >
      <div className="mb-1 flex items-center gap-2 text-primary">
        <CalendarDays className="h-4 w-4" />
        <span className="text-xs uppercase tracking-[0.2em]">
          {getCategoryLabel(category)}
        </span>
      </div>
      <p className="mb-1 text-sm font-medium">{title}</p>
      <p className="text-xs text-muted-foreground">{date}</p>
    </button>
  );
}
