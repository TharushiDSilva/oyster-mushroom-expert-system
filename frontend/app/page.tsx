"use client";

import { useEffect, useMemo, useState } from "react";
import { fetchVocabulary, runConsultation } from "@/lib/api";
import type {
  ConditionSpec,
  ConsultationResponse,
  InferenceMode,
  Vocabulary,
} from "@/lib/types";
import DiagnosisCard from "@/components/DiagnosisCard";
import SectionHeader from "@/components/SectionHeader";
import MushroomScene from "@/components/MushroomScene";

type FieldValues = Record<string, string>;

const fieldClasses =
  "rounded-xl border border-border bg-background px-3 py-2 text-foreground placeholder:text-muted/70 outline-none transition focus:border-accent focus:ring-2 focus:ring-accent/25";

function ConditionField({
  spec,
  value,
  onChange,
}: {
  spec: ConditionSpec;
  value: string;
  onChange: (key: string, value: string) => void;
}) {
  if (spec.type === "number") {
    return (
      <label className="flex flex-col gap-1.5 text-sm">
        <span className="font-medium text-muted">
          {spec.label}
          {spec.unit ? ` (${spec.unit})` : ""}
        </span>
        <input
          type="number"
          value={value}
          onChange={(e) => onChange(spec.key, e.target.value)}
          className={fieldClasses}
          placeholder="not measured"
        />
      </label>
    );
  }
  return (
    <label className="flex flex-col gap-1.5 text-sm">
      <span className="font-medium text-muted">{spec.label}</span>
      <select
        value={value}
        onChange={(e) => onChange(spec.key, e.target.value)}
        className={fieldClasses}
      >
        <option value="">-- not reported --</option>
        {spec.options?.map((opt) => (
          <option key={opt} value={opt}>
            {opt.replace(/_/g, " ")}
          </option>
        ))}
      </select>
    </label>
  );
}

