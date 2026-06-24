import { HashRouter, Routes, Route, Navigate } from "react-router-dom";
import { lazy, Suspense } from "react";
import App from "./App";
import { ArtLoadingScreen } from "./components/ArtLoadingScreen";
import { ErrorBoundary } from "./components/ErrorBoundary";

const MultiPageApp = lazy(() => import("./pages/MultiPageApp"));

function RouteWrapper({ children }: { children: React.ReactNode }) {
  return (
    <ErrorBoundary>
      <Suspense fallback={<ArtLoadingScreen />}>
        {children}
      </Suspense>
    </ErrorBoundary>
  );
}

export function AppRouter() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<RouteWrapper><App /></RouteWrapper>} />
        <Route path="/login" element={<RouteWrapper><MultiPageApp page="login" /></RouteWrapper>} />
        <Route path="/signup" element={<RouteWrapper><MultiPageApp page="signup" /></RouteWrapper>} />
        <Route path="/profile" element={<RouteWrapper><MultiPageApp page="profile" /></RouteWrapper>} />
        <Route path="/community" element={<RouteWrapper><MultiPageApp page="community" /></RouteWrapper>} />
        <Route path="/database" element={<RouteWrapper><MultiPageApp page="database" /></RouteWrapper>} />
        <Route path="/music" element={<RouteWrapper><MultiPageApp page="music" /></RouteWrapper>} />
        <Route path="/visual-art" element={<RouteWrapper><MultiPageApp page="visual-art" /></RouteWrapper>} />
        <Route path="/manga" element={<RouteWrapper><MultiPageApp page="manga" /></RouteWrapper>} />
        <Route path="/film" element={<RouteWrapper><MultiPageApp page="film" /></RouteWrapper>} />
        <Route path="/literature" element={<RouteWrapper><MultiPageApp page="literature" /></RouteWrapper>} />
        <Route path="/animation" element={<RouteWrapper><MultiPageApp page="animation" /></RouteWrapper>} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </HashRouter>
  );
}
