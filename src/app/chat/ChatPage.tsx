import { useState, useEffect, useCallback, useRef } from "react";
import { LogIn, MessageCircle } from "lucide-react";
import { supabase, hasSupabaseEnv } from "../lib/supabase";
import type {
  ChatChannel,
  ChatGroup,
  ChatMessage,
  ChatChannelMember,
  UserPresence,
  UnreadCount,
  ChannelPreview,
  MessageReaction,
} from "./chat-types";
import {
  fetchChannels,
  fetchGroups,
  fetchMessages,
  sendMessage as sendMessageService,
  deleteMessage as deleteMessageService,
  editMessage as editMessageService,
  subscribeToMessages,
  fetchChannelMembers,
  addReaction,
  fetchReactions,
  togglePinMessage,
  fetchPinnedMessages,
  createChannel,
  leaveChannel,
  uploadChatFile,
  sendVoiceMessage,
  sendStickerMessage,
  sendGifMessage,
  sendFileMessage,
  updatePresence,
  fetchPresence,
  setTyping,
  subscribeToTyping,
  searchMessages,
  joinChannel,
} from "./chat-service";
import { ChatSidebar } from "./ChatSidebar";
import { ChatHeader } from "./ChatHeader";
import { ChatMessage as ChatMessageComponent } from "./ChatMessage";
import { ChatInput } from "./ChatInput";
import { CreateChannelDialog } from "./CreateChannelDialog";

export function ChatPage() {
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);
  const [currentUserEmail, setCurrentUserEmail] = useState<string>("");
  const [channels, setChannels] = useState<ChatChannel[]>([]);
  const [groups, setGroups] = useState<ChatGroup[]>([]);
  const [activeChannelId, setActiveChannelId] = useState<string | null>(null);
  const [activeGroupId, setActiveGroupId] = useState<string | null>(null);
  const [showFriends, setShowFriends] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [members, setMembers] = useState<ChatChannelMember[]>([]);
  const [showMembers, setShowMembers] = useState(false);
  const [pinnedCount, setPinnedCount] = useState(0);
  const [replyTo, setReplyTo] = useState<{ id: string; content: string } | null>(null);
  const [showCreateChannel, setShowCreateChannel] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [typingUsers, setTypingUsers] = useState<{ user_id: string; email: string }[]>([]);
  const [userPresence, setUserPresence] = useState<Record<string, UserPresence["status"]>>({});
  const [unreadCounts, setUnreadCounts] = useState<UnreadCount[]>([]);
  const [channelPreviews, setChannelPreviews] = useState<ChannelPreview[]>([]);
  const [searchMode, setSearchMode] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<ChatMessage[]>([]);
  const [reactionsMap, setReactionsMap] = useState<Map<string, MessageReaction[]>>(new Map());

  const messagesEndRef = useRef<HTMLDivElement>(null);
  const typingTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const unsubscribeMessagesRef = useRef<(() => void) | null>(null);
  const unsubscribeTypingRef = useRef<(() => void) | null>(null);
  const messagesRef = useRef(messages);
  messagesRef.current = messages;

  const activeChannel = channels.find((c) => c.id === activeChannelId) || null;

  // ─── Scroll to bottom ───
  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };
  const prevMessagesLength = useRef(0);
  useEffect(() => {
    if (messages.length > prevMessagesLength.current) {
      const lastMsg = messages[messages.length - 1];
      if (lastMsg?.author_id === currentUserId) {
        scrollToBottom();
      }
    }
    prevMessagesLength.current = messages.length;
  }, [messages, currentUserId]);
  useEffect(() => {
    scrollToBottom();
  }, [searchResults]);

  // ─── Load current user ───
  useEffect(() => {
    if (!hasSupabaseEnv || !supabase) {
      setIsLoading(false);
      return;
    }
    supabase.auth.getUser().then(({ data }) => {
      if (data.user) {
        setCurrentUserId(data.user.id);
        setCurrentUserEmail(data.user.email || "");
      }
      setIsLoading(false);
    });
  }, []);

  // ─── Update presence ───
  useEffect(() => {
    if (!currentUserId) return;
    updatePresence("online");
    const interval = setInterval(() => updatePresence("online"), 30000);
    const handleVisibility = () => {
      updatePresence(document.hidden ? "idle" : "online");
    };
    document.addEventListener("visibilitychange", handleVisibility);
    return () => {
      clearInterval(interval);
      document.removeEventListener("visibilitychange", handleVisibility);
      updatePresence("offline");
    };
  }, [currentUserId]);

  // ─── Fetch presence ───
  useEffect(() => {
    if (!hasSupabaseEnv || !supabase) return;
    fetchPresence().then((data) => {
      const map: Record<string, UserPresence["status"]> = {};
      for (const p of data) {
        map[p.user_id] = p.status;
      }
      setUserPresence(map);
    });
  }, []);

  // ─── Load channels and groups ───
  const loadChannelsAndGroups = useCallback(async () => {
    if (!hasSupabaseEnv || !supabase) return;
    try {
      const [ch, gr] = await Promise.all([fetchChannels(), fetchGroups()]);
      setChannels(ch);
      setGroups(gr);
    } catch (err) {
      console.error("Failed to load channels/groups:", err);
    }
  }, []);

  useEffect(() => {
    loadChannelsAndGroups();
  }, [loadChannelsAndGroups]);

  // ─── Load messages when channel changes ───
  useEffect(() => {
    if (!activeChannelId || !hasSupabaseEnv || !supabase) {
      setMessages([]);
      setMembers([]);
      setPinnedCount(0);
      return;
    }

    let isMounted = true;

    async function load() {
      try {
        const [msgs, mems, pinned] = await Promise.all([
          fetchMessages(activeChannelId!, 50),
          fetchChannelMembers(activeChannelId!),
          fetchPinnedMessages(activeChannelId!),
        ]);
        if (!isMounted) return;
        setMessages(msgs);
        setMembers(mems);
        setPinnedCount(pinned.length);

        // Load reactions
        const msgIds = msgs.map((m) => m.id);
        if (msgIds.length > 0) {
          const rmap = await fetchReactions(msgIds);
          if (isMounted) {
            setReactionsMap(rmap);
            setMessages((prev) =>
              prev.map((m) => ({
                ...m,
                reactions: rmap.get(m.id) || [],
              })),
            );
          }
        }
      } catch (err) {
        console.error("Failed to load channel data:", err);
      }
    }

    load();

    // Subscribe to real-time messages
    const unsubMessages = subscribeToMessages(activeChannelId, (newMsg) => {
      if (!isMounted) return;
      setMessages((prev) => {
        if (prev.find((m) => m.id === newMsg.id)) return prev;
        return [...prev, newMsg];
      });
    });

    // Subscribe to typing
    const unsubTyping = subscribeToTyping(activeChannelId, (typing) => {
      if (!isMounted) return;
      setTypingUsers(typing.filter((t) => t.user_id !== currentUserId));
    });

    unsubscribeMessagesRef.current = unsubMessages;
    unsubscribeTypingRef.current = unsubTyping;

    return () => {
      isMounted = false;
      unsubMessages?.();
      unsubTyping?.();
    };
  }, [activeChannelId, currentUserId]);

  // ─── Handlers ───
  const handleSelectChannel = useCallback(async (id: string) => {
    setActiveChannelId(id);
    setActiveGroupId(null);
    setShowFriends(false);
    setSearchMode(false);
    setSearchResults([]);
    try {
      await joinChannel(id);
    } catch {
      // Already joined or not authenticated
    }
  }, []);

  const handleSelectGroup = useCallback((id: string) => {
    setActiveGroupId(id);
    setActiveChannelId(null);
    setShowFriends(false);
    setSearchMode(false);
    setSearchResults([]);
  }, []);

  const handleShowFriends = useCallback(() => {
    setShowFriends(true);
    setActiveChannelId(null);
    setActiveGroupId(null);
    setSearchMode(false);
    setSearchResults([]);
  }, []);

  const handleCreateChannel = useCallback(
    async (name: string, description: string, type: "public" | "private", categorySlug: string | null) => {
      try {
        const channel = await createChannel(name, description, type, categorySlug);
        setChannels((prev) => [...prev, channel]);
        setActiveChannelId(channel.id);
        setShowFriends(false);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur lors de la création du salon");
      }
    },
    [],
  );

  const handleSend = useCallback(
    async (content: string, attachmentUrl?: string) => {
      if (!activeChannelId || !currentUserId) return;
      try {
        await sendMessageService(activeChannelId, content, replyTo?.id, attachmentUrl);
        setReplyTo(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur d'envoi");
      }
    },
    [activeChannelId, currentUserId, replyTo],
  );

  const handleDelete = useCallback(async (id: string) => {
    try {
      await deleteMessageService(id);
      setMessages((prev) => prev.filter((m) => m.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur de suppression");
    }
  }, []);

  const handleEdit = useCallback(async (id: string, content: string) => {
    try {
      await editMessageService(id, content);
      setMessages((prev) => prev.map((m) => (m.id === id ? { ...m, content, edited_at: new Date().toISOString() } : m)));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur de modification");
    }
  }, []);

  const handleReply = useCallback((id: string) => {
    const msg = messagesRef.current.find((m) => m.id === id);
    if (msg) {
      setReplyTo({ id: msg.id, content: msg.content.slice(0, 80) + (msg.content.length > 80 ? "..." : "") });
    }
  }, []);

  const handleReact = useCallback(async (messageId: string, emoji: string) => {
    try {
      await addReaction(messageId, emoji);
      // Refresh reactions for this message
      const rmap = await fetchReactions([messageId]);
      const reactions = rmap.get(messageId) || [];
      setMessages((prev) => prev.map((m) => (m.id === messageId ? { ...m, reactions } : m)));
      setReactionsMap((prev) => {
        const next = new Map(prev);
        next.set(messageId, reactions);
        return next;
      });
    } catch (err) {
      console.error("Reaction error:", err);
    }
  }, []);

  const handlePin = useCallback(async (messageId: string) => {
    try {
      await togglePinMessage(messageId);
      setMessages((prev) =>
        prev.map((m) => (m.id === messageId ? { ...m, is_pinned: !m.is_pinned } : m)),
      );
      setPinnedCount((prev) => (messagesRef.current.find((m) => m.id === messageId)?.is_pinned ? prev - 1 : prev + 1));
    } catch (err) {
      console.error("Pin error:", err);
    }
  }, []);

  const handleLeave = useCallback(async () => {
    if (!activeChannelId) return;
    try {
      await leaveChannel(activeChannelId);
      setActiveChannelId(null);
      setMessages([]);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erreur");
    }
  }, [activeChannelId]);

  const handleSearch = useCallback(async (query: string) => {
    if (!activeChannelId || !query.trim()) {
      setSearchMode(false);
      setSearchResults([]);
      return;
    }
    setSearchMode(true);
    setSearchQuery(query);
    try {
      const results = await searchMessages(activeChannelId, query);
      setSearchResults(results);
    } catch (err) {
      console.error("Search error:", err);
    }
  }, [activeChannelId]);

  const handleFileUpload = useCallback(
    async (file: File) => {
      if (!activeChannelId || !currentUserId) return;
      try {
        const url = await uploadChatFile(file, activeChannelId);
        await sendFileMessage(activeChannelId, url, file.name);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur d'upload");
      }
    },
    [activeChannelId, currentUserId],
  );

  const handleSendVoice = useCallback(
    async (audioBlob: Blob, duration: number) => {
      if (!activeChannelId || !currentUserId) return;
      try {
        const url = await uploadChatFile(audioBlob, activeChannelId);
        await sendVoiceMessage(activeChannelId, url, duration);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur vocal");
      }
    },
    [activeChannelId, currentUserId],
  );

  const handleSendSticker = useCallback(
    async (stickerId: string, stickerUrl: string) => {
      if (!activeChannelId) return;
      try {
        await sendStickerMessage(activeChannelId, stickerId, stickerUrl);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur sticker");
      }
    },
    [activeChannelId],
  );

  const handleSendGif = useCallback(
    async (gifUrl: string) => {
      if (!activeChannelId) return;
      try {
        await sendGifMessage(activeChannelId, gifUrl);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Erreur GIF");
      }
    },
    [activeChannelId],
  );

  const handleTyping = useCallback(
    (isTyping: boolean) => {
      if (!activeChannelId) return;
      setTyping(activeChannelId, isTyping);
      if (typingTimeoutRef.current) clearTimeout(typingTimeoutRef.current);
      if (isTyping) {
        typingTimeoutRef.current = setTimeout(() => {
          setTyping(activeChannelId, false);
        }, 3000);
      }
    },
    [activeChannelId],
  );

  // ─── Typing indicator UI ───
  const typingIndicator = typingUsers.length > 0 && (
    <div className="px-6 py-1 text-[11px] text-muted-foreground/60 animate-pulse">
      {typingUsers.map((u) => u.email.split("@")[0]).join(", ")} {typingUsers.length > 1 ? "écrivent" : "écrit"}...
    </div>
  );

  // ─── Not connected view ───
  if (!hasSupabaseEnv || !supabase) {
    return (
      <section id="chat" className="scroll-mt-28">
        <div className="mx-auto max-w-7xl px-6 py-20">
          <div className="street-panel mx-auto max-w-lg p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-primary/10">
              <MessageCircle className="h-6 w-6 text-primary" />
            </div>
            <h2 className="mb-3 text-2xl font-display italic text-foreground">Chat communautaire</h2>
            <p className="text-muted-foreground">
              Le chat nécessite une connexion Supabase. Configure VITE_SUPABASE_URL et VITE_SUPABASE_ANON_KEY dans .env.
            </p>
          </div>
        </div>
      </section>
    );
  }

  if (isLoading) {
    return (
      <section id="chat" className="scroll-mt-28">
        <div className="mx-auto max-w-7xl px-6 py-20 text-center">
          <p className="text-muted-foreground animate-pulse">Chargement du chat...</p>
        </div>
      </section>
    );
  }

  if (!currentUserId) {
    return (
      <section id="chat" className="scroll-mt-28">
        <div className="mx-auto max-w-7xl px-6 py-20">
          <div className="street-panel mx-auto max-w-lg p-10 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-primary/10">
              <LogIn className="h-6 w-6 text-primary" />
            </div>
            <h2 className="mb-3 text-2xl font-display italic text-foreground">Rejoins la conversation</h2>
            <p className="mb-6 text-muted-foreground">
              Connecte-toi pour accéder aux salons de discussion et discuter avec la communauté Arteïa.
            </p>
            <a
              href="/connexion.html"
              className="inline-flex items-center gap-2 rounded-xl bg-primary px-6 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
            >
              <LogIn className="h-4 w-4" />
              Se connecter
            </a>
          </div>
        </div>
      </section>
    );
  }

  const displayMessages = searchMode ? searchResults : messages;
  const totalUnread = unreadCounts.reduce((sum, u) => sum + u.count, 0);

  return (
    <section id="chat" className="scroll-mt-28">
      <div className="mx-auto max-w-7xl px-6 py-6">
        <div className="street-panel overflow-hidden" style={{ height: "70vh", minHeight: "500px" }}>
          <div className="flex h-full">
            <ChatSidebar
              channels={channels}
              groups={groups}
              activeChannelId={activeChannelId}
              activeGroupId={activeGroupId}
              onSelectChannel={handleSelectChannel}
              onSelectGroup={handleSelectGroup}
              onCreateChannel={() => setShowCreateChannel(true)}
              onCreateGroup={() => { /* TODO: group creation */ }}
              onShowFriends={handleShowFriends}
              showFriends={showFriends}
              unreadCounts={unreadCounts}
              channelPreviews={channelPreviews}
              userPresence={userPresence}
              totalUnread={totalUnread}
            />

            <div className="flex flex-1 flex-col min-w-0">
              {activeChannel && (
                <ChatHeader
                  channel={activeChannel}
                  members={members}
                  currentUserId={currentUserId}
                  onShowMembers={() => setShowMembers(!showMembers)}
                  onLeaveChannel={handleLeave}
                  showMembers={showMembers}
                  userPresence={userPresence}
                  pinnedCount={pinnedCount}
                  onSearch={handleSearch}
                />
              )}

              {showFriends && (
                <div className="flex flex-1 items-center justify-center">
                  <div className="text-center p-10">
                    <MessageCircle className="mx-auto mb-4 h-10 w-10 text-muted-foreground/30" />
                    <p className="text-muted-foreground">Sélectionne un salon ou un groupe pour commencer à discuter.</p>
                  </div>
                </div>
              )}

              {activeChannel && !showFriends && (
                <>
                  <div className="flex-1 overflow-y-auto px-2 py-4">
                    {searchMode && (
                      <div className="mb-4 px-4">
                        <p className="text-xs text-muted-foreground">
                          {searchResults.length} résultat{searchResults.length > 1 ? "s" : ""} pour "{searchQuery}"
                        </p>
                      </div>
                    )}
                    {displayMessages.length === 0 ? (
                      <div className="flex h-full items-center justify-center">
                        <div className="text-center">
                          <MessageCircle className="mx-auto mb-3 h-10 w-10 text-muted-foreground/20" />
                          <p className="text-sm text-muted-foreground">
                            {searchMode ? "Aucun message trouvé" : "Aucun message encore. Sois le premier à écrire !"}
                          </p>
                        </div>
                      </div>
                    ) : (
                      <div className="space-y-1">
                        {displayMessages.map((msg, index) => {
                          const prevMsg = displayMessages[index - 1];
                          const showAuthor = !prevMsg || prevMsg.author_id !== msg.author_id;
                          return (
                            <ChatMessageComponent
                              key={msg.id}
                              message={msg}
                              isOwn={msg.author_id === currentUserId}
                              onDelete={handleDelete}
                              onEdit={handleEdit}
                              onReply={handleReply}
                              onReact={handleReact}
                              onPin={handlePin}
                              showAuthor={showAuthor}
                            />
                          );
                        })}
                        <div ref={messagesEndRef} />
                      </div>
                    )}
                  </div>

                  <ChatInput
                    onSend={handleSend}
                    onSendVoice={handleSendVoice}
                    onSendSticker={handleSendSticker}
                    onSendGif={handleSendGif}
                    onFileUpload={handleFileUpload}
                    replyTo={replyTo}
                    onCancelReply={() => setReplyTo(null)}
                    disabled={false}
                    typingIndicator={typingIndicator}
                  />
                </>
              )}

              {!activeChannel && !showFriends && (
                <div className="flex flex-1 items-center justify-center">
                  <div className="text-center p-10">
                    <MessageCircle className="mx-auto mb-4 h-12 w-12 text-muted-foreground/20" />
                    <p className="text-lg font-medium text-foreground mb-1">Bienvenue dans le chat Artéïa</p>
                    <p className="text-sm text-muted-foreground max-w-sm">
                      Sélectionne un salon dans la barre latérale pour rejoindre la conversation en temps réel.
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="fixed bottom-24 right-6 z-50 max-w-md rounded-xl border border-red-500/30 bg-red-500/10 px-5 py-4 text-sm text-red-300 shadow-xl backdrop-blur">
          {error}
          <button onClick={() => setError(null)} className="ml-3 text-red-400 hover:text-red-200">×</button>
        </div>
      )}

      <CreateChannelDialog
        open={showCreateChannel}
        onClose={() => setShowCreateChannel(false)}
        onCreate={handleCreateChannel}
        categories={channels
          .filter((c) => c.category_slug)
          .map((c) => ({ slug: c.category_slug!, label: c.name }))}
      />
    </section>
  );
}
