import { useState, useEffect, useCallback } from "react";
import {
  MessageSquare,
  Bell,
  Hash,
  Search,
  CheckCheck,
  Mail,
  MailOpen,
  Loader2,
  Send,
  User,
  Users,
  Clock,
  ChevronRight,
  Inbox,
} from "lucide-react";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "../components/ui/tabs";
import { Badge } from "../components/ui/badge";
import { Skeleton } from "../components/Skeleton";
import * as InboxService from "../services/inbox";
import type { DMConversation, ChannelWithUnread } from "../services/inbox";
import type { Notification } from "../services/notifications";

type Props = {
  onNavigate?: (page: string) => void;
};

function formatRelativeTime(dateStr: string | null): string {
  if (!dateStr) return "";
  const now = Date.now();
  const date = new Date(dateStr).getTime();
  const diffMs = now - date;
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return "à l'instant";
  if (diffMin < 60) return `il y a ${diffMin}min`;
  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `il y a ${diffH}h`;
  const diffD = Math.floor(diffH / 24);
  if (diffD < 7) return `il y a ${diffD}j`;
  return new Date(dateStr).toLocaleDateString("fr-FR");
}

function getInitials(email: string): string {
  return email.charAt(0).toUpperCase();
}

export function InboxPage({ onNavigate }: Props) {
  const [activeTab, setActiveTab] = useState("messages");
  const [loading, setLoading] = useState(true);

  // Messages tab
  const [conversations, setConversations] = useState<DMConversation[]>([]);
  const [convSearch, setConvSearch] = useState("");

  // Channels tab
  const [channels, setChannels] = useState<ChannelWithUnread[]>([]);

  // Notifications tab
  const [notifData, setNotifData] = useState<{
    notifications: Notification[];
    unread_count: number;
  }>({ notifications: [], unread_count: 0 });

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [convos, chs, notifs] = await Promise.all([
        InboxService.getDMConversations(),
        InboxService.getChannelsWithUnread(),
        InboxService.getNotificationsWithCount(),
      ]);
      setConversations(convos);
      setChannels(chs);
      setNotifData(notifs);
    } catch (err) {
      console.error("Failed to load inbox:", err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { loadData(); }, [loadData]);

  const handleMarkAllRead = useCallback(async () => {
    await InboxService.markAllNotificationsRead();
    setNotifData((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) => ({ ...n, is_read: true })),
      unread_count: 0,
    }));
  }, []);

  const handleMarkRead = useCallback(async (id: string) => {
    await InboxService.markNotificationRead(id);
    setNotifData((prev) => ({
      ...prev,
      notifications: prev.notifications.map((n) =>
        n.id === id ? { ...n, is_read: true } : n,
      ),
      unread_count: Math.max(0, prev.unread_count - 1),
    }));
  }, []);

  const filteredConversations = conversations.filter((c) =>
    c.other_email.toLowerCase().includes(convSearch.toLowerCase()),
  );

  const LoadingSkeleton = () => (
    <div className="space-y-3">
      {Array.from({ length: 5 }).map((_, i) => (
        <Skeleton key={i} className="h-20 rounded-xl" />
      ))}
    </div>
  );

  return (
    <div className="mx-auto max-w-4xl px-4 py-8">
      {/* Header */}
      <div className="mb-8 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 to-indigo-500 shadow-lg">
            <Inbox className="h-5 w-5 text-white" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-foreground">Boîte de réception</h1>
            <p className="text-sm text-muted-foreground">
              Messages, canaux et notifications
            </p>
          </div>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="mb-6">
          <TabsTrigger value="messages" className="relative">
            <MessageSquare className="h-4 w-4" />
            Messages
            {conversations.length > 0 && (
              <span className="ml-1.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-primary/15 px-1 text-[9px] font-bold text-primary">
                {conversations.length}
              </span>
            )}
          </TabsTrigger>
          <TabsTrigger value="channels">
            <Hash className="h-4 w-4" />
            Canaux
          </TabsTrigger>
          <TabsTrigger value="notifications" className="relative">
            <Bell className="h-4 w-4" />
            Alertes
            {notifData.unread_count > 0 && (
              <span className="ml-1.5 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-red-500 px-1 text-[9px] font-bold text-white">
                {notifData.unread_count > 9 ? "9+" : notifData.unread_count}
              </span>
            )}
          </TabsTrigger>
        </TabsList>

        {/* ═══════ MESSAGES ═══════ */}
        <TabsContent value="messages" className="space-y-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <input
              type="text"
              placeholder="Rechercher une conversation..."
              value={convSearch}
              onChange={(e) => setConvSearch(e.target.value)}
              className="w-full rounded-xl border border-border/50 bg-card/50 py-2.5 pl-10 pr-4 text-sm text-foreground outline-none transition-all focus:border-blue-500 focus:ring-1 focus:ring-blue-500/30"
            />
          </div>

          {loading ? (
            <LoadingSkeleton />
          ) : filteredConversations.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-16 text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-blue-500/10">
                <Send className="h-8 w-8 text-blue-500/40" />
              </div>
              <p className="text-sm font-medium text-foreground">
                {convSearch ? "Aucune conversation trouvée" : "Aucune conversation"}
              </p>
              <p className="text-xs text-muted-foreground">
                {convSearch ? "Essaie un autre terme" : "Rejoins des canaux ou ajoute des amis pour commencer"}
              </p>
            </div>
          ) : (
            <div className="space-y-1.5">
              {filteredConversations.map((conv) => (
                <button
                  key={conv.channel_id}
                  className="flex w-full items-center gap-4 rounded-xl border border-border/30 bg-card/50 p-4 text-left transition-all hover:border-blue-500/30 hover:shadow-md active:scale-[0.99]"
                >
                  <div className={`relative flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-blue-500 to-indigo-500 text-lg font-bold text-white`}>
                    {getInitials(conv.other_email)}
                    <span className={`absolute -bottom-0.5 -right-0.5 h-3.5 w-3.5 rounded-full border-2 border-background ${
                      conv.is_online ? "bg-emerald-500" : "bg-muted-foreground/40"
                    }`} />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-sm font-semibold text-foreground">
                        {conv.other_email}
                      </span>
                      <span className="shrink-0 text-[10px] text-muted-foreground">
                        {formatRelativeTime(conv.last_message_at)}
                      </span>
                    </div>
                    <p className="mt-0.5 truncate text-xs text-muted-foreground">
                      {conv.last_message ?? "Aucun message"}
                    </p>
                  </div>
                  <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground/30" />
                </button>
              ))}
            </div>
          )}
        </TabsContent>

        {/* ═══════ CHANNELS ═══════ */}
        <TabsContent value="channels" className="space-y-4">
          {loading ? (
            <LoadingSkeleton />
          ) : channels.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-16 text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-indigo-500/10">
                <Hash className="h-8 w-8 text-indigo-500/40" />
              </div>
              <p className="text-sm font-medium text-foreground">Aucun canal</p>
              <p className="text-xs text-muted-foreground">
                Les canaux apparaîtront ici une fois créés
              </p>
            </div>
          ) : (
            <div className="space-y-1.5">
              {channels.map((cw) => (
                <button
                  key={cw.channel.id}
                  className="flex w-full items-center gap-4 rounded-xl border border-border/30 bg-card/50 p-4 text-left transition-all hover:border-indigo-500/30 hover:shadow-md active:scale-[0.99]"
                >
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-indigo-500/10">
                    <Hash className="h-5 w-5 text-indigo-500" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-sm font-semibold text-foreground">
                        {cw.channel.name}
                      </span>
                      <div className="flex shrink-0 items-center gap-2">
                        {cw.unread_count > 0 && (
                          <span className="flex h-5 min-w-[20px] items-center justify-center rounded-full bg-primary/15 px-1.5 text-[9px] font-bold text-primary">
                            {cw.unread_count > 99 ? "99+" : cw.unread_count}
                          </span>
                        )}
                        <span className="text-[10px] text-muted-foreground">
                          {formatRelativeTime(cw.last_message_at ?? null)}
                        </span>
                      </div>
                    </div>
                    <p className="mt-0.5 truncate text-xs text-muted-foreground">
                      {(cw.last_message ?? cw.channel.description) || "Aucun message"}
                    </p>
                  </div>
                  <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground/30" />
                </button>
              ))}
            </div>
          )}
        </TabsContent>

        {/* ═══════ NOTIFICATIONS ═══════ */}
        <TabsContent value="notifications" className="space-y-4">
          {notifData.unread_count > 0 && (
            <button
              onClick={handleMarkAllRead}
              className="flex items-center gap-2 rounded-xl bg-primary/10 px-4 py-2.5 text-sm font-medium text-primary transition-colors hover:bg-primary/20"
            >
              <CheckCheck className="h-4 w-4" />
              Tout marquer comme lu ({notifData.unread_count})
            </button>
          )}

          {loading ? (
            <LoadingSkeleton />
          ) : notifData.notifications.length === 0 ? (
            <div className="flex flex-col items-center gap-3 py-16 text-center">
              <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-amber-500/10">
                <Bell className="h-8 w-8 text-amber-500/40" />
              </div>
              <p className="text-sm font-medium text-foreground">Aucune notification</p>
              <p className="text-xs text-muted-foreground">
                Tu es à jour ! Les notifications apparaîtront ici
              </p>
            </div>
          ) : (
            <div className="space-y-1.5">
              {notifData.notifications.map((notif) => (
                <button
                  key={notif.id}
                  onClick={() => handleMarkRead(notif.id)}
                  className={`flex w-full items-start gap-4 rounded-xl border p-4 text-left transition-all active:scale-[0.99] ${
                    notif.is_read
                      ? "border-border/20 bg-card/30"
                      : "border-primary/20 bg-card/60 shadow-sm"
                  }`}
                >
                  <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-full ${
                    notif.type === "like" ? "bg-red-500/10" :
                    notif.type === "comment" ? "bg-violet-500/10" :
                    notif.type === "follow" ? "bg-blue-500/10" :
                    notif.type === "favorite" ? "bg-amber-500/10" :
                    notif.type === "mention" ? "bg-cyan-500/10" :
                    "bg-muted/30"
                  }`}>
                    {notif.type === "like" && "❤️"}
                    {notif.type === "comment" && "💬"}
                    {notif.type === "follow" && "👤"}
                    {notif.type === "favorite" && "⭐"}
                    {notif.type === "mention" && "📢"}
                    {notif.type === "system" && "🔔"}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="truncate text-sm font-medium text-foreground">
                        {notif.title}
                      </span>
                      <span className="shrink-0 text-[10px] text-muted-foreground">
                        {formatRelativeTime(notif.created_at)}
                      </span>
                    </div>
                    <p className="mt-0.5 text-xs text-muted-foreground">{notif.body}</p>
                  </div>
                  {!notif.is_read && (
                    <span className="mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full bg-primary" />
                  )}
                </button>
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  );
}
