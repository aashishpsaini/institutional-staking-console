import { useEffect, useState } from "react";

interface CopyButtonProps {
  readonly text: string;
}

export function CopyButton({ text }: CopyButtonProps) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) return;
    const id = window.setTimeout(() => setCopied(false), 2000);
    return () => window.clearTimeout(id);
  }, [copied]);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
    } catch {
      // Clipboard can be unavailable (permissions, insecure context); the value stays selectable.
    }
  };

  return (
    <button type="button" className="btn-copy" onClick={handleCopy} aria-label={`Copy ${text}`}>
      {copied ? "✓ Copied" : "Copy"}
    </button>
  );
}
