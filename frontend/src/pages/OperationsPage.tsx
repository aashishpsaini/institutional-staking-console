import { ChangeEvent, FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { apiGet, apiPost } from "../api";
import { Alert } from "../components/Alert";
import { Badge } from "../components/Badge";
import { CopyButton } from "../components/CopyButton";
import { EmptyState } from "../components/EmptyState";
import { Loading } from "../components/Loading";
import { Pagination } from "../components/Pagination";
import { useAsync } from "../hooks/useAsync";
import type {
  CreateOperationParams,
  OperationAction,
  OperationsResponse,
  OperationSingleResponse
} from "../types/operations";
import { formatDateTime, formatTokenAmount } from "../utils/formatters";

const initialForm: CreateOperationParams = {
  network: "ethereum",
  action: "stake",
  amount: ""
};

export default function OperationsPage() {
  const [form, setForm] = useState<CreateOperationParams>(initialForm);
  const [operationsState, fetchOperations] = useAsync<OperationsResponse>();
  const [submitState, submitOperation, resetSubmitState] = useAsync<OperationSingleResponse>();
  const [validationError, setValidationError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  const loadOperations = useCallback(() => {
    void fetchOperations(() => apiGet<OperationsResponse>("/api/v1/stake_operations"));
  }, [fetchOperations]);

  useEffect(() => {
    loadOperations();
  }, [loadOperations]);

  // Real-time polling for in-flight operations (pending or submitted)
  useEffect(() => {
    if (operationsState.status !== "success") return;

    const hasInFlight = operationsState.data.data.some(
      (op) => op.status === "pending" || op.status === "submitted"
    );

    if (!hasInFlight) return;

    const interval = setInterval(() => {
      loadOperations();
    }, 3500);

    return () => clearInterval(interval);
  }, [operationsState, loadOperations]);

  const handleNetworkChange = (event: ChangeEvent<HTMLSelectElement>) => {
    setForm((prev) => ({ ...prev, network: event.target.value }));
  };

  const handleActionChange = (event: ChangeEvent<HTMLSelectElement>) => {
    const action = event.target.value as OperationAction;
    setForm((prev) => ({ ...prev, action }));
  };

  const handleAmountChange = (event: ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, amount: event.target.value }));
    setValidationError(null);
  };

  const setPreset = (network: string, amount: string) => {
    setForm((prev) => ({ ...prev, network, amount }));
    setValidationError(null);
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const cleanAmount = form.amount.trim();

    if (!cleanAmount || !/^[1-9]\d*$/.test(cleanAmount)) {
      setValidationError("Amount must be a positive integer string without decimals (base units).");
      return;
    }

    resetSubmitState();
    const result = await submitOperation(() =>
      apiPost<OperationSingleResponse>("/api/v1/stake_operations", {
        network: form.network,
        action: form.action,
        amount: cleanAmount
      })
    );

    if (result) {
      setForm((prev) => ({ ...prev, amount: "" }));
      loadOperations();
    }
  };

  const isSubmitting = submitState.status === "loading";
  const operations = operationsState.status === "success" ? operationsState.data.data : [];

  const paginatedOperations = useMemo(() => {
    const startIndex = (currentPage - 1) * pageSize;
    return operations.slice(startIndex, startIndex + pageSize);
  }, [operations, currentPage, pageSize]);

  return (
    <section>
      <h1>Stake Operations</h1>
      <p className="subtitle">Execute and track institutional stake/unstake requests through the mock chain service boundary.</p>

      <div className="quick-filters">
        <span style={{ fontSize: "0.85rem", color: "#64748b", fontWeight: 600 }}>Quick Presets:</span>
        <button
          type="button"
          className="btn-pill"
          onClick={() => setPreset("ethereum", "32000000000000000000")}
        >
          32 ETH Validator
        </button>
        <button
          type="button"
          className="btn-pill"
          onClick={() => setPreset("ethereum", "1000000000000000000")}
        >
          1 ETH
        </button>
        <button
          type="button"
          className="btn-pill"
          onClick={() => setPreset("solana", "100000000000")}
        >
          100 SOL
        </button>
      </div>

      <form className="filters" onSubmit={handleSubmit}>
        <label>
          Network
          <select value={form.network} onChange={handleNetworkChange}>
            <option value="ethereum">Ethereum</option>
            <option value="solana">Solana</option>
          </select>
        </label>
        <label>
          Action
          <select value={form.action} onChange={handleActionChange}>
            <option value="stake">Stake</option>
            <option value="unstake">Unstake</option>
          </select>
        </label>
        <label style={{ flex: 1 }}>
          Amount (integer string in base units)
          <input
            placeholder="e.g. 32000000000000000000 (wei) or 100000000000 (lamports)"
            value={form.amount}
            onChange={handleAmountChange}
            required
          />
        </label>
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "Submitting Request…" : "Create Operation"}
        </button>
      </form>

      {validationError && <Alert variant="error">{validationError}</Alert>}
      {submitState.status === "error" && <Alert variant="error">{submitState.error}</Alert>}
      {submitState.status === "success" && (
        <Alert variant="success">
          Successfully submitted {submitState.data.data.action} request for {submitState.data.data.amount} on {submitState.data.data.network}. Transaction reference: {submitState.data.data.external_id}
        </Alert>
      )}

      {operationsState.status === "loading" && <Loading message="Loading operation records…" />}
      {operationsState.status === "error" && <Alert variant="error">{operationsState.error}</Alert>}

      {operationsState.status === "success" && (
        <>
          {operations.length === 0 ? (
            <EmptyState message="No operations have been recorded yet. Submit your first staking request using the form above." />
          ) : (
            <>
              <div className="table-container">
                <table>
                  <thead>
                    <tr>
                      <th>Timestamp</th>
                      <th>Network</th>
                      <th>Action</th>
                      <th>Amount</th>
                      <th>External Chain ID</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {paginatedOperations.map((operation) => (
                      <tr key={operation.id}>
                        <td>{formatDateTime(operation.created_at)}</td>
                        <td>
                          <strong style={{ textTransform: "capitalize" }}>{operation.network}</strong>
                        </td>
                        <td>
                          <span style={{ textTransform: "uppercase", fontSize: "0.82em", fontWeight: 700 }}>
                            {operation.action}
                          </span>
                        </td>
                        <td>
                          <span className="token-readable">{formatTokenAmount(operation.amount, operation.network)}</span>
                          <span className="token-raw"><code>{operation.amount}</code></span>
                        </td>
                        <td>
                          {operation.external_id ? (
                            <div style={{ display: "flex", alignItems: "center" }}>
                              <code>{operation.external_id}</code>
                              <CopyButton text={operation.external_id} />
                            </div>
                          ) : (
                            <span className="muted">—</span>
                          )}
                        </td>
                        <td>
                          <Badge status={operation.status}>{operation.status}</Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <Pagination
                currentPage={currentPage}
                totalItems={operations.length}
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
