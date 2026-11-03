import { DependencyList, useCallback, useEffect, useRef, useState } from "react";
import { isAbortError } from "../api";

export interface QueryState<T> {
  readonly data: T | undefined;
  readonly error: string | null;
  /** True only while there is no data yet — keeps tables mounted during refreshes. */
  readonly isLoading: boolean;
  readonly isRefreshing: boolean;
  readonly reload: () => void;
}

/**
 * Minimal data-fetching hook: aborts in-flight requests when deps change or the
 * component unmounts, ignores out-of-order responses, and keeps the previous
 * data visible while reloading (stale-while-revalidate).
 */
export function useQuery<T>(fetcher: (signal: AbortSignal) => Promise<T>, deps: DependencyList): QueryState<T> {
  const [data, setData] = useState<T | undefined>(undefined);
  const [error, setError] = useState<string | null>(null);
  const [inFlight, setInFlight] = useState(true);
  const [reloadToken, setReloadToken] = useState(0);
  const fetcherRef = useRef(fetcher);
  fetcherRef.current = fetcher;

  useEffect(() => {
    const controller = new AbortController();
    setInFlight(true);

    fetcherRef
      .current(controller.signal)
      .then((result) => {
        setData(result);
        setError(null);
      })
      .catch((err: unknown) => {
        if (isAbortError(err)) return;
        setError(err instanceof Error ? err.message : "Unexpected error");
      })
      .finally(() => {
        if (!controller.signal.aborted) setInFlight(false);
      });

    return () => controller.abort();
    // Deps are supplied by the caller, like useEffect itself; the fetcher is read via ref.
  }, [...deps, reloadToken]);

  const reload = useCallback(() => setReloadToken((n) => n + 1), []);

  return { data, error, isLoading: inFlight && data === undefined, isRefreshing: inFlight && data !== undefined, reload };
}
