import { ReactNode } from "react";

interface StatCardProps {
  readonly title: string;
  readonly value: string | ReactNode;
  readonly subtitle?: string;
  readonly badge?: ReactNode;
}

export function StatCard({ title, value, subtitle, badge }: StatCardProps) {
  return (
    <div className="stat-card">
      <div className="stat-header">
        <span className="stat-title">{title}</span>
        {badge && <span>{badge}</span>}
      </div>
      <div className="stat-value">{value}</div>
      {subtitle && <div className="stat-subtitle">{subtitle}</div>}
    </div>
  );
}

