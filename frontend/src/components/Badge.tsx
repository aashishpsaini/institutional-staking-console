import { ReactNode } from "react";
import type { OperationStatus } from "../types/operations";

interface BadgeProps {
  readonly status: OperationStatus | string;
  readonly children: ReactNode;
}

export function Badge({ status, children }: BadgeProps) {
  return <span className={`badge ${status}`}>{children}</span>;
}
