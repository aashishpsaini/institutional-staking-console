import type { ReactNode } from "react";

interface EmptyStateProps {
  readonly message: string;
  readonly action?: ReactNode;
}

export function EmptyState({ message, action }: EmptyStateProps) {
  return (
    <div className="empty-state">
      <p>{message}</p>
      {action}
    </div>
  );
}
