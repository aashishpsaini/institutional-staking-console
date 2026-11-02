import { useState } from "react";

interface CopyButtonProps {
  readonly text: string;
  readonly label?: string;
}

export function CopyButton({ text, label }: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
    }
  };

  return (
    <button
      type="button"
      className="btn-copy"
      onClick={handleCopy}
      title="Copy to clipboard"
    >
      {copied ? "✓ Copied" : label ?? "Copy"}
    </button>
  );
}

