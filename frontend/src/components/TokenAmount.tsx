import { useNetworks } from "../hooks/useNetworks";
import type { Network } from "../types/api";
import { formatTokenAmount } from "../utils/formatters";

interface TokenAmountProps {
  readonly amount: string;
  readonly network: string | Network;
}

/** Human-readable amount with the exact base-unit value underneath for auditability. */
export function TokenAmount({ amount, network }: TokenAmountProps) {
  const { bySlug } = useNetworks();
  const details = typeof network === "string" ? bySlug(network) : network;

  return (
    <>
      <span className="token-readable">{formatTokenAmount(amount, details)}</span>
      <span className="token-raw">
        <code>{amount}</code>
      </span>
    </>
  );
}
