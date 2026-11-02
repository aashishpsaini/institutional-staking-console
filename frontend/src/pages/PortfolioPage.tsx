import { useEffect, useState } from "react";
import { apiGet, apiPost } from "../api";
import { Alert } from "../components/Alert";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { StatCard } from "../components/StatCard";
import { useAsync } from "../hooks/useAsync";
import type { PortfolioResponse, SyncResponse } from "../types/portfolio";
import { formatDate, formatDateTime, formatTokenAmount } from "../utils/formatters";

export default function PortfolioPage() {
  const [portfolioState, fetchPortfolio] = useAsync<PortfolioResponse>();
  const [syncState, runSync] = useAsync<SyncResponse>();
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    void fetchPortfolio(() => apiGet<PortfolioResponse>("/api/v1/portfolio"));
  }, [fetchPortfolio]);

  const handleSync = async () => {
    setNotice(null);
    const result = await runSync(() => apiPost<SyncResponse>("/api/v1/sync/rewards", {}));

    if (result) {
      setNotice("Background rewards sync initiated across all networks. Refreshing portfolio…");
      setTimeout(() => {
        void fetchPortfolio(() => apiGet<PortfolioResponse>("/api/v1/portfolio"));
        setNotice(null);
      }, 1500);
    }
  };

  const isSyncing = syncState.status === "loading";

  return (
    <section>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "1rem" }}>
        <div>
          <h1>Institutional Portfolio</h1>
          <p className="subtitle">Real-time custody balances and rewards aggregated through the chain service boundary.</p>
        </div>
        <button type="button" onClick={handleSync} disabled={isSyncing}>
          {isSyncing ? "Syncing on-chain rewards…" : "Sync Rewards"}
        </button>
      </div>

      {notice && <Alert variant="success">{notice}</Alert>}
      {syncState.status === "error" && <Alert variant="error">{syncState.error}</Alert>}

      {portfolioState.status === "loading" && <Loading message="Loading institutional portfolio balances…" />}
      {portfolioState.status === "error" && <Alert variant="error">{portfolioState.error}</Alert>}

      {portfolioState.status === "success" && (
        <>
          <div className="stat-grid">
            <StatCard
              title="Active Networks"
              value={portfolioState.data.data.length.toString()}
              subtitle="Ethereum & Solana positions"
            />
            <StatCard
              title="Rewards Synced"
              value={portfolioState.data.data.reduce((acc, curr) => acc + (BigInt(curr.total_rewards_received) > 0n ? 1 : 0), 0) > 0 ? "Active" : "Pending Sync"}
              subtitle="Multi-network event rollups"
              badge={<span className="badge confirmed">Ingested</span>}
            />
            <StatCard
              title="Last Sync Timestamp"
              value={portfolioState.data.last_synced_at ? formatDateTime(portfolioState.data.last_synced_at) : "Never"}
              subtitle="Automated audit trail"
            />
          </div>

          {portfolioState.data.data.length === 0 ? (
            <EmptyState
              message="No portfolio positions registered for this organization."
              action={
                <button type="button" onClick={handleSync} disabled={isSyncing}>
                  Sync Rewards Now
                </button>
              }
            />
          ) : (
            <div className="table-container">
              <table>
                <thead>
                  <tr>
                    <th>Network</th>
                    <th>Staked Position</th>
                    <th>Total Rewards Received</th>
                    <th>Position Started</th>
                    <th>Last Balance Check</th>
                  </tr>
                </thead>
                <tbody>
                  {portfolioState.data.data.map((row) => (
                    <tr key={row.protocol}>
                      <td>
                        <strong style={{ textTransform: "capitalize", fontSize: "1rem" }}>{row.protocol}</strong>
                      </td>
                      <td>
                        <span className="token-readable">{formatTokenAmount(row.balance, row.protocol)}</span>
                        <span className="token-raw"><code>{row.balance}</code></span>
                      </td>
                      <td>
                        <span className="token-readable">{formatTokenAmount(row.total_rewards_received, row.protocol)}</span>
                        <span className="token-raw"><code>{row.total_rewards_received}</code></span>
                      </td>
                      <td>{formatDate(row.started_at)}</td>
                      <td>{formatDateTime(row.updated_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </>
      )}
    </section>
  );
}
