import type { ReactNode } from "react";

interface AlertProps {
  readonly variant: "error" | "success" | "info";
  readonly children: ReactNode;
}

const CLASS_BY_VARIANT = { error: "error", success: "success-msg", info: "info-msg" } as const;

export function Alert({ variant, children }: AlertProps) {
  return (
    <div className={CLASS_BY_VARIANT[variant]} role={variant === "error" ? "alert" : "status"}>
      {children}
    </div>
  );
}
