import type { ConsultationRequest, ConsultationResponse, Vocabulary } from "./types";

const API_BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000";

export async function fetchVocabulary(): Promise<Vocabulary> {
  const res = await fetch(`${API_BASE}/vocabulary`, { cache: "no-store" });
  if (!res.ok) {
    throw new Error(`Failed to load vocabulary (${res.status})`);
  }
  return res.json();
}

export async function runConsultation(
  request: ConsultationRequest
): Promise<ConsultationResponse> {
  const res = await fetch(`${API_BASE}/consult`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(request),
    cache: "no-store",
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    const detail =
      typeof body?.detail === "string"
        ? body.detail
        : JSON.stringify(body?.detail ?? `HTTP ${res.status}`);
    throw new Error(detail);
  }
  return res.json();
}
