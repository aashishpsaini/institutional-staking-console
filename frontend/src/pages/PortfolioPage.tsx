import { useEffect, useState } from "react";
import { apiGet } from "../api";

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

  useEffect(() => {
    apiGet<PortfolioResponse>("/api/v1/portfolio")
      .then(setData)
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p>Loading portfolio…</p>;
  if (error) return <p className="error">{error}</p>;
  if (!data?.data?.length) return <p>No portfolio rows yet. Implement API + sync.</p>;

  return (
    <section>
      <h1>Portfolio</h1>
      <p className="muted">Last synced: {data.last_synced_at ?? "—"}</p>
      <table>
        <thead>
          <tr>
            <th>Network</th>
            <th>Balance</th>
            <th>Total rewards</th>
          </tr>
        </thead>
        <tbody>
          {data.data.map((row) => (
            <tr key={row.protocol}>
              <td>{row.protocol}</td>
              <td>
                <code>{row.balance}</code>
              </td>
              <td>
                <code>{row.total_rewards_received}</code>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
