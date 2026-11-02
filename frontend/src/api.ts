const API_BASE = import.meta.env.VITE_API_BASE ?? "";
const API_KEY = import.meta.env.VITE_API_KEY ?? "demo-key";

async function handleError(res: Response, _path: string): Promise<never> {
  let message = `${res.status} ${res.statusText}`;
  try {
    const errorBody = await res.json();
    if (errorBody.details && Array.isArray(errorBody.details)) {
      message = errorBody.details.join(", ");
    } else if (errorBody.error) {
      message = errorBody.error;
    } else if (errorBody.message) {
      message = errorBody.message;
    }
  } catch {
    // response was not JSON
  }
  throw new Error(message);
}

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: {
      "X-Api-Key": API_KEY,
      Accept: "application/json"
    }
  });
  if (!res.ok) {
    return handleError(res, path);
  }
  return res.json() as Promise<T>;
}

export async function apiPost<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: {
      "X-Api-Key": API_KEY,
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });
  if (!res.ok) {
    return handleError(res, path);
  }
  return res.json() as Promise<T>;
}
