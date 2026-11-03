import { FormEvent, useEffect, useRef, useState } from "react";
import { api } from "../api";
import { Alert } from "../components/Alert";
import { Badge } from "../components/Badge";
import { CopyButton } from "../components/CopyButton";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { Pagination } from "../components/Pagination";
import { TokenAmount } from "../components/TokenAmount";
import { useInterval } from "../hooks/useInterval";
import { useNetworks } from "../hooks/useNetworks";
import { usePagination } from "../hooks/usePagination";
import { useQuery } from "../hooks/useQuery";
import { IN_FLIGHT_STATUSES, type CreateStakeOperation, type OperationAction, type StakeOperation } from "../types/api";
import { formatDateTime, formatTokenAmount, parseUnits } from "../utils/formatters";

const POLL_MS = 3000;

const PRESETS = [
  { label: "32 ETH validator", network: "ethereum", amount: "32" },
  { label: "1 ETH", network: "ethereum", amount: "1" },
  { label: "100 SOL", network: "solana", amount: "100" }
] as const;

export default function OperationsPage() {
  const { networks, bySlug } = useNetworks();
  const operations = useQuery((signal) => api.stakeOperations(signal), []);

  const [networkSlug, setNetworkSlug] = useState("");
  const [action, setAction] = useState<OperationAction>("stake");
  const [amountInput, setAmountInput] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [lastCreated, setLastCreated] = useState<StakeOperation | null>(null);

  // One Idempotency-Key per distinct payload: retrying the same request after a
  // timeout reuses the key (server returns the original), editing the form mints a new one.
  const attempt = useRef<{ signature: string; key: string } | null>(null);

  useEffect(() => {
    if (!networkSlug && networks[0]) setNetworkSlug(networks[0].slug);
  }, [networks, networkSlug]);

  const network = bySlug(networkSlug);
  const baseUnits = network ? parseUnits(amountInput, network.decimals) : null;
  const amountError =
    amountInput.trim() === "" ? null : baseUnits === null || baseUnits === "0" ? `Enter a positive amount with at most ${network?.decimals ?? 0} decimals.` : null;

  const rows = operations.data ?? [];
  const hasInFlight = rows.some((op) => IN_FLIGHT_STATUSES.includes(op.status));
  // Silent refresh: existing rows stay rendered while statuses update.
  useInterval(operations.reload, POLL_MS, hasInFlight);

  const { page, setPage, pageSize, setPageSize, pageItems } = usePagination(rows, null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!network || !baseUnits || baseUnits === "0") return;

    const payload: CreateStakeOperation = { network: network.slug, action, amount: baseUnits };
    const signature = JSON.stringify(payload);
    if (attempt.current?.signature !== signature) attempt.current = { signature, key: crypto.randomUUID() };

    setIsSubmitting(true);
    setSubmitError(null);
    setLastCreated(null);
    try {
      const created = await api.createStakeOperation(payload, attempt.current.key);
      attempt.current = null;
      setLastCreated(created);
      setAmountInput("");
      operations.reload();
    } catch (error) {
      setSubmitError(error instanceof Error ? error.message : "Failed to create operation");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <section>
      <h1>Stake operations</h1>
      <p className="subtitle">Create stake/unstake requests and track them from pending → submitted → confirmed or failed.</p>

      <form className="stake-form" onSubmit={handleSubmit} noValidate>
        <div className="stake-form-row">
          <label>
            Network
            <select value={networkSlug} onChange={(e) => setNetworkSlug(e.target.value)} disabled={networks.length === 0}>
              {networks.map((n) => (
                <option key={n.slug} value={n.slug}>
                  {n.display_name}
                </option>
              ))}
            </select>
          </label>

          <div className="field">
            <span className="field-label" id="action-label">
              Action
            </span>
            <div className="segmented" role="radiogroup" aria-labelledby="action-label">
              {(["stake", "unstake"] as const).map((option) => (
                <button
                  key={option}
                  type="button"
                  role="radio"
                  aria-checked={action === option}
                  className={action === option ? "active" : ""}
                  onClick={() => setAction(option)}
                >
                  {option === "stake" ? "Stake" : "Unstake"}
                </button>
              ))}
            </div>
          </div>

          <label className="grow">
            Amount
            <div className={`input-affix ${amountError ? "invalid" : ""}`}>
              <input
                inputMode="decimal"
                autoComplete="off"
                placeholder="0.0"
                value={amountInput}
                onChange={(e) => setAmountInput(e.target.value)}
                aria-invalid={amountError !== null}
                aria-describedby="amount-hint"
              />
              <span className="affix">{network?.symbol ?? ""}</span>
            </div>
          </label>

          <button type="submit" className="stake-submit" disabled={isSubmitting || !baseUnits || baseUnits === "0" || !network}>
            {isSubmitting ? "Submitting…" : action === "stake" ? "Stake" : "Unstake"}
          </button>
        </div>

        <div className="stake-form-footer">
          <div className="quick-fill" role="group" aria-label="Amount presets">
            <span className="quick-filters-label">Quick fill</span>
            {PRESETS.map((preset) => (
              <button
                key={preset.label}
                type="button"
                className="btn-pill"
                onClick={() => {
                  setNetworkSlug(preset.network);
                  setAmountInput(preset.amount);
                }}
              >
                {preset.label}
              </button>
            ))}
          </div>
          <span id="amount-hint" className={amountError ? "field-error" : "hint"} aria-live="polite">
            {amountError ??
              (baseUnits && network
                ? `Sends ${baseUnits} base units`
                : "Enter the amount in tokens; it is converted to base units (wei / lamports)")}
          </span>
        </div>
      </form>

      {submitError && <Alert variant="error">{submitError}</Alert>}
      {lastCreated && (
        <Alert variant={lastCreated.status === "failed" ? "error" : "success"}>
          {lastCreated.status === "failed"
            ? `The chain rejected the ${lastCreated.action}: ${lastCreated.error_message ?? "unknown error"}`
            : `${lastCreated.action === "stake" ? "Stake" : "Unstake"} of ${formatTokenAmount(lastCreated.amount, bySlug(lastCreated.network))} submitted (ref ${lastCreated.external_id}). Status updates automatically.`}
        </Alert>
      )}

      {operations.isLoading && <Loading message="Loading operations…" />}
      {operations.error && <Alert variant="error">{operations.error}</Alert>}

      {operations.data &&
        (rows.length === 0 ? (
          <EmptyState message="No operations yet. Submit a stake request using the form above." />
        ) : (
          <>
            <div className="table-container">
              <table>
                <thead>
                  <tr>
                    <th>Created</th>
                    <th>Network</th>
                    <th>Action</th>
                    <th>Amount</th>
                    <th>Chain reference</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {pageItems.map((op) => (
                    <tr key={op.id}>
                      <td>{formatDateTime(op.created_at)}</td>
                      <td className="capitalize">{op.network}</td>
                      <td className="action-cell">{op.action}</td>
                      <td>
                        <TokenAmount amount={op.amount} network={op.network} />
                      </td>
                      <td>
                        {op.external_id ? (
                          <div className="inline">
                            <code>{op.external_id}</code>
                            <CopyButton text={op.external_id} />
                          </div>
                        ) : (
                          <span className="muted">—</span>
                        )}
                      </td>
                      <td>
                        <Badge status={op.status} />
                        {op.error_message && <span className="field-error">{op.error_message}</span>}
                      </td>
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
