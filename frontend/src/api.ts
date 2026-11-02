import type { ApiErrorResponse } from "./types/api";

const API_BASE = import.meta.env.VITE_API_BASE ?? "";
const API_KEY = import.meta.env.VITE_API_KEY ?? "demo-key";

  export class ApiError extends Error {
    readonly status: number;
    readonly details: readonly string[];

    constructor(status: number, message: string, details: readonly string[] = []) {
      super(message);
      this.name = "ApiError";
      this.status = status;
      this.details = details;
    }
  }

  async function handleResponse<T>(res: Response): Promise<T> {
    if (res.ok) {
      return (await res.json()) as T;
    }

    let errorMessage = `HTTP Error ${res.status}: ${res.statusText}`;
    let errorDetails: readonly string[] = [];

    try {
      const errorBody = (await res.json()) as ApiErrorResponse;
      if (errorBody.details && Array.isArray(errorBody.details)) {
        errorDetails = errorBody.details;
        errorMessage = errorDetails.join(", ");
      } else if (errorBody.error) {
        errorMessage = errorBody.error;
      } else if (errorBody.message) {
        errorMessage = errorBody.message;
      }
    } catch {
      // Response was not JSON
    }

    throw new ApiError(res.status, errorMessage, errorDetails);
  }

  export async function apiGet<T>(path: string): Promise<T> {
    const res = await fetch(`${API_BASE}${path}`, {
      headers: {
        "X-Api-Key": API_KEY,
        Accept: "application/json"
      }
    });

    return handleResponse<T>(res);
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

    return handleResponse<T>(res);
  }
