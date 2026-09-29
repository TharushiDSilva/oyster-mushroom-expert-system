"""
FastAPI application for the Oyster Mushroom Cultivation Problem
Diagnosis Expert System.

This layer does no diagnostic reasoning itself: it validates the
grower's input, translates it into the JSON shape the Prolog engine
expects, calls SWI-Prolog as a subprocess (see prolog_bridge.py), and
returns its diagnosis report to the Next.js frontend. All intelligence
lives in prolog/{facts,rules,engine}.pl.
"""

from __future__ import annotations

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from models import ConsultationRequest, ConsultationResponse
from prolog_bridge import PrologError, run_consultation
from vocabulary import VOCABULARY

app = FastAPI(
    title="Oyster Mushroom Cultivation Expert System API",
    description=(
        "Diagnoses common oyster mushroom (Pleurotus spp.) cultivation "
        "problems from growing conditions and symptoms, using a "
        "SWI-Prolog rule-based expert system."
    ),
    version="1.0.0",
)

# Permissive CORS for local development against the Next.js dev server.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict:
    """Liveness check that also confirms the Prolog engine is reachable."""
    try:
        run_consultation({"symptoms": [], "conditions": {}, "mode": "backward"})
    except PrologError as exc:
        raise HTTPException(status_code=503, detail=f"Prolog engine unavailable: {exc}") from exc
    return {"status": "ok"}


@app.get("/vocabulary")
def vocabulary() -> dict:
    """The symptom/condition/hygiene/room vocabulary the rule base understands."""
    return VOCABULARY


@app.post("/consult", response_model=ConsultationResponse)
def consult(request: ConsultationRequest) -> ConsultationResponse:
    """
    Runs one consultation against the expert system.

    Returns, per matched problem: the possible cultivation problem, the
    supporting reasoning (evidence), the rule(s) applied, and a
    management recommendation.
    """
    try:
        result = run_consultation(request.to_prolog_dict())
    except PrologError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    return ConsultationResponse(**result)
