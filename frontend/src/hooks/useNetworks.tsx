import { createContext, ReactNode, useContext, useMemo } from "react";
import { api } from "../api";
import type { Network } from "../types/api";
import { useQuery } from "./useQuery";

interface NetworksContextValue {
  readonly networks: readonly Network[];
  readonly bySlug: (slug: string) => Network | undefined;
  readonly error: string | null;
}

const NetworksContext = createContext<NetworksContextValue>({ networks: [], bySlug: () => undefined, error: null });

/** Loads network metadata (symbol, decimals) once so no page hardcodes token math. */
export function NetworksProvider({ children }: { readonly children: ReactNode }) {
  const { data, error } = useQuery((signal) => api.networks(signal), []);

  const value = useMemo(() => {
    const networks = data ?? [];
    const index = new Map(networks.map((n) => [n.slug, n]));
    return { networks, bySlug: (slug: string) => index.get(slug), error };
  }, [data, error]);

  return <NetworksContext.Provider value={value}>{children}</NetworksContext.Provider>;
}

export function useNetworks(): NetworksContextValue {
  return useContext(NetworksContext);
}
