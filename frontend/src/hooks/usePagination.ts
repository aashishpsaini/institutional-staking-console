import { useEffect, useMemo, useState } from "react";

/** Client-side pagination; resets to page 1 whenever `resetKey` changes. */
export function usePagination<T>(items: readonly T[], resetKey: unknown, initialPageSize = 10) {
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(initialPageSize);

  useEffect(() => setPage(1), [resetKey, pageSize]);

  const pageItems = useMemo(() => items.slice((page - 1) * pageSize, page * pageSize), [items, page, pageSize]);

  return { page, setPage, pageSize, setPageSize, pageItems };
}
