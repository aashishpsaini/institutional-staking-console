import { FormEvent, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api } from "../api";
import { Alert } from "../components/Alert";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { Pagination } from "../components/Pagination";
import { TokenAmount } from "../components/TokenAmount";
import { useNetworks } from "../hooks/useNetworks";
import { usePagination } from "../hooks/usePagination";
import { useQuery } from "../hooks/useQuery";
import type { RewardFilters } from "../types/api";
import { daysAgo, formatDate, sumAmounts, toISODate } from "../utils/formatters";

const PRESETS = [
  { id: "all", label: "All time", days: null },
  { id: "7d", label: "Last 7 days", days: 7 },
  { id: "30d", label: "Last 30 days", days: 30 }
] as const;

function presetFilters(days: number | null, network: string): RewardFilters {
  return days === null ? { network, start: "", end: "" } : { network, start: daysAgo(days), end: toISODate(new Date()) };
}

export default function RewardsPage() {
  const { networks } = useNetworks();
  const [searchParams, setSearchParams] = useSearchParams();

  // Applied filters live in the URL so a filtered report can be bookmarked or shared.
  const applied: RewardFilters = useMemo(
    () => ({
      network: searchParams.get("network") ?? "",
      start: searchParams.get("start") ?? "",
      end: searchParams.get("end") ?? ""
    }),
    [searchParams]
  );
  const [draft, setDraft] = useState<RewardFilters>(applied);
  const [validationError, setValidationError] = useState<string | null>(null);
  useEffect(() => setDraft(applied), [applied]);

  const filterKey = `${applied.network}|${applied.start}|${applied.end}`;
  const rewards = useQuery((signal) => api.rewards(applied, signal), [filterKey]);
  const rows = rewards.data ?? [];
  const { page, setPage, pageSize, setPageSize, pageItems } = usePagination(rows, filterKey);

  const totalsByNetwork = useMemo(() => {
    const grouped = new Map<string, string[]>();
    rows.forEach((row) => grouped.set(row.network, [...(grouped.get(row.network) ?? []), row.amount]));
    return [...grouped].map(([network, amounts]) => ({ network, total: sumAmounts(amounts) }));
  }, [rows]);

  const apply = (filters: RewardFilters) => {
    if (filters.start && filters.end && filters.start > filters.end) {
      setValidationError("Start date must be on or before the end date.");
      return;
    }
    setValidationError(null);
    setSearchParams(Object.fromEntries(Object.entries(filters).filter(([, value]) => value !== "")));
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    apply(draft);
  };

  const activePreset =
    PRESETS.find((p) => {
      const expected = presetFilters(p.days, applied.network);
      return expected.start === applied.start && expected.end === applied.end;
    })?.id ?? "custom";

  return (
    <section>
      <h1>Rewards</h1>
      <p className="subtitle">Daily reward rollups per network. Amounts are summed from individual reward events.</p>

      <div className="quick-filters" role="group" aria-label="Date range presets">
        <span className="quick-filters-label">Range:</span>
        {PRESETS.map((preset) => (
          <button
            key={preset.id}
            type="button"
            className={`btn-pill ${activePreset === preset.id ? "active" : ""}`}
            aria-pressed={activePreset === preset.id}
            onClick={() => apply(presetFilters(preset.days, draft.network))}
          >
            {preset.label}
          </button>
        ))}
      </div>

      <form className="filters" onSubmit={handleSubmit}>
        <label>
          Network
          <select value={draft.network} onChange={(e) => setDraft((d) => ({ ...d, network: e.target.value }))}>
            <option value="">All networks</option>
            {networks.map((n) => (
              <option key={n.slug} value={n.slug}>
                {n.display_name}
              </option>
            ))}
          </select>
        </label>
        <label>
          Start date
          <input type="date" value={draft.start} max={draft.end || undefined} onChange={(e) => setDraft((d) => ({ ...d, start: e.target.value }))} />
        </label>
        <label>
          End date
          <input type="date" value={draft.end} min={draft.start || undefined} onChange={(e) => setDraft((d) => ({ ...d, end: e.target.value }))} />
        </label>
        <button type="submit" disabled={rewards.isRefreshing}>
          {rewards.isRefreshing ? "Loading…" : "Apply filters"}
        </button>
        <button type="button" className="btn-secondary" onClick={() => apply({ network: "", start: "", end: "" })}>
          Reset
        </button>
      </form>

      {validationError && <Alert variant="error">{validationError}</Alert>}
      {rewards.isLoading && <Loading message="Loading rewards…" />}
      {rewards.error && <Alert variant="error">{rewards.error}</Alert>}

      {rewards.data &&
        (rows.length === 0 ? (
          <EmptyState
            message="No rewards match these filters. Run a sync from the Portfolio page or widen the date range."
            action={
              <button type="button" className="btn-secondary" onClick={() => apply({ network: "", start: "", end: "" })}>
                Clear filters
              </button>
            }
          />
        ) : (
          <>
            <div className="summary-row" aria-label="Totals for current filters">
              {totalsByNetwork.map(({ network, total }) => (
                <div key={network} className="summary-item">
                  <span className="stat-title">{network} total</span>
                  <TokenAmount amount={total} network={network} />
                </div>
              ))}
            </div>

            <div className="table-container" aria-busy={rewards.isRefreshing}>
              <table>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Network</th>
                    <th>Daily reward</th>
                    <th>Events</th>
                  </tr>
                </thead>
                <tbody>
                  {pageItems.map((row) => (
                    <tr key={`${row.network}-${row.date}`}>
                      <td>{formatDate(row.date)}</td>
                      <td className="capitalize">{row.network}</td>
                      <td>
                        <TokenAmount amount={row.amount} network={row.network} />
                      </td>
                      <td>{row.event_count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <Pagination currentPage={page} totalItems={rows.length} pageSize={pageSize} onPageChange={setPage} onPageSizeChange={setPageSize} />
          </>
        ))}
    </section>
  );
}
