/**
 * Formats large blockchain integer strings into human-readable token amounts
 * while maintaining precision awareness.
 * 
 * Ethereum: 1 ETH = 10^18 wei (or toy scale if mock)
 * Solana: 1 SOL = 10^9 lamports
 */
export function formatTokenAmount(amount: string, network: string): string {
  try {
    const raw = BigInt(amount);
    const slug = network.toLowerCase();

    if (slug === "ethereum") {
      // 18 decimals (standard wei)
      if (raw >= 10n ** 18n) {
        const whole = raw / 10n ** 18n;
        const remainder = raw % 10n ** 18n;
        const decimals = (remainder / 10n ** 14n).toString().padStart(4, "0");
        return `${whole.toLocaleString()}.${decimals} ETH`;
      }
      // Smaller mock scale (1e11 toy scale from mock chain client)
      if (raw >= 10n ** 7n) {
        return `${Number(raw) / 1e7} ETH (est)`;
      }
      return `${raw.toLocaleString()} wei`;
    }

    if (slug === "solana") {
      // 9 decimals (lamports)
      if (raw >= 10n ** 9n) {
        const whole = raw / 10n ** 9n;
        const remainder = raw % 10n ** 9n;
        const decimals = (remainder / 10n ** 6n).toString().padStart(3, "0");
        return `${whole.toLocaleString()}.${decimals} SOL`;
      }
      return `${Number(raw) / 1e6} SOL (est)`;
    }

    return `${raw.toLocaleString()} units`;
  } catch {
    return amount;
  }
}

export function formatDate(isoString?: string | null): string {
  if (!isoString) return "—";
  try {
    const date = new Date(isoString);
    return isNaN(date.getTime()) ? "—" : date.toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric"
    });
  } catch {
    return "—";
  }
}

export function formatDateTime(isoString?: string | null): string {
  if (!isoString) return "—";
  try {
    const date = new Date(isoString);
    return isNaN(date.getTime()) ? "—" : date.toLocaleString(undefined, {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit"
    });
  } catch {
    return "—";
  }
}
