import { ChangeEvent, FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { apiGet } from "../api";
import { Alert } from "../components/Alert";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { Pagination } from "../components/Pagination";
import { useAsync } from "../hooks/useAsync";
import type { RewardFilters, RewardsResponse } from "../types/rewards";
import { formatDate, formatTokenAmount } from "../utils/formatters";

const initialFilters: RewardFilters = {
  network: "",
  start: "",
  end: ""
};

export default function RewardsPage() {
  const [filters, setFilters] = useState<RewardFilters>(initialFilters);
  const [rewardsState, fetchRewards] = useAsync<RewardsResponse>();
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);
  const [activePreset, setActivePreset] = useState<string>("all");

  const loadRewards = useCallback(
    (currentFilters: RewardFilters) => {
      const params = new URLSearchParams();
      if (currentFilters.network) params.set("network", currentFilters.network);
      if (currentFilters.start) params.set("start", currentFilters.start);
      if (currentFilters.end) params.set("end", currentFilters.end);

      void fetchRewards(() => apiGet<RewardsResponse>(`/api/v1/rewards?${params.toString()}`));
      setCurrentPage(1);
    },
    [fetchRewards]
  );

  useEffect(() => {
    loadRewards(initialFilters);
  }, [loadRewards]);

  const handleNetworkChange = (event: ChangeEvent<HTMLSelectElement>) => {
    setFilters((prev) => ({ ...prev, network: event.target.value }));
  };

  const handleStartChange = (event: ChangeEvent<HTMLInputElement>) => {
    setFilters((prev) => ({ ...prev, start: event.target.value }));
    setActivePreset("custom");
  };

  const handleEndChange = (event: ChangeEvent<HTMLInputElement>) => {
    setFilters((prev) => ({ ...prev, end: event.target.value }));
    setActivePreset("custom");
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    loadRewards(filters);
  };

  const applyPreset = (preset: "7d" | "30d" | "all") => {
    setActivePreset(preset);
    const today = new Date();
    const endStr = today.toISOString().split("T")[0] ?? "";

    if (preset === "7d") {
      const past = new Date();
      past.setDate(today.getDate() - 7);
      const newFilters = { ...filters, start: past.toISOString().split("T")[0] ?? "", end: endStr };
      setFilters(newFilters);
      loadRewards(newFilters);
    } else if (preset === "30d") {
      const past = new Date();
      past.setDate(today.getDate() - 30);
      const newFilters = { ...filters, start: past.toISOString().split("T")[0] ?? "", end: endStr };
      setFilters(newFilters);
      loadRewards(newFilters);
    } else {
      const newFilters = { ...filters, start: "", end: "" };
      setFilters(newFilters);
      loadRewards(newFilters);
    }
  };

  const handleReset = () => {
    setFilters(initialFilters);
    setActivePreset("all");
    loadRewards(initialFilters);
  };

  const isLoading = rewardsState.status === "loading";

  // Client-side pagination for responsive UI
  const rows = rewardsState.status === "success" ? rewardsState.data.data : [];
  const paginatedRows = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize;
    return rows.slice(startIndex, startIndex + pageSize);
  }, [rows, currentPage, pageSize]);

  return (
    <section>
      <h1>Rewards Reporting</h1>
      <p className="subtitle">Daily reward rollups aggregated from validators, with multi-network and date-window filtering.</p>

        <div className="quick-filters">
          <span style={{ fontSize: "0.85rem", color: "#64748b", fontWeight: 600 }}>Quick Range:</span>
          <button
            type="button"
            className={`btn-pill ${activePreset === "all" ? "active" : ""}`}
            onClick={() => applyPreset("all")}
          >
            All Time
          </button>
          <button
            type="button"
            className={`btn-pill ${activePreset === "7d" ? "active" : ""}`}
            onClick={() => applyPreset("7d")}
          >
            Last 7 Days
          </button>
          <button
            type="button"
            className={`btn-pill ${activePreset === "30d" ? "active" : ""}`}
            onClick={() => applyPreset("30d")}
          >
            Last 30 Days
          </button>
        </div>

        <form className="filters" onSubmit={handleSubmit}>
          <label>
            Network
            <select value={filters.network} onChange={handleNetworkChange}>
              <option value="">All Networks</option>
              <option value="ethereum">Ethereum</option>
              <option value="solana">Solana</option>
            </select>
          </label>
          <label>
            Start Date
            <input type="date" value={filters.start} onChange={handleStartChange} />
          </label>
          <label>
            End Date
            <input type="date" value={filters.end} onChange={handleEndChange} />
          </label>
          <button type="submit" disabled={isLoading}>
            {isLoading ? "Filtering…" : "Apply Filters"}
          </button>
            <button type="button" className="btn-secondary" onClick={handleReset} disabled={isLoading}>
              Reset
            </button>
        </form>

        {rewardsState.status === "loading" && <Loading message="Loading daily rewards rollups…" />}
        {rewardsState.status === "error" && <Alert variant="error">{rewardsState.error}</Alert>}

        {rewardsState.status === "success" && (
          <>
          {rows.length === 0 ? (
              <EmptyState
                message="No rewards found matching current criteria. Sync rewards from the Portfolio page or broaden your date filters."
                action={
                  <button type="button" className="btn-secondary" onClick={handleReset}>
                    Clear Filters
                  </button>
                }
              />
            ) : (
            <>
              <div className="table-container">
                <table>
                  <thead>
                    <tr>
                      <th>Reward Date</th>
                      <th>Network</th>
                      <th>Daily Reward Amount</th>
                      <th>Events Count</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedRows.map((row) => (
                      <tr key={`${row.network}-${row.date}-${row.amount}`}>
                        <td>{formatDate(row.date)}</td>
                        <td>
                          <strong style={{ textTransform: "capitalize" }}>{row.network}</strong>
                        </td>
                        <td>
                          <span className="token-readable">{formatTokenAmount(row.amount, row.network)}</span>
                          <span className="token-raw"><code>{row.amount}</code></span>
                        </td>
                        <td>
                          <span className="badge" style={{ background: "#f1f5f9", color: "#334155" }}>
                            {row.event_count ?? 1} events
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <Pagination
                currentPage={currentPage}
                totalItems={rows.length}
                pageSize={pageSize}
                onPageChange={setCurrentPage}
                onPageSizeChange={(newSize) => {
                  setPageSize(newSize);
                  setCurrentPage(1);
                }}
              />
            </>
            )}
          </>
        )}
    </section>
  );
}
