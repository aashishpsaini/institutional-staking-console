import { useEffect, useRef } from "react";

/** Calls `callback` every `delayMs` while `enabled` is true. */
export function useInterval(callback: () => void, delayMs: number, enabled: boolean): void {
  const callbackRef = useRef(callback);
  callbackRef.current = callback;

  useEffect(() => {
    if (!enabled) return;
    const id = window.setInterval(() => callbackRef.current(), delayMs);
    return () => window.clearInterval(id);
  }, [delayMs, enabled]);
}
