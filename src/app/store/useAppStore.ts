import { create } from "zustand";
import type { CategorySlug } from "../data/community";
import type { AuthUser } from "../services/auth";

interface AppState {
  selectedCategory: CategorySlug;
  setSelectedCategory: (category: CategorySlug) => void;

  currentUser: AuthUser | null;
  setCurrentUser: (user: AuthUser | null) => void;

  isMobile: boolean | null;
  setIsMobile: (value: boolean | null) => void;
}

export const useAppStore = create<AppState>((set) => ({
  selectedCategory: "all",
  setSelectedCategory: (category) => set({ selectedCategory: category }),

  currentUser: null,
  setCurrentUser: (user) => set({ currentUser: user }),

  isMobile: null,
  setIsMobile: (value) => set({ isMobile: value }),
}));
