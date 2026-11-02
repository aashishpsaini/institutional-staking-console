import { useCallback, useState } from "react";
import type { AsyncState } from "../types/api";

export function useAsync<T>() {
  const [state, setState] = useState<AsyncState<T>>({ status: "idle" });

  const execute = useCallback(async (action: () => Promise<T>): Promise<T | null> => {
    setState({ status: "loading" });
    try {
      const data = await action();
      setState({ status: "success", data });
      return data;
    } catch (error) {
      const message = error instanceof Error ? error.message : "An unexpected error occurred";
      setState({ status: "error", error: message });
      return null;
    }
  }, []);

  const reset = useCallback(() => {
    setState({ status: "idle" });
  }, []);

  return [state, execute, reset] as const;
}
