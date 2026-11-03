import type { OperationStatus, SyncRunStatus } from "../types/api";

interface BadgeProps {
  readonly status: OperationStatus | SyncRunStatus;
}

export function Badge({ status }: BadgeProps) {
  return <span className={`badge ${status}`}>{status}</span>;
}
