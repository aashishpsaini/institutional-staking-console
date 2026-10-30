import { FormEvent, useState } from "react";
import { apiGet } from "../api";

type RewardsResponse = {
  data: Array<{
    network: string;
    date: string;
    amount: string;
  }>;
};

export default function RewardsPage() {
  const [network, setNetwork] = useState("");
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");
  const [rows, setRows] = useState<RewardsResponse["data"]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    const params = new URLSearchParams();
    if (network) params.set("network", network);
    if (start) params.set("start", start);
    if (end) params.set("end", end);
    try {
      const res = await apiGet<RewardsResponse>(`/api/v1/rewards?${params}`);
      setRows(res.data ?? []);
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <section>
      <h1>Rewards</h1>
      <form className="filters" onSubmit={onSubmit}>
        <label>
          Network
          <select value={network} onChange={(e) => setNetwork(e.target.value)}>
            <option value="">All</option>
            <option value="ethereum">ethereum</option>
            <option value="solana">solana</option>
          </select>
        </label>
        <label>
          Start
          <input type="date" value={start} onChange={(e) => setStart(e.target.value)} />
        </label>
        <label>
          End
          <input type="date" value={end} onChange={(e) => setEnd(e.target.value)} />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "Loading…" : "Apply"}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
      {!error && !rows.length && <p>No rows. Implement rewards API, then filter.</p>}
      {!!rows.length && (
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Network</th>
              <th>Amount</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((r) => (
              <tr key={`${r.network}-${r.date}-${r.amount}`}>
                <td>{r.date}</td>
                <td>{r.network}</td>
                <td>
                  <code>{r.amount}</code>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
