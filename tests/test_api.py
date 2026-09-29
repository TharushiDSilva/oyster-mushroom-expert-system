"""
Integration tests for the FastAPI layer (backend/main.py).

These tests exercise the real subprocess bridge to SWI-Prolog (no
mocking) so they double as an end-to-end check of the whole
Next.js-facing contract: request validation, translation into Prolog
case facts, and the shape of the JSON response.

Run from the project root with:
    PYTHONPATH=backend pytest tests/test_api.py -v
(the backend/ directory must be on PYTHONPATH so `import main` finds
prolog_bridge.py, models.py and vocabulary.py next to it.)
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

BACKEND_DIR = Path(__file__).resolve().parent.parent / "backend"
sys.path.insert(0, str(BACKEND_DIR))

from main import app  # noqa: E402

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_vocabulary_endpoint_shape():
    response = client.get("/vocabulary")
    assert response.status_code == 200
    body = response.json()
    for key in ("growth_stages", "symptoms", "conditions", "hygiene", "room"):
        assert key in body
    assert len(body["symptoms"]) >= 15


def test_vocabulary_matches_rules():
    """
    Guards against the vocabulary (backend/vocabulary.py) drifting away
    from the symptom/condition keys the Prolog rule base actually
    understands (prolog/rules.pl).
    """
    rules_pl = (BACKEND_DIR.parent / "prolog" / "rules.pl").read_text()
    response = client.get("/vocabulary")
    body = response.json()
    for symptom in body["symptoms"]:
        assert f"observed_symptom({symptom['value']})" in rules_pl, (
            f"vocabulary symptom {symptom['value']!r} is not referenced by any rule"
        )


def test_consult_high_co2_stress():
    payload = {
        "growth_stage": "fruiting",
        "days_since_spawning": 16,
        "symptoms": ["long_stem", "small_cap"],
        "conditions": {"co2_level": "high"},
    }
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    body = response.json()
    problems = {d["problem"] for d in body["diagnoses"]}
    assert "high_co2_stress" in problems
    assert "no_pinning" in problems  # 16 days, no pins, high CO2 -> R7 also fires

    co2_diag = next(d for d in body["diagnoses"] if d["problem"] == "high_co2_stress")
    assert co2_diag["rules_applied"] == ["R1"]
    assert "long_stem was observed" in co2_diag["evidence"]
    assert "fresh-air exchange" in co2_diag["recommendation"].lower()


def test_consult_numeric_co2_ppm_uses_r2():
    payload = {"growth_stage": "fruiting", "conditions": {"co2_ppm": 1500}}
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert len(body["diagnoses"]) == 1
    assert body["diagnoses"][0]["problem"] == "high_co2_stress"
    assert body["diagnoses"][0]["rules_applied"] == ["R2"]


def test_consult_green_mold_contamination():
    payload = {"days_since_spawning": 12, "symptoms": ["green_patches_on_substrate"]}
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["diagnoses"][0]["problem"] == "green_mold_contamination"
    assert body["diagnoses"][0]["rules_applied"] == ["R14"]


def test_consult_r24_viral_infection_ruled_in_by_elimination():
    payload = {"symptoms": ["thin_stipe", "delayed_fruiting", "abnormal_shape"]}
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["diagnoses"][0]["problem"] == "possible_viral_infection"


def test_consult_r24_suppressed_when_high_co2_stress_present():
    """R24 should NOT fire once a more common cause (high CO2) explains the case."""
    payload = {
        "symptoms": [
            "thin_stipe", "delayed_fruiting", "abnormal_shape",
            "long_stem", "small_cap",
        ],
        "conditions": {"co2_level": "high"},
    }
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    problems = {d["problem"] for d in response.json()["diagnoses"]}
    assert "possible_viral_infection" not in problems
    assert "high_co2_stress" in problems


def test_consult_empty_request_returns_no_diagnoses():
    response = client.post("/consult", json={})
    assert response.status_code == 200
    assert response.json() == {"mode": "backward", "diagnoses": []}


def test_consult_forward_mode_matches_backward_for_same_case():
    payload = {
        "growth_stage": "fruiting",
        "days_since_spawning": 16,
        "symptoms": ["long_stem", "small_cap"],
        "conditions": {"co2_level": "high"},
        "mode": "forward",
    }
    response = client.post("/consult", json=payload)
    assert response.status_code == 200
    body = response.json()
    assert body["mode"] == "forward"
    problems = {d["problem"] for d in body["diagnoses"]}
    assert problems == {"high_co2_stress", "no_pinning"}


def test_consult_rejects_invalid_growth_stage():
    response = client.post("/consult", json={"growth_stage": "not_a_real_stage"})
    assert response.status_code == 422


def test_consult_rejects_negative_days_since_spawning():
    response = client.post("/consult", json={"days_since_spawning": -5})
    assert response.status_code == 422


def test_consultations_do_not_leak_case_facts_between_requests():
    """
    Each /consult call must run in isolation: symptoms from one request
    must never influence the diagnosis of the next.
    """
    first = client.post(
        "/consult",
        json={"symptoms": ["long_stem", "small_cap"], "conditions": {"co2_level": "high"}},
    )
    assert first.json()["diagnoses"] != []

    second = client.post("/consult", json={})
    assert second.json()["diagnoses"] == []


@pytest.mark.parametrize(
    "condition_value",
    [70, 70.5, "high"],
)
def test_consult_accepts_both_numeric_and_category_condition_values(condition_value):
    key = "humidity_percent" if isinstance(condition_value, (int, float)) else "co2_level"
    response = client.post("/consult", json={"conditions": {key: condition_value}})
    assert response.status_code == 200
