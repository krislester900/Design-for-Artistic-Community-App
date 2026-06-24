import { Component, type ErrorInfo, type ReactNode } from "react";
import { AlertTriangle, RefreshCw } from "lucide-react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error("ErrorBoundary caught an error:", error, errorInfo);
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) {
        return this.props.fallback;
      }
      return (
        <div className="flex min-h-screen items-center justify-center bg-background px-6">
          <div className="street-panel mx-auto max-w-md p-8 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-red-500/10">
              <AlertTriangle className="h-7 w-7 text-red-400" />
            </div>
            <h2 className="mb-2 text-xl font-bold text-foreground">Quelque chose s'est mal passé</h2>
            <p className="mb-6 text-sm text-muted-foreground">
              Une erreur inattendue est survenue. Tu peux réessayer ou recharger la page.
            </p>
            {this.state.error && (
              <pre className="mb-6 overflow-x-auto rounded-lg border border-border bg-card/50 p-3 text-left text-xs text-red-300">
                {this.state.error.message}
              </pre>
            )}
            <button
              onClick={this.handleReset}
              className="inline-flex items-center gap-2 rounded-xl bg-primary px-5 py-3 text-sm font-medium text-primary-foreground transition-opacity hover:opacity-90"
            >
              <RefreshCw className="h-4 w-4" />
              Réessayer
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
