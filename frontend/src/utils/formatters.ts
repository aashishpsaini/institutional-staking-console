import type { Network } from "../types/api";

const BASE_UNITS = /^\d+$/;
const TOKEN_INPUT = /^(\d+)(?:\.(\d*))?$/;

function groupThousands(digits: string): string {
  return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Converts a base-unit integer string (wei, lamports) into a token string,
 * e.g. formatUnits("1500000000000000000", 18) → "1.5". Pure BigInt/string math,
 * so 18-decimal amounts never lose precision through IEEE floats.
 */
export function formatUnits(raw: string, decimals: number, maxFractionDigits = 6): string {
  if (!BASE_UNITS.test(raw)) return raw;

  const value = BigInt(raw);
  const base = 10n ** BigInt(decimals);
  const whole = groupThousands((value / base).toString());
  const fraction = (value % base).toString().padStart(decimals, "0").slice(0, maxFractionDigits).replace(/0+$/, "");

  if (fraction) return `${whole}.${fraction}`;
  return value > 0n && value < base ? `<0.${"0".repeat(Math.max(maxFractionDigits - 1, 0))}1` : whole;
}

/**
 * Inverse of formatUnits for user input: parseUnits("1.5", 18) → "1500000000000000000".
 * Returns null for malformed input or more fractional digits than the token supports.
 */
export function parseUnits(input: string, decimals: number): string | null {
  const match = TOKEN_INPUT.exec(input.trim());
  if (!match) return null;

  const [, whole = "0", fraction = ""] = match;
  if (fraction.length > decimals) return null;

  return (BigInt(whole) * 10n ** BigInt(decimals) + BigInt(fraction.padEnd(decimals, "0") || "0")).toString();
}

export function formatTokenAmount(raw: string, network: Network | undefined): string {
  if (!network) return raw;
  return `${formatUnits(raw, network.decimals)} ${network.symbol}`;
}

export function sumAmounts(amounts: readonly string[]): string {
  return amounts.reduce((total, amount) => total + BigInt(amount), 0n).toString();
}

export function formatDate(isoDate: string | null | undefined): string {
  if (!isoDate) return "—";
  // Date-only strings are parsed as local dates; `new Date("2024-06-01")` would be UTC midnight
  // and render as the previous day west of Greenwich.
  const [year, month, day] = isoDate.slice(0, 10).split("-").map(Number);
  if (!year || !month || !day) return "—";
  return new Date(year, month - 1, day).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

export function formatDateTime(isoString: string | null | undefined): string {
  if (!isoString) return "—";
  const date = new Date(isoString);
  return Number.isNaN(date.getTime())
    ? "—"
    : date.toLocaleString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

/** Local calendar date as YYYY-MM-DD (toISOString() would shift to UTC). */
export function toISODate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

export function daysAgo(days: number, from: Date = new Date()): string {
  const date = new Date(from);
  date.setDate(date.getDate() - days);
  return toISODate(date);
}