export default function Home() {
  const [vocab, setVocab] = useState<Vocabulary | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);

  const [growthStage, setGrowthStage] = useState<string>("fruiting");
  const [daysSince, setDaysSince] = useState<string>("");
  const [symptoms, setSymptoms] = useState<Set<string>>(new Set());
  const [conditions, setConditions] = useState<FieldValues>({});
  const [hygiene, setHygiene] = useState<FieldValues>({});
  const [room, setRoom] = useState<FieldValues>({});
  const [mode, setMode] = useState<InferenceMode>("backward");

  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<ConsultationResponse | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);

  useEffect(() => {
    fetchVocabulary()
      .then(setVocab)
      .catch((err) => setLoadError(String(err)));
  }, []);

  const toggleSymptom = (value: string) => {
    setSymptoms((prev) => {
      const next = new Set(prev);
      if (next.has(value)) next.delete(value);
      else next.add(value);
      return next;
    });
  };

  const buildFieldMap = (values: FieldValues, numericKeys: Set<string>) => {
    const out: Record<string, string | number> = {};
    for (const [key, raw] of Object.entries(values)) {
      if (raw === "" || raw === undefined) continue;
      out[key] = numericKeys.has(key) ? Number(raw) : raw;
    }
    return out;
  };

  const numericConditionKeys = useMemo(
    () => new Set((vocab?.conditions ?? []).filter((c) => c.type === "number").map((c) => c.key)),
    [vocab]
  );

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setSubmitError(null);
    setResult(null);
    try {
      const response = await runConsultation({
        growth_stage: growthStage ? (growthStage as any) : undefined,
        days_since_spawning: daysSince === "" ? undefined : Number(daysSince),
        symptoms: Array.from(symptoms),
        conditions: buildFieldMap(conditions, numericConditionKeys),
        hygiene: buildFieldMap(hygiene, new Set()) as Record<string, string>,
        room: buildFieldMap(room, new Set()) as Record<string, string>,
        mode,
      });
      setResult(response);
    } catch (err) {
      setSubmitError(String(err instanceof Error ? err.message : err));
    } finally {
      setSubmitting(false);
    }
  };

  if (loadError) {
    return (
      <main className="mx-auto flex min-h-screen max-w-2xl items-center p-8">
        <p className="rounded-xl border border-danger/30 bg-danger/10 p-4 text-sm text-danger">
          Could not reach the backend API at{" "}
          <code className="rounded bg-background/40 px-1 py-0.5">
            {process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8000"}
          </code>
          : {loadError}
        </p>
      </main>
    );
  }

  if (!vocab) {
    return (
      <main className="mx-auto flex min-h-screen max-w-2xl items-center p-8">
        <p className="flex items-center gap-2 text-muted">
          <span className="h-2 w-2 animate-pulse rounded-full bg-accent" />
          Loading form&hellip;
        </p>
      </main>
    );
  }

  return (
    <main className="mx-auto max-w-3xl px-4 py-10 sm:px-6 sm:py-14">
      <header className="relative mb-10 overflow-hidden rounded-3xl border border-border bg-surface px-6 py-10 sm:px-10 sm:py-14">
        <MushroomScene />
        <div className="relative flex items-start gap-4">
          <span className="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-accent-soft text-3xl">
            🍄
          </span>
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-accent">
              Expert System
            </p>
            <h1 className="mt-2 text-3xl font-extrabold leading-tight text-foreground sm:text-4xl">
              Oyster Mushroom
              <br />
              Cultivation Diagnosis
            </h1>
            <p className="mt-3 max-w-xl text-sm text-muted sm:text-base">
              A rule-based expert system for diagnosing common <em>Pleurotus</em> spp.
              cultivation problems. Fill in what you can observe or measure &mdash; every
              field is optional.
            </p>
          </div>
        </div>
      </header>

      <form onSubmit={handleSubmit} className="flex flex-col gap-6">
        <section className="rounded-2xl border border-border bg-surface p-5 sm:p-6">
          <SectionHeader index="01" title="Growth details" />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <label className="flex flex-col gap-1.5 text-sm">
              <span className="font-medium text-muted">Growth stage</span>
              <select
                value={growthStage}
                onChange={(e) => setGrowthStage(e.target.value)}
                className={fieldClasses}
              >
                <option value="">-- not specified --</option>
                {vocab.growth_stages.map((g) => (
                  <option key={g.value} value={g.value}>
                    {g.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="flex flex-col gap-1.5 text-sm">
              <span className="font-medium text-muted">{vocab.days_since_spawning.label}</span>
              <input
                type="number"
                value={daysSince}
                onChange={(e) => setDaysSince(e.target.value)}
                className={fieldClasses}
                placeholder="e.g. 16"
              />
            </label>
          </div>
        </section>

        <section className="rounded-2xl border border-border bg-surface p-5 sm:p-6">
          <SectionHeader index="02" title="Observed symptoms" subtitle="Tap all that apply" />
          <div className="flex flex-wrap gap-2">
            {vocab.symptoms.map((s) => {
              const active = symptoms.has(s.value);
              return (
                <button
                  key={s.value}
                  type="button"
                  onClick={() => toggleSymptom(s.value)}
                  aria-pressed={active}
                  className={
                    active
                      ? "rounded-full border border-accent bg-accent px-3.5 py-1.5 text-sm font-semibold text-background transition"
                      : "rounded-full border border-border bg-background px-3.5 py-1.5 text-sm font-medium text-muted transition hover:border-accent/50 hover:text-foreground"
                  }
                >
                  {s.label}
                </button>
              );
            })}
          </div>
        </section>

        <section className="rounded-2xl border border-border bg-surface p-5 sm:p-6">
          <SectionHeader index="03" title="Growing conditions" />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {vocab.conditions.map((spec) => (
              <ConditionField
                key={spec.key}
                spec={spec}
                value={conditions[spec.key] ?? ""}
                onChange={(key, value) => setConditions((prev) => ({ ...prev, [key]: value }))}
              />
            ))}
          </div>
        </section>

        <section className="rounded-2xl border border-border bg-surface p-5 sm:p-6">
          <SectionHeader index="04" title="Hygiene &amp; room conditions" />
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2">
            <div>
              <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted">
                Hygiene
              </h3>
              <div className="flex flex-col gap-3">
                {vocab.hygiene.map((spec) => (
                  <ConditionField
                    key={spec.key}
                    spec={spec}
                    value={hygiene[spec.key] ?? ""}
                    onChange={(key, value) => setHygiene((prev) => ({ ...prev, [key]: value }))}
                  />
                ))}
              </div>
            </div>
            <div>
              <h3 className="mb-2 text-xs font-semibold uppercase tracking-wide text-muted">
                Room conditions
              </h3>
              <div className="flex flex-col gap-3">
                {vocab.room.map((spec) => (
                  <ConditionField
                    key={spec.key}
                    spec={spec}
                    value={room[spec.key] ?? ""}
                    onChange={(key, value) => setRoom((prev) => ({ ...prev, [key]: value }))}
                  />
                ))}
              </div>
            </div>
          </div>
        </section>

        <section className="flex flex-col items-stretch gap-4 rounded-2xl border border-border bg-surface p-5 sm:flex-row sm:items-center sm:justify-between sm:p-6">
          <label className="flex items-center gap-2 text-sm text-muted">
            <span>Inference mode:</span>
            <select
              value={mode}
              onChange={(e) => setMode(e.target.value as InferenceMode)}
              className={`${fieldClasses} py-1.5`}
            >
              <option value="backward">Backward chaining</option>
              <option value="forward">Forward chaining</option>
            </select>
          </label>
          <button
            type="submit"
            disabled={submitting}
            className="rounded-full bg-accent px-6 py-2.5 text-sm font-bold text-background transition hover:bg-accent-strong disabled:opacity-50"
          >
            {submitting ? "Diagnosing…" : "Run diagnosis"}
          </button>
        </section>
      </form>

      {submitError && (
        <p className="mt-6 rounded-xl border border-danger/30 bg-danger/10 p-4 text-sm text-danger">
          {submitError}
        </p>
      )}

      {result && (
        <section className="mt-10 flex flex-col gap-4">
          <SectionHeader
            index="✓"
            title="Results"
            subtitle={`${result.mode} chaining`}
          />
          {result.diagnoses.length === 0 ? (
            <p className="rounded-xl border border-border bg-surface p-4 text-sm text-muted">
              No matching problems were found for the information provided. This may mean
              conditions are within normal range, or that more symptoms/conditions need to
              be reported for a diagnosis.
            </p>
          ) : (
            result.diagnoses.map((d) => <DiagnosisCard key={d.problem} diagnosis={d} />)
          )}
        </section>
      )}
    </main>
  );
}
