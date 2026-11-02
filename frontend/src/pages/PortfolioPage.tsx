import { useEffect, useState } from "react";
import { apiGet, apiPost } from "../api";

type PortfolioResponse = {
  data: Array<{
    protocol: string;
    balance: string;
    total_rewards_received: string;
    updated_at?: string;
    started_at?: string;
  }>;
  last_synced_at?: string | null;
};

export default function PortfolioPage() {
  const [data, setData] = useState<PortfolioResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [syncing, setSyncing] = useState(false);
  const [syncMessage, setSyncMessage] = useState<string | null>(null);

  async function loadPortfolio() {
    setLoading(true);
    setError(null);
    try {
      const res = await apiGet<PortfolioResponse>("/api/v1/portfolio");
      setData(res);
    } catch (e) {
      setError(String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadPortfolio();
  }, []);

  async function handleSync() {
    setSyncing(true);
    setSyncMessage(null);
    setError(null);
    try {
      await apiPost("/api/v1/sync/rewards", {});
      setSyncMessage("Sync enqueued! Refreshing portfolio...");
      setTimeout(async () => {
        await loadPortfolio();
        setSyncing(false);
        setSyncMessage("Sync completed.");
      }, 1500);
    } catch (e) {
      setError(String(e));
      setSyncing(false);
    }
  }

  if (loading && !data) return <p>Loading portfolio…</p>;
  if (error && !data) return <p className="error">{error}</p>;

  return (
    <section>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "1rem" }}>
        <h1>Portfolio</h1>
        <button onClick={handleSync} disabled={syncing}>
          {syncing ? "Syncing rewards…" : "Sync Rewards"}
        </button>
      </div>

      <p className="muted">Last synced: {data?.last_synced_at ?? "Never"}</p>
      {syncMessage && <p style={{ color: "#1e648c", fontWeight: 500 }}>{syncMessage}</p>}
      {error && <p className="error">{error}</p>}

      {!data?.data?.length ? (
        <p>No portfolio rows yet. Run a sync above to fetch rewards.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Network</th>
              <th>Staked Balance</th>
              <th>Total Rewards Received</th>
              <th>Started At</th>
              <th>Last Updated</th>
            </tr>
          </thead>
          <tbody>
            {data.data.map((row) => (
              <tr key={row.protocol}>
                <td style={{ textTransform: "capitalize", fontWeight: 600 }}>{row.protocol}</td>
                <td>
                  <code>{row.balance}</code>
                </td>
                <td>
                  <code>{row.total_rewards_received}</code>
                </td>
                <td>{row.started_at ? new Date(row.started_at).toLocaleDateString() : "—"}</td>
                <td>{row.updated_at ? new Date(row.updated_at).toLocaleDateString() : "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
