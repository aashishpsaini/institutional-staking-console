interface LoadingProps {
  readonly message?: string;
}

export function Loading({ message = "Loading…" }: LoadingProps) {
  return (
    <p className="muted" role="status" aria-live="polite">
      {message}
    </p>
  );
}
