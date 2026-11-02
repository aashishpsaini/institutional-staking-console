import { FormEvent, useEffect, useState } from "react";
import { apiGet, apiPost } from "../api";

type Operation = {
  id: number;
  network: string;
  action: string;
  amount: string;
  status: string;
  external_id?: string | null;
  error_message?: string | null;
  created_at: string;
};

export default function OperationsPage() {
  const [ops, setOps] = useState<Operation[]>([]);
  const [network, setNetwork] = useState("ethereum");
  const [action, setAction] = useState("stake");
  const [amount, setAmount] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function refresh() {
    try {
      const res = await apiGet<{ data: Operation[] }>("/api/v1/stake_operations");
      setOps(res.data ?? []);
    } catch (e) {
      setError(String(e));
    }
  }

  useEffect(() => {
    refresh();
  }, []);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!/^\d+$/.test(amount.trim()) || BigInt(amount.trim()) <= 0n) {
      setError("Amount must be a positive integer string (no decimals).");
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      await apiPost("/api/v1/stake_operations", { network, action, amount: amount.trim() });
      setSuccess(`Successfully submitted ${action} request for ${amount} on ${network}.`);
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
      <h1>Stake Operations</h1>
      <p className="muted">Submit stake and unstake requests through the institutional service boundary.</p>

      <form className="filters" onSubmit={onSubmit} style={{ marginTop: "1rem" }}>
        <label>
          Network
          <select value={network} onChange={(e) => setNetwork(e.target.value)}>
            <option value="ethereum">Ethereum</option>
            <option value="solana">Solana</option>
          </select>
        </label>
        <label>
          Action
          <select value={action} onChange={(e) => setAction(e.target.value)}>
            <option value="stake">Stake</option>
            <option value="unstake">Unstake</option>
          </select>
        </label>
        <label>
          Amount (integer string)
          <input
            placeholder="e.g. 1000000000"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
          />
        </label>
        <button type="submit" disabled={loading}>
          {loading ? "Submitting…" : "Create Operation"}
        </button>
      </form>

      {error && <p className="error">{error}</p>}
      {success && <p style={{ color: "#2d7a4c", fontWeight: 500 }}>{success}</p>}

      {!ops.length ? (
        <p>No operations created yet.</p>
      ) : (
        <table>
          <thead>
            <tr>
              <th>Created At</th>
              <th>Network</th>
              <th>Action</th>
              <th>Amount</th>
              <th>External ID</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {ops.map((op) => (
              <tr key={op.id}>
                <td>{new Date(op.created_at).toLocaleString()}</td>
                <td style={{ textTransform: "capitalize", fontWeight: 600 }}>{op.network}</td>
                <td>
                  <span style={{ textTransform: "uppercase", fontSize: "0.85em", fontWeight: "bold" }}>
                    {op.action}
                  </span>
                </td>
                <td>
                  <code>{op.amount}</code>
                </td>
                <td>
                  <code style={{ fontSize: "0.85em", color: "#555" }}>{op.external_id ?? "—"}</code>
                </td>
                <td>
                  <span className={`badge ${op.status}`}>{op.status}</span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </section>
  );
}
