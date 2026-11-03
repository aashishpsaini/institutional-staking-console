import { useState } from "react";
import { api } from "../api";
import { Alert } from "../components/Alert";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { StatCard } from "../components/StatCard";
import { TokenAmount } from "../components/TokenAmount";
import { useInterval } from "../hooks/useInterval";
import { useQuery } from "../hooks/useQuery";
import type { SyncRun } from "../types/api";
import { formatDate, formatDateTime } from "../utils/formatters";

const SYNC_POLL_MS = 1000;

export default function PortfolioPage() {
  const portfolio = useQuery((signal) => api.portfolio(signal), []);
  const [syncRun, setSyncRun] = useState<SyncRun | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);
  const [isRequestingSync, setIsRequestingSync] = useState(false);

  const isSyncing = isRequestingSync || syncRun?.status === "queued" || syncRun?.status === "running";

  // The API returns a SyncRun immediately (202); poll it until the background job finishes.
  useInterval(
    () => {
      if (!syncRun) return;
      api
        .syncRun(syncRun.id)
        .then((next) => {
          setSyncRun(next);
          if (next.status === "completed") portfolio.reload();
        })
        .catch((error: unknown) => {
          setSyncError(error instanceof Error ? error.message : "Failed to check sync status");
          setSyncRun(null);
        });
    },
    SYNC_POLL_MS,
    syncRun?.status === "queued" || syncRun?.status === "running"
  );

  const startSync = async () => {
    setSyncError(null);
    setIsRequestingSync(true);
    try {
      setSyncRun(await api.syncRewards());
    } catch (error) {
      setSyncError(error instanceof Error ? error.message : "Failed to start sync");
    } finally {
      setIsRequestingSync(false);
    }
  };

  const positions = portfolio.data?.data ?? [];
  const activePositions = positions.filter((p) => p.validator_count > 0);
  const validatorCount = positions.reduce((sum, p) => sum + p.validator_count, 0);

  return (
    <section>
      <div className="page-header">
        <div>
          <h1>Portfolio</h1>
          <p className="subtitle">Staked balances and rewards received per network, computed from synced chain data.</p>
        </div>
        <button type="button" onClick={startSync} disabled={isSyncing}>
          {isSyncing ? "Syncing rewards…" : "Sync rewards"}
        </button>
      </div>

      {syncError && <Alert variant="error">{syncError}</Alert>}
      {syncRun?.status === "completed" && (
        <Alert variant="success">
          Sync complete — {syncRun.records_upserted} reward events reconciled for {formatDate(syncRun.from)} – {formatDate(syncRun.to)}.
        </Alert>
      )}
      {syncRun?.status === "failed" && <Alert variant="error">Sync failed: {syncRun.error_message ?? "unknown error"}</Alert>}

      {portfolio.isLoading && <Loading message="Loading portfolio…" />}
      {portfolio.error && (
        <Alert variant="error">
          {portfolio.error}{" "}
          <button type="button" className="btn-link" onClick={portfolio.reload}>
            Retry
          </button>
        </Alert>
      )}

      {portfolio.data && (
        <>
          <div className="stat-grid">
            <StatCard title="Networks staked" value={`${activePositions.length} / ${positions.length}`} subtitle="Networks with at least one validator" />
            <StatCard title="Validators" value={String(validatorCount)} subtitle="Delegated positions across networks" />
            <StatCard
              title="Last rewards sync"
              value={portfolio.data.meta.last_synced_at ? formatDateTime(portfolio.data.meta.last_synced_at) : "Never"}
              subtitle={portfolio.data.meta.last_synced_at ? "Most recent completed sync" : "Run a sync to ingest rewards"}
            />
          </div>

          {positions.length === 0 ? (
            <EmptyState message="No networks are configured yet." />
          ) : (
            <div className="table-container" aria-busy={portfolio.isRefreshing}>
              <table>
                <thead>
                  <tr>
                    <th>Network</th>
                    <th>Validators</th>
                    <th>Staked balance</th>
                    <th>Total rewards received</th>
                    <th>Position started</th>
                    <th>Balance updated</th>
                  </tr>
                </thead>
                <tbody>
                  {positions.map((row) => (
                    <tr key={row.network}>
                      <td>
                        <strong className="token-readable">{row.network_details.display_name}</strong>
                        <span className="token-raw">{row.network_details.symbol}</span>
                      </td>
                      <td>{row.validator_count}</td>
                      <td>
                        <TokenAmount amount={row.balance} network={row.network_details} />
                      </td>
                      <td>
                        <TokenAmount amount={row.total_rewards_received} network={row.network_details} />
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
