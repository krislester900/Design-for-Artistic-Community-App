import { Hash, Lock, Plus, Users, UserPlus, MessageCircle, Search, ChevronDown, ChevronRight, Bell, BellOff } from "lucide-react";
import { useState, useMemo } from "react";
import type { ChatChannel, ChatGroup, UnreadCount, ChannelPreview, PresenceStatus } from "./chat-types";

type ChatSidebarProps = {
  channels: ChatChannel[];
  groups: ChatGroup[];
  activeChannelId: string | null;
  activeGroupId: string | null;
  onSelectChannel: (id: string) => void;
  onSelectGroup: (id: string) => void;
  onCreateChannel: () => void;
  onCreateGroup: () => void;
  onShowFriends: () => void;
  showFriends: boolean;
  unreadCounts?: UnreadCount[];
  channelPreviews?: ChannelPreview[];
  userPresence?: Record<string, PresenceStatus>;
  totalUnread?: number;
};

export function ChatSidebar({
  channels,
  groups,
  activeChannelId,
  activeGroupId,
  onSelectChannel,
  onSelectGroup,
  onCreateChannel,
  onCreateGroup,
  onShowFriends,
  showFriends,
  unreadCounts = [],
  channelPreviews = [],
  userPresence = {},
  totalUnread = 0,
}: ChatSidebarProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [showPublic, setShowPublic] = useState(true);
  const [showPrivate, setShowPrivate] = useState(true);
  const [showGroups, setShowGroups] = useState(true);
  const [mutedChannels, setMutedChannels] = useState<Set<string>>(new Set());

  const publicChannels = channels.filter((c) => c.type === "public");
  const privateChannels = channels.filter((c) => c.type === "private");

  // Filter channels by search query
  const filteredPublic = useMemo(
    () => publicChannels.filter((c) => c.name.toLowerCase().includes(searchQuery.toLowerCase())),
    [publicChannels, searchQuery]
  );
  const filteredPrivate = useMemo(
    () => privateChannels.filter((c) => c.name.toLowerCase().includes(searchQuery.toLowerCase())),
    [privateChannels, searchQuery]
  );
  const filteredGroups = useMemo(
    () => groups.filter((g) => g.name.toLowerCase().includes(searchQuery.toLowerCase())),
    [groups, searchQuery]
  );

  function getUnreadCount(channelId: string): number {
    return unreadCounts.find((u) => u.channel_id === channelId)?.count || 0;
  }

  function getChannelPreview(channelId: string): ChannelPreview | undefined {
    return channelPreviews.find((p) => p.channel_id === channelId);
  }

  function toggleMute(channelId: string, e: React.MouseEvent) {
    e.stopPropagation();
    setMutedChannels((prev) => {
      const next = new Set(prev);
      if (next.has(channelId)) next.delete(channelId);
      else next.add(channelId);
      return next;
    });
  }

  return (
    <aside className="flex h-full w-72 flex-col border-r border-border/50 bg-gradient-to-b from-card/80 to-card/60 backdrop-blur-2xl">
      {/* Header */}
      <div className="flex items-center justify-between border-b border-border/50 px-4 py-4">
        <div className="flex items-center gap-2">
          <h2 className="text-sm font-bold uppercase tracking-[0.18em] bg-gradient-to-r from-primary to-primary/70 bg-clip-text text-transparent">
            Artéïa
          </h2>
          {totalUnread > 0 && (
            <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-red-500 px-1.5 text-[10px] font-bold text-white shadow-lg shadow-red-500/30">
              {totalUnread > 99 ? "99+" : totalUnread}
            </span>
          )}
        </div>
      </div>

      {/* Search */}
      <div className="px-3 py-3">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground/40" />
          <input
            className="w-full rounded-xl border border-border/30 bg-background/40 pl-9 pr-3 py-2 text-xs text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/40 focus:bg-background/60 transition-all"
            placeholder="Rechercher un salon, un groupe..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {/* Friends */}
      <button
        onClick={onShowFriends}
        className={`mx-3 mb-1 flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-all ${
          showFriends
            ? "bg-gradient-to-r from-primary/12 to-primary/5 text-primary shadow-sm"
            : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
        }`}
      >
        <MessageCircle className="h-4 w-4" />
        <span className="font-medium">Amis</span>
      </button>

      {/* Scrollable content */}
      <div className="flex-1 overflow-y-auto px-3 pb-4 scrollbar-thin scrollbar-thumb-border/30 scrollbar-track-transparent">
        {/* Public Channels */}
        <div className="mt-3">
          <button
            onClick={() => setShowPublic(!showPublic)}
            className="mb-1.5 flex w-full items-center justify-between group/section"
          >
            <div className="flex items-center gap-1">
              {showPublic ? (
                <ChevronDown className="h-3 w-3 text-muted-foreground/50" />
              ) : (
                <ChevronRight className="h-3 w-3 text-muted-foreground/50" />
              )}
              <span className="text-[10px] font-semibold uppercase tracking-[0.2em] text-muted-foreground/60">
                Salons
              </span>
              {filteredPublic.length > 0 && (
                <span className="text-[10px] text-muted-foreground/30">({filteredPublic.length})</span>
              )}
            </div>
            <button
              onClick={(e) => { e.stopPropagation(); onCreateChannel(); }}
              className="flex h-5 w-5 items-center justify-center rounded-md text-muted-foreground/50 transition-colors hover:bg-card/40 hover:text-primary opacity-0 group-hover/section:opacity-100"
              title="Créer un salon"
            >
              <Plus className="h-3.5 w-3.5" />
            </button>
          </button>

          {showPublic && (
            <div className="space-y-0.5">
              {filteredPublic.length === 0 && searchQuery && (
                <p className="px-3 py-2 text-[11px] text-muted-foreground/40 italic">Aucun résultat</p>
              )}
              {filteredPublic.map((channel) => {
                const unread = getUnreadCount(channel.id);
                const preview = getChannelPreview(channel.id);
                const isMuted = mutedChannels.has(channel.id);
                return (
                  <button
                    key={channel.id}
                    onClick={() => onSelectChannel(channel.id)}
                    className={`group flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm transition-all ${
                      activeChannelId === channel.id && !showFriends
                        ? "bg-gradient-to-r from-primary/12 to-primary/5 text-primary shadow-sm"
                        : unread > 0
                          ? "text-foreground font-medium hover:bg-card/40"
                          : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
                    }`}
                  >
                    <Hash className={`h-4 w-4 shrink-0 ${unread > 0 ? "text-primary" : ""}`} />
                    <div className="min-w-0 flex-1 text-left">
                      <div className="flex items-center gap-1.5">
                        <span className={`truncate ${unread > 0 ? "font-semibold" : ""}`}>
                          {channel.name}
                        </span>
                        {channel.is_locked && (
                          <Lock className="h-3 w-3 shrink-0 text-muted-foreground/40" />
                        )}
                      </div>
                      {preview && (
                        <p className="truncate text-[11px] text-muted-foreground/40 mt-0.5">
                          {preview.last_author && <span className="text-muted-foreground/50">{preview.last_author.split("@")[0]}: </span>}
                          {preview.last_message}
                        </p>
                      )}
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                      {isMuted ? (
                        <BellOff className="h-3 w-3 text-muted-foreground/30" />
                      ) : (
                        <button
                          onClick={(e) => toggleMute(channel.id, e)}
                          className="opacity-0 group-hover:opacity-100 transition-opacity"
                        >
                          <Bell className="h-3 w-3 text-muted-foreground/30 hover:text-primary" />
                        </button>
                      )}
                      {unread > 0 && !isMuted && (
                        <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-bold text-primary-foreground shadow-md shadow-primary/20">
                          {unread > 99 ? "99+" : unread}
                        </span>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* Private Channels */}
        {filteredPrivate.length > 0 && (
          <div className="mt-4">
            <button
              onClick={() => setShowPrivate(!showPrivate)}
              className="mb-1.5 flex w-full items-center justify-between group/section"
            >
              <div className="flex items-center gap-1">
                {showPrivate ? (
                  <ChevronDown className="h-3 w-3 text-muted-foreground/50" />
                ) : (
                  <ChevronRight className="h-3 w-3 text-muted-foreground/50" />
                )}
                <span className="text-[10px] font-semibold uppercase tracking-[0.2em] text-muted-foreground/60">
                  Privés
                </span>
              </div>
            </button>

            {showPrivate && (
              <div className="space-y-0.5">
                {filteredPrivate.map((channel) => {
                  const unread = getUnreadCount(channel.id);
                  const preview = getChannelPreview(channel.id);
                  return (
                    <button
                      key={channel.id}
                      onClick={() => onSelectChannel(channel.id)}
                      className={`flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm transition-all ${
                        activeChannelId === channel.id && !showFriends
                          ? "bg-gradient-to-r from-primary/12 to-primary/5 text-primary shadow-sm"
                          : unread > 0
                            ? "text-foreground font-medium hover:bg-card/40"
                            : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
                      }`}
                    >
                      <Lock className={`h-4 w-4 shrink-0 ${unread > 0 ? "text-primary" : ""}`} />
                      <div className="min-w-0 flex-1 text-left">
                        <span className={`truncate block ${unread > 0 ? "font-semibold" : ""}`}>
                          {channel.name}
                        </span>
                        {preview && (
                          <p className="truncate text-[11px] text-muted-foreground/40 mt-0.5">
                            {preview.last_message}
                          </p>
                        )}
                      </div>
                      {unread > 0 && (
                        <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary px-1.5 text-[10px] font-bold text-primary-foreground shadow-md shadow-primary/20">
                          {unread > 99 ? "99+" : unread}
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Groups */}
        <div className="mt-4">
          <button
            onClick={() => setShowGroups(!showGroups)}
            className="mb-1.5 flex w-full items-center justify-between group/section"
          >
            <div className="flex items-center gap-1">
              {showGroups ? (
                <ChevronDown className="h-3 w-3 text-muted-foreground/50" />
              ) : (
                <ChevronRight className="h-3 w-3 text-muted-foreground/50" />
              )}
              <span className="text-[10px] font-semibold uppercase tracking-[0.2em] text-muted-foreground/60">
                Groupes
              </span>
              {filteredGroups.length > 0 && (
                <span className="text-[10px] text-muted-foreground/30">({filteredGroups.length})</span>
              )}
            </div>
            <button
              onClick={(e) => { e.stopPropagation(); onCreateGroup(); }}
              className="flex h-5 w-5 items-center justify-center rounded-md text-muted-foreground/50 transition-colors hover:bg-card/40 hover:text-primary opacity-0 group-hover/section:opacity-100"
              title="Créer un groupe"
            >
              <UserPlus className="h-3.5 w-3.5" />
            </button>
          </button>

          {showGroups && (
            <div className="space-y-0.5">
              {filteredGroups.length === 0 ? (
                <p className="px-3 py-2 text-[11px] text-muted-foreground/40 italic">
                  {searchQuery ? "Aucun résultat" : "Aucun groupe"}
                </p>
              ) : (
                filteredGroups.map((group) => (
                  <button
                    key={group.id}
                    onClick={() => onSelectGroup(group.id)}
                    className={`flex w-full items-center gap-2.5 rounded-xl px-3 py-2 text-sm transition-all ${
                      activeGroupId === group.id && !showFriends
                        ? "bg-gradient-to-r from-primary/12 to-primary/5 text-primary shadow-sm"
                        : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
                    }`}
                  >
                    <Users className="h-4 w-4 shrink-0" />
                    <span className="truncate">{group.name}</span>
                  </button>
                ))
              )}
            </div>
          )}
        </div>
      </div>

      {/* Footer stats */}
      <div className="border-t border-border/50 px-4 py-3">
        <div className="flex items-center justify-between">
          <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground/40">
            {channels.length} salons · {groups.length} groupes
          </p>
          <div className="flex items-center gap-1">
            <div className="h-2 w-2 rounded-full bg-green-500 shadow-sm shadow-green-500/30" />
            <span className="text-[10px] text-muted-foreground/40">En ligne</span>
          </div>
        </div>
      </div>
    </aside>
  );
}