# 📱 Artéïa Mobile — Design Spec pour Figma

## Design Tokens

### Colors
```
Primary:    #FF6A1A (orange vif)
Secondary:  #D9FF38 (chartreuse)
Accent:     #28D8FF (cyan)
Bg:         #09090D (noir profond)
Card:       #15151B (card bg)
Surface:    #1A1A22 (surface)
Muted:      #B8B4C5 (gris lavande)
Red:        #D4183D (destructive)
Border:     rgba(255,255,255,0.11)
White:      #F3F2EC (foreground)
```

### Typography
```
Display (logo):   Alien Block, 28px, 400, tracking: 0.05em
H1:               Space Grotesk, 24px, 700, tracking: -0.02em
H2:               Space Grotesk, 18px, 600, tracking: -0.01em
H3:               Space Grotesk, 16px, 600
Body:             Josefin Sans, 15px, 400, leading: 1.5
Caption:          Josefin Sans, 11px, 500, tracking: 0.05em
Label (tab):      Josefin Sans, 10px, 500, tracking: 0.1em
```

### Spacing (base 4)
```
xs: 4px   sm: 8px   md: 16px   lg: 24px   xl: 32px   2xl: 48px
```

### Radius
```
sm: 8px   md: 12px   lg: 16px   xl: 24px   full: 9999px
```

### Shadows
```
Card:     0 2px 8px rgba(0,0,0,0.4)
Elevated: 0 8px 32px rgba(0,0,0,0.5)
Glow:     0 0 20px rgba(255,106,26,0.25)  // primary glow
TabBar:   0 -2px 16px rgba(0,0,0,0.6)
```

---

## ÉCRAN 1 — ACCUEIL (Home)

### Layout (360×800 viewport)
```
┌──────────────────────────────┐
│ [Logo Artéïa]          [👤]  │  h=56px header
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │     🎨 Hero Banner       │ │
│ │  "Ta créativité,         │ │  h=200px
│ │   ton univers"           │ │  gradient: primary/10→accent/5
│ │  Explore, crée, partage  │ │  padding: 24px
│ │                          │ │
│ └──────────────────────────┘ │
│                              │
│  Univers                     │
│ ┌──────┐┌──────┐┌──────┐┌──┐│
│ │🎵    ││🎨    ││📖    ││🎬││  h=80px each
│ │Musique││Art   ││Manga ││Film││ 2×4 grid
│ └──────┘└──────┘└──────┘└──┘│
│                              │
│  🔥 À la une                │
│ ┌───scroll horiz───────┐    │
│ │[card][card][card]→   │    │  h=220px
│ └──────────────────────┘    │  cards: 160×220
│                              │     img: 120px top
│                              │     title + artist + likes
│ ┌ Feed récent ─────────────┐│
│ │ [👤]  "Nouvel album..."  ││
│ │ [👤]  "Expo street art"  ││  h=60px each
│ │ [👤]  "Chapitre 42..."   ││  5 items
│ └──────────────────────────┘│
├──────────────────────────────┤
│ [🏠]  [🔍]  [💬]  [👤]     │  h=64px bottom bar
│ Accueil Explorer Chat Profil │
└──────────────────────────────┘
```

### Components détaillés:

**Hero Banner**
```
Container: 344×200px, rounded: 24px (xl)
Background: linear-gradient(135deg, rgba(255,106,26,0.12), rgba(40,216,255,0.06))
Decoration: floating abstract shapes (circles, dots) in primary/10
Content:
  - Badge "Bienvenue sur Artéïa" (primary bg, white text, 11px, rounded-full)
  - H1: "Ta créativité, ton univers" (Space Grotesk 700, 24px, foreground)
  - Caption: "Explore, crée, partage" (Josefin Sans 400, 13px, muted)
```

**Quick Action Card**
```
Size: 80×80px
Background: card (#15151B)
Border: 1px solid border
Radius: 16px (lg)
Icon: 44px circle with colored gradient bg (violet/orange/blue/emerald)
Label: 10px, muted, centered below icon
Press state: scale(0.95), card bg → surface
```

**Artwork Card (scroll horizontal)**
```
Size: 160×220px
Radius: 16px
Overflow: hidden
Top section: 120px height, gradient bg (primary/20→accent/10), placeholder image
Bottom section: padding 12px
  - Title: H3, 14px, foreground
  - Artist: Caption, 11px, muted
  - Badge: "❤️ 234" (primary/10 bg, 10px, primary, rounded-full)
```

**Feed Item**
```
Height: 60px
Padding: 12px 16px
Avatar: 40px circle, gradient primary→accent, initial letter
Content:
  - Title: Body semibold, 14px, foreground
  - Subtitle: Caption, 11px, muted
Right: heart icon + count
Press state: card/50 bg
```

**Bottom Tab Bar**
```
Height: 64px + safe-area-inset-bottom
Background: bg/95 + backdrop-blur(20px)
Border top: 1px solid border
Items: 4 equal-width tabs
  - Icon: 24px (lucide-react)
  - Label: 10px, 500
  - Active: primary color, small dot indicator (4px, primary, rounded-full)
  - Inactive: muted/40 color
  - Press: scale(0.9)
```

---

## ÉCRAN 2 — EXPLORER

```
┌──────────────────────────────┐
│ Explorer                     │  header
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 🔍 Rechercher un artiste │ │  Search bar
│ └──────────────────────────┘ │  h=44px, card bg
│                              │
│ ┌──────┐┌──────┐┌──────┐   │
│ │🎵    ││🎨    ││📖    │   │
│ │Musique││Art   ││Manga │   │  3×2 grid
│ │ 42    ││ 38   ││ 56   │   │  each: 100×100
│ └──────┘└──────┘└──────┘   │
│ ┌──────┐┌──────┐┌──────┐   │
│ │🎬    ││✍️    ││🎞️    │   │
│ │Films ││Litt. ││Animat│   │
│ │ 31   ││ 27   ││ 19   │   │
│ └──────┘└──────┘└──────┘   │
│                              │
│ [Tous] [Tendance] [Nouveau] [Populaire] │ chips
│                              │
│  Artistes à la une           │
│ ┌─card──┐┌─card──┐          │
│ │ img   ││ img   │          │  2 columns
│ │ name  ││ name  │          │
│ │ role  ││ role  │          │  masonry-layout
│ └───────┘└───────┘          │
├──────────────────────────────┤
│ [🏠]  [🔍]  [💬]  [👤]     │
└──────────────────────────────┘
```

**Category Card**
```
Size: 100×100px (flexible)
Background: each category has a unique gradient:
  Music: violet-500/15 → purple-600/10
  Art Visuel: orange-500/15 → red-500/10
  Manga: blue-500/15 → cyan-500/10
  Films: emerald-500/15 → teal-600/10
  Littérature: rose-500/15 → pink-600/10
  Animation: cyan-500/15 → blue-600/10
Border: 1px border
Radius: 16px
Icon: 48px in the center, category color
Label: H3, 14px, foreground
Count: Caption, 11px, muted (e.g. "42 œuvres")
Press: scale(0.95), border → primary/30
```

**Filter Chip**
```
Height: 32px
Padding: 8px 16px
Radius: full
Background: card
Border: 1px border
Text: Caption, 12px, muted
Active state: primary/15 bg, primary border, primary text
```

**Artist Card (masonry)**
```
Width: 50% of container (minus gap)
Border radius: 16px
Overflow: hidden
Background: card
Border: 1px border/20
Image: 140px height, object-cover, gradient overlay at bottom
Overlay: gradient from transparent to bg/80
Bottom section: padding 12px
  - Name: H3, 14px, foreground
  - Role: Caption, 11px, muted
  - Category badge: small chip, category color bg/20
Press: scale(0.97), shadow elevate
```

---

## ÉCRAN 3 — COMMUNAUTÉ (Chat)

```
┌──────────────────────────────┐
│ Communauté                   │
├──────────────────────────────┤
│ ┌──────────────────────────┐ │
│ │ 🔍 Rechercher une conv...│ │  Search
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ 🟢 Musique Urbaine   2m  │ │
│ │   "Nouveau son dispo!" │ │  h=72px
│ │                    [3] │ │
│ ├──────────────────────────┤ │
│ │ ⚪ Art Visuel Paris  1h  │ │
│ │   "Expo ce weekend..." │ │
│ ├──────────────────────────┤ │
│ │ 🟢 Manga Club        3h  │ │
│ │   "Chapitre 42..."   [5]│ │
│ ├──────────────────────────┤ │
│ │ ⚪ Films Indés       5h  │ │
│ │   "Projection privée..."│ │
│ └──────────────────────────┘ │
├──────────────────────────────┤
│ [🏠]  [🔍]  [💬]  [👤]     │
└──────────────────────────────┘
```

**Chat List Item**
```
Height: 72px
Padding: 12px 16px
Avatar: 48px circle, card bg, first letter(s) in primary
Online indicator: 8px circle, green (#22C55E), absolute bottom-right of avatar
Content (flex-1):
  - Name: H3, 14px, foreground, semibold
  - Last message: Caption, 12px, muted, truncate
  - Time: Caption, 10px, muted/60
Unread badge: 20px circle, primary bg, white text, 10px bold
Separator: 1px solid border/20, inset-left 64px
Press: card/60 bg
```

**Vue Chat (quand on ouvre une conversation)**:
```
┌──────────────────────────────┐
│ ←  🟢 Musique Urbaine      │  Chat header, h=56px
├──────────────────────────────┤
│                              │
│ ┌──────┐                     │
│ │ DJ K │ Merci ! J'ai bossé │  Message reçu
│ │      │ toute la semaine   │  card bg, rounded-bl: 4px
│ └──────┘             14:31   │
│                              │
│         ┌──────────────────┐│
│         │ Grave ! Envoie !!││  Message envoyé
│         └──────────────────┘│  primary gradient
│                    14:33    │  rounded-br: 4px
│                              │
├──────────────────────────────┤
│ 😊 📎 ┌─────────────────┐ 🎤│  Input bar
│       │ Écris un message  │  │  h=52px
│       └─────────────────┘  │
└──────────────────────────────┘
```

**Message Bubble (reçu)**
```
Max width: 80% of screen
Background: card (#15151B)
Border: 1px border
Border radius: 16px, bottom-left: 4px
Padding: 10px 14px
Author name: Caption, 11px, semibold, primary (only first of group)
Content: Body, 14px, foreground
Timestamp: Caption, 10px, muted/40, right-aligned
```

**Message Bubble (envoyé)**
```
Max width: 80%
Background: linear-gradient(135deg, primary, primary/80)
Text: white
Border radius: 16px, bottom-right: 4px
Padding: 10px 14px
Content: Body, 14px, white
Timestamp: 10px, white/60, right-aligned
```

**Input Bar**
```
Background: bg/95 + backdrop-blur(20px)
Border top: 1px border
Padding: 8px 12px
Items (left to right):
  - Emoji button: 36px circle, icon Smile, muted
  - Attach button: 36px circle, icon Paperclip, muted
  - Input: flex-1, h=40px, border rounded-2xl, card/60 bg, 14px text, placeholder muted/30
  - Send/Mic button: 40px circle
      - If text entered: primary gradient bg, Send icon, white, shadow glow
      - If empty: card bg, Mic icon, muted, subtle border
```

---

## ÉCRAN 4 — PROFIL

```
┌──────────────────────────────┐
│ Profil                       │
├──────────────────────────────┤
│                              │
│ ┌──────────────────────────┐ │
│ │      ┌────┐              │ │
│ │      │ 80 │  gradient    │ │  Avatar: 80px
│ │      │ px │  border 3px  │ │  border: 3px solid primary→accent
│ │      └────┘              │ │
│ │     Créateur              │ │  H1 name
│ │     test@arteia.com       │ │  Caption email
│ │                           │ │
│ └──────────────────────────┘ │  Card h=160px, gradient bg
│                              │
│ ┌───┐ ┌───┐ ┌───┐          │
│ │ 12│ │156│ │ 89│          │  Stats row
│ │ Œuv│ │Foll│ │Suiv│          │  equal width, centered
│ └───┘ └───┘ └───┘          │
│                              │
│ ┌──────────────────────────┐ │
│ │ ❤️  Favoris           > │ │
│ │ 🔖  Enregistrés       > │ │  Menu items
│ │ 🎨  Mes créations     > │ │  h=52px each
│ │ 🔔  Notifications     > │ │  icon + label + chevron
│ │ ⚙️  Paramètres        > │ │
│ └──────────────────────────┘ │
│                              │
│ ┌──────────────────────────┐ │
│ │ 🚪  Déconnexion          │ │
│ └──────────────────────────┘ │  destructive bg
│                              │
├──────────────────────────────┤
│ [🏠]  [🔍]  [💬]  [👤]     │
└──────────────────────────────┘
```

**Profile Avatar**
```
Size: 80×80px
Shape: circle
Border: 3px solid transparent
Gradient border: primary→accent (use background-clip technique or pseudo-element)
Background: gradient primary→accent
Icon/Initial: User icon 32px or initial letter, white
Shadow: 0 4px 20px rgba(255,106,26,0.3)
```

**Stat Item**
```
Height: 56px
Layout: flex-col, centered
Number: H2, 24px, foreground, bold
Label: Caption, 11px, muted, uppercase
```

**Menu Item**
```
Height: 52px
Padding: 0 16px
Icon: 20px, left, colored per item
Label: Body, 15px, foreground
Chevron: ChevronRight icon 16px, muted/40
Divider: 1px border/20, inset 48px
Press: card/60 bg
Last item: no divider
```

**Logout Button**
```
Height: 52px
Background: red-500/8 (very subtle)
Text: Body, 15px, red-400
Icon: LogOut 20px, red-400
Press: red-500/15 bg
```

---

## GLOBAL COMPONENTS

### Loading Skeleton
```
Card skeleton: shimmer animation on card bg
  - Rectangle for image
  - 3 bars for text (80%, 60%, 40% width)
  - Each: bg muted/20, rounded-full, shimmer gradient
```

### Empty States
```
Icon: 64px, muted/20, centered
Title: H2, 20px, muted, centered
Subtitle: Caption, muted/60, centered
CTA button: primary gradient, rounded-xl
```

### Toast/Notification
```
Position: top, sticky
Background: card, border, backdrop-blur
Border left: 3px primary (success) or destructive (error)
Padding: 12px 16px
Icon + Message: Caption, 13px
Auto-dismiss: 3s
Swipe to dismiss
```

### Pull to Refresh
```
Spinner: 24px, primary color
Position: top of scroll container
Threshold: 80px pull
```

---

## ANIMATION SPECS

| Animation | Duration | Easing | Description |
|-----------|----------|--------|-------------|
| Tab switch | 200ms | ease-out | opacity 0→1, translateY(8px→0) |
| Card enter | 300ms | ease-out | opacity 0→1, translateY(20px→0), stagger 50ms per card |
| Button press | 100ms | ease-in-out | scale(0.97) + opacity(0.85) |
| Skeleton shimmer | 1.5s | ease-in-out | infinite loop, gradient translation |
| Toast enter | 300ms | spring(0.4,0.8) | translateY(-20px→0) + opacity(0→1) |
| Modal/Overlay | 250ms | ease-out | backdrop opacity 0→1, content scale(0.95→1) |
| Message sent | 200ms | ease-out | scale(0.8→1), opacity(0→1) |
| Tab indicator | 250ms | spring(0.3,0.9) | dot size 0→4px, spring bounce |