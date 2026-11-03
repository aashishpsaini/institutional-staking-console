import { describe, expect, it } from "vitest";
import { daysAgo, formatDate, formatTokenAmount, formatUnits, parseUnits, sumAmounts, toISODate } from "./formatters";

const ETH = { slug: "ethereum", display_name: "Ethereum", symbol: "ETH", decimals: 18 };

describe("formatUnits", () => {
  it("formats whole and fractional token amounts", () => {
    expect(formatUnits("32000000000000000000", 18)).toBe("32");
    expect(formatUnits("1500000000000000000", 18)).toBe("1.5");
    expect(formatUnits("100000000000", 9)).toBe("100");
  });

  it("groups thousands and keeps precision beyond Number.MAX_SAFE_INTEGER", () => {
    expect(formatUnits("123456789012345678901234567", 18)).toBe("123,456,789.012345");
  });

  it("signals dust instead of rounding it to zero", () => {
    expect(formatUnits("10000000", 18)).toBe("<0.000001");
    expect(formatUnits("0", 18)).toBe("0");
  });

  it("passes through non-integer strings untouched", () => {
    expect(formatUnits("abc", 18)).toBe("abc");
  });
});

describe("parseUnits", () => {
  it("converts token input to base units", () => {
    expect(parseUnits("1.5", 18)).toBe("1500000000000000000");
    expect(parseUnits("32", 18)).toBe("32000000000000000000");
    expect(parseUnits("0.000000001", 9)).toBe("1");
    expect(parseUnits(" 100. ", 9)).toBe("100000000000");
  });

  it("rejects malformed or over-precise input", () => {
    expect(parseUnits("", 18)).toBeNull();
    expect(parseUnits("-1", 18)).toBeNull();
    expect(parseUnits("1e18", 18)).toBeNull();
    expect(parseUnits("0.0000000001", 9)).toBeNull();
  });

  it("round-trips with formatUnits", () => {
    expect(formatUnits(parseUnits("12.345678", 18) ?? "", 18)).toBe("12.345678");
  });
});

describe("helpers", () => {
  it("formats amounts with the network symbol", () => {
    expect(formatTokenAmount("2500000000000000000", ETH)).toBe("2.5 ETH");
  });

  it("sums integer strings with BigInt", () => {
    expect(sumAmounts(["9007199254740993", "1"])).toBe("9007199254740994");
  });

  it("works with local calendar dates", () => {
    expect(toISODate(new Date(2024, 0, 5))).toBe("2024-01-05");
    expect(daysAgo(7, new Date(2024, 2, 3))).toBe("2024-02-25");
    expect(formatDate("2024-06-01")).toContain("2024");
  });
});
