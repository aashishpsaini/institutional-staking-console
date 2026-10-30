import { FormEvent, useEffect, useState } from "react";
import { apiGet, apiPost } from "../api";

type Operation = {
  id: number;
  network: string;
  action: string;
  amount: string;
  status: string;
  external_id?: string | null;
  created_at: string;
};

export default function OperationsPage() {
  const [ops, setOps] = useState<Operation[]>([]);
  const [network, setNetwork] = useState("ethereum");
  const [action, setAction] = useState("stake");
  const [amount, setAmount] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function refresh() {
    const res = await apiGet<{ data: Operation[] }>("/api/v1/stake_operations");
    setOps(res.data ?? []);
  }

  useEffect(() => {
    refresh().catch((e) => setError(String(e)));
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      // TODO(candidate): ensure backend create is implemented
      await apiPost("/api/v1/stake_operations", { network, action, amount });
      await refresh();
      setAmount("");
    } catch (err) {
      setError(String(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <section>
      <h1>Stake operations</h1>
      <form className="filters" onSubmit={onSubmit}>
        <label>
          Network
          <select value={network} onChange={(e) => setNetwork(e.target.value)}>
            <option value="ethereum">ethereum</option>
            <option value="solana">solana</option>
          </select>
        </label>
        <label>
          Action
          <select value={action} onChange={(e) => setAction(e.target.value)}>
            <option value="stake">stake</option>
            <option value="unstake">unstake</option>
          </select>
        </label>
        <label>
          Amount (integer string)
          <input value={amount} onChange={(e) => setAmount(e.target.value)} required />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "Submitting…" : "Create"}
        </button>
      </form>
      {error && <p className="error">{error}</p>}
      <table>
        <thead>
          <tr>
            <th>Created</th>
            <th>Network</th>
            <th>Action</th>
            <th>Amount</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          {ops.map((op) => (
            <tr key={op.id}>
              <td>{op.created_at}</td>
              <td>{op.network}</td>
              <td>{op.action}</td>
              <td>
                <code>{op.amount}</code>
              </td>
              <td>
                <span className={`badge ${op.status}`}>{op.status}</span>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
