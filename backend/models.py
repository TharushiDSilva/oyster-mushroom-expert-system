"""Pydantic request/response models for the Oyster Mushroom Expert System API."""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

Number = int | float
ConditionValue = Number | str


class ConsultationRequest(BaseModel):
    growth_stage: Literal["spawn_run", "pinning", "fruiting"] | None = Field(
        default=None,
        description="The crop's current growth stage.",
    )
    days_since_spawning: int | None = Field(
        default=None, ge=0, description="Days elapsed since the substrate was spawned."
    )
    symptoms: list[str] = Field(
        default_factory=list,
        description="Symptom keys the grower observed (see GET /vocabulary).",
    )
    conditions: dict[str, ConditionValue] = Field(
        default_factory=dict,
        description=(
            "Environmental readings. Each value may be numeric "
            "(e.g. humidity_percent: 70) or a category "
            "(e.g. co2_level: 'high') -- whichever the grower can supply."
        ),
    )
    hygiene: dict[str, str] = Field(
        default_factory=dict, description="Hygiene-practice facts, e.g. {'substrate_sterilization': 'poor'}."
    )
    room: dict[str, str] = Field(
        default_factory=dict, description="Physical room facts, e.g. {'window_screens': 'absent'}."
    )
    mode: Literal["backward", "forward"] = Field(
        default="backward",
        description=(
            "Inference strategy to run: 'backward' (default) answers "
            "'what problems does the evidence prove, and why' via SLD "
            "resolution over diagnose/1. 'forward' starts purely from "
            "the asserted facts and derives everything reachable via "
            "repeated rule/3 passes to a fixpoint, demonstrating "
            "data-driven forward chaining."
        ),
    )

    def to_prolog_dict(self) -> dict:
        payload: dict = {
            "symptoms": self.symptoms,
            "conditions": self.conditions,
            "hygiene": self.hygiene,
            "room": self.room,
            "mode": self.mode,
        }
        if self.growth_stage is not None:
            payload["growth_stage"] = self.growth_stage
        if self.days_since_spawning is not None:
            payload["days_since_spawning"] = self.days_since_spawning
        return payload


class Diagnosis(BaseModel):
    problem: str
    label: str
    evidence: list[str]
    rules_applied: list[str]
    explanation: str
    recommendation: str


class ConsultationResponse(BaseModel):
    mode: Literal["backward", "forward"]
    diagnoses: list[Diagnosis]
