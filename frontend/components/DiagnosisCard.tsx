import type { Diagnosis } from "@/lib/types";

export default function DiagnosisCard({ diagnosis }: { diagnosis: Diagnosis }) {
  return (
    <div className="rounded-2xl border border-border bg-surface p-5 shadow-lg shadow-black/20 sm:p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h3 className="text-lg font-bold text-foreground">{diagnosis.label}</h3>
        <div className="flex flex-wrap gap-1.5">
          {diagnosis.rules_applied.map((rule) => (
            <span
              key={rule}
              className="rounded-full bg-accent-soft px-2.5 py-1 text-xs font-semibold text-accent"
            >
              {rule}
            </span>
          ))}
        </div>
      </div>

      <div className="mt-4">
        <h4 className="text-xs font-semibold uppercase tracking-wide text-muted">
          Supporting reasoning
        </h4>
        <ul className="mt-1.5 list-inside list-disc space-y-0.5 text-sm text-foreground/85">
          {diagnosis.evidence.map((fact, i) => (
            <li key={i}>{fact}</li>
          ))}
        </ul>
      </div>

      <div className="mt-4">
        <h4 className="text-xs font-semibold uppercase tracking-wide text-muted">
          Explanation
        </h4>
        <p className="mt-1.5 text-sm text-foreground/85">{diagnosis.explanation}</p>
      </div>

      <div className="mt-4 rounded-xl border border-amber/30 bg-amber/10 p-4">
        <h4 className="text-xs font-semibold uppercase tracking-wide text-amber">
          Management recommendation
        </h4>
        <p className="mt-1.5 text-sm text-foreground">{diagnosis.recommendation}</p>
      </div>
    </div>
  );
}
