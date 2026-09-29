// Types mirroring backend/models.py and backend/vocabulary.py.

export type GrowthStage = "spawn_run" | "pinning" | "fruiting";
export type InferenceMode = "backward" | "forward";

export interface VocabItem {
  value: string;
  label: string;
}

export interface ConditionSpec {
  key: string;
  type?: "category" | "number";
  options?: string[];
  unit?: string;
  label: string;
}

export interface Vocabulary {
  growth_stages: VocabItem[];
  symptoms: VocabItem[];
  conditions: ConditionSpec[];
  hygiene: ConditionSpec[];
  room: ConditionSpec[];
  days_since_spawning: { type: string; unit: string; label: string };
}

export interface ConsultationRequest {
  growth_stage?: GrowthStage;
  days_since_spawning?: number;
  symptoms: string[];
  conditions: Record<string, string | number>;
  hygiene: Record<string, string>;
  room: Record<string, string>;
  mode: InferenceMode;
}

export interface Diagnosis {
  problem: string;
  label: string;
  evidence: string[];
  rules_applied: string[];
  explanation: string;
  recommendation: string;
}

export interface ConsultationResponse {
  mode: InferenceMode;
  diagnoses: Diagnosis[];
}
