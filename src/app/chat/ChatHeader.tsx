import { Hash, Lock, Users, LogOut, Search, Pin, Settings, MoreVertical, X } from "lucide-react";
import { useState } from "react";
import type { ChatChannel, ChatChannelMember, PresenceStatus } from "./chat-types";

type ChatHeaderProps = {
  channel: ChatChannel | null;
  members: ChatChannelMember[];
  currentUserId: string | null;
  onShowMembers: () => void;
  onLeaveChannel: () => void;
  showMembers: boolean;
  userPresence?: Record<string, PresenceStatus>;
  pinnedCount?: number;
  onSearch?: (query: string) => void;
};

export function ChatHeader({
  channel,
  members,
  currentUserId,
  onShowMembers,
  onLeaveChannel,
  showMembers,
  userPresence = {},
  pinnedCount = 0,
  onSearch,
}: ChatHeaderProps) {
  const [showSearch, setShowSearch] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  if (!channel) return null;

  const isOwner = members.some(
    (m) => m.user_id === currentUserId && m.role === "owner",
  );
  const isMember = members.some((m) => m.user_id === currentUserId);

  const onlineCount = members.filter(
    (m) => userPresence[m.user_id] === "online"
  ).length;

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    onSearch?.(searchQuery);
  }

  return (
    <div className="flex items-center justify-between border-b border-border/50 bg-gradient-to-r from-card/40 to-card/20 px-6 py-3 backdrop-blur-xl">
      <div className="flex items-center gap-3">
        {/* Channel icon with gradient */}
        <div className={`flex h-9 w-9 items-center justify-center rounded-xl ${
          channel.type === "private"
            ? "bg-gradient-to-br from-amber-500/20 to-amber-500/5 text-amber-500"
            : "bg-gradient-to-br from-primary/15 to-primary/5 text-primary"
        }`}>
          {channel.type === "private" ? (
            <Lock className="h-4 w-4" />
          ) : (
            <Hash className="h-4 w-4" />
          )}
        </div>
        <div>
          <h2 className="text-sm font-semibold text-foreground">
            {channel.name}
          </h2>
          {channel.description && (
            <p className="text-[11px] text-muted-foreground/50 max-w-xs truncate">
              {channel.description}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center gap-1">
        {/* Search toggle */}
        {onSearch && (
          <button
            onClick={() => setShowSearch(!showSearch)}
            className={`flex items-center gap-1.5 rounded-xl px-2.5 py-1.5 text-xs transition-all ${
              showSearch
                ? "bg-primary/12 text-primary"
                : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
            }`}
            title="Rechercher"
          >
            <Search className="h-3.5 w-3.5" />
          </button>
        )}

        {/* Pinned messages */}
        {pinnedCount > 0 && (
          <button
            className="flex items-center gap-1.5 rounded-xl px-2.5 py-1.5 text-xs text-muted-foreground hover:bg-card/40 hover:text-amber-500 transition-all"
            title={`${pinnedCount} message(s) épinglé(s)`}
          >
            <Pin className="h-3.5 w-3.5" />
            <span>{pinnedCount}</span>
          </button>
        )}

        {/* Members toggle */}
        <button
          onClick={onShowMembers}
          className={`flex items-center gap-1.5 rounded-xl px-2.5 py-1.5 text-xs transition-all ${
            showMembers
              ? "bg-primary/12 text-primary"
              : "text-muted-foreground hover:bg-card/40 hover:text-foreground"
          }`}
        >
          <Users className="h-3.5 w-3.5" />
          <span>{members.length}</span>
          {onlineCount > 0 && (
            <span className="flex h-1.5 w-1.5 rounded-full bg-green-500 shadow-sm shadow-green-500/30" />
          )}
        </button>

        {/* Leave channel */}
        {isMember && !isOwner && (
          <button
            onClick={onLeaveChannel}
            className="flex items-center gap-1.5 rounded-xl px-2.5 py-1.5 text-xs text-muted-foreground transition-all hover:bg-red-500/10 hover:text-red-400"
          >
            <LogOut className="h-3.5 w-3.5" />
            <span>Quitter</span>
          </button>
        )}
      </div>

      {/* Search bar (expandable) */}
      {showSearch && (
        <div className="absolute top-full left-0 right-0 z-40 border-b border-border/50 bg-card/95 px-6 py-3 backdrop-blur-xl">
          <form onSubmit={handleSearch} className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-3.5 w-3.5 -translate-y-1/2 text-muted-foreground/40" />
              <input
                className="w-full rounded-xl border border-border/30 bg-background/40 pl-9 pr-3 py-2 text-sm text-foreground outline-none placeholder:text-muted-foreground/30 focus:border-primary/40"
                placeholder="Rechercher dans les messages..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                autoFocus
              />
            </div>
            <button
              type="button"
              onClick={() => { setShowSearch(false); setSearchQuery(""); }}
              className="flex h-8 w-8 items-center justify-center rounded-xl text-muted-foreground hover:bg-card/40 hover:text-foreground transition-colors"
            >
              <X className="h-4 w-4" />
            </button>
          </form>
        </div>
      )}
    </div>
  );
}