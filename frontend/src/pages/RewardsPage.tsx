import { FormEvent, useEffect, useState } from "react";
import { apiGet } from "../api";

type RewardsResponse = {
  data: Array<{
    network: string;
    date: string;
    amount: string;
    event_count?: number;
  }>;
};

export default function RewardsPage() {
  const [network, setNetwork] = useState("");
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [rows, setRows] = useState<RewardsResponse["data"]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function fetchRewards(filters = { network, start, end }) {
    setLoading(true);
    setError(null);
    const params = new URLSearchParams();
    if (filters.network) params.set("network", filters.network);
    if (filters.start) params.set("start", filters.start);
    if (filters.end) params.set("end", filters.end);

    try {
      const res = await apiGet<RewardsResponse>(`/api/v1/rewards?${params}`);
      setRows(res.data ?? []);
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    fetchRewards({ network: "", start: "", end: "" });
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    await fetchRewards({ network, start, end });
  }

  function handleReset() {
    setNetwork("");
    setStart("");
    setEnd("");
    fetchRewards({ network: "", start: "", end: "" });
  }

  return (
    <section>
      <h1>Rewards Reporting</h1>
      <form className="filters" onSubmit={onSubmit}>
        <label>
          Network
          <select value={network} onChange={(e) => setNetwork(e.target.value)}>
            <option value="">All Networks</option>
            <option value="ethereum">Ethereum</option>
            <option value="solana">Solana</option>
          </select>
        </label>
        <label>
          Start Date
          <input type="date" value={start} onChange={(e) => setStart(e.target.value)} />
        </label>
        <label>
          End Date
          <input type="date" value={end} onChange={(e) => setEnd(e.target.value)} />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "Loading…" : "Apply Filters"}
        </button>
        <button type="button" onClick={handleReset} disabled={loading} style={{ background: "#6c757d" }}>
          Reset
        </button>
      </form>

      {error && <p className="error">{error}</p>}
      {!error && !loading && !rows.length && (
        <p>No rewards found for the selected criteria. Ensure rewards have been synced from the Portfolio page.</p>
      )}

      {!!rows.length && (
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Network</th>
              <th>Total Daily Reward</th>
              <th>Events Count</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={`${r.network}-${r.date}-${r.amount}`}>
                <td>{r.date}</td>
                <td style={{ textTransform: "capitalize", fontWeight: 600 }}>{r.network}</td>
                <td>
                  <code>{r.amount}</code>
                </td>
                <td>{r.event_count ?? 1}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
