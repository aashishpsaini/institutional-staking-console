import { ReactNode } from "react";

interface AlertProps {
  readonly variant: "error" | "success" | "info";
  readonly children: ReactNode;
}

export function Alert({ variant, children }: AlertProps) {
  const className = variant === "error" ? "error" : variant === "success" ? "success-msg" : "muted";
  return <p className={className}>{children}</p>;
}
