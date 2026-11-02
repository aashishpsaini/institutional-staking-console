import { ReactNode } from "react";

interface EmptyStateProps {
  readonly message: string;
  readonly action?: ReactNode;
}

export function EmptyState({ message, action }: EmptyStateProps) {
  return (
    <div style={{ padding: "1.5rem 0", color: "#5f6976" }}>
      <p>{message}</p>
      {action}
    </div>
  );
}
