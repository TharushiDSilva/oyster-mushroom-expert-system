"""
prolog_bridge.py

Bridges FastAPI to the SWI-Prolog expert system. Each consultation is
run as a short-lived `swipl` subprocess: the request is written to its
stdin as JSON, and the diagnosis report is read back from its stdout
as JSON. This keeps the reasoning entirely inside Prolog (no
reimplementation of the rules in Python) without depending on a
Python<->Prolog binding library such as pyswip, which can be brittle
to install. A fresh process per request also guarantees case facts
from one consultation can never leak into another.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any

PROLOG_DIR = Path(__file__).resolve().parent.parent / "prolog"
RUN_SCRIPT = PROLOG_DIR / "run_consultation.pl"

SWIPL_TIMEOUT_SECONDS = 10


class PrologError(RuntimeError):
    """Raised when the Prolog engine cannot be reached or reports an error."""


def run_consultation(request: dict[str, Any]) -> dict[str, Any]:
    """
    Sends `request` (already shaped like the Prolog engine's expected
    input -- see ConsultationRequest.to_prolog_dict) to run_consultation.pl
    and returns its parsed JSON response.
    """
    if not RUN_SCRIPT.exists():
        raise PrologError(f"Prolog entry point not found at {RUN_SCRIPT}")

    payload = json.dumps(request)

    try:
        completed = subprocess.run(
            ["swipl", "-q", "-f", str(RUN_SCRIPT), "-g", "main", "-t", "halt"],
            input=payload,
            capture_output=True,
            text=True,
            timeout=SWIPL_TIMEOUT_SECONDS,
            cwd=str(PROLOG_DIR),
        )
    except FileNotFoundError as exc:
        raise PrologError(
            "swipl was not found on PATH. Install SWI-Prolog (e.g. "
            "`apt-get install swi-prolog-nox`) and ensure `swipl` is available."
        ) from exc
    except subprocess.TimeoutExpired as exc:
        raise PrologError("The Prolog engine timed out.") from exc

    if completed.returncode != 0:
        raise PrologError(
            f"swipl exited with code {completed.returncode}: {completed.stderr.strip()}"
        )

    stdout = completed.stdout.strip()
    if not stdout:
        raise PrologError(f"swipl produced no output. stderr: {completed.stderr.strip()}")

    try:
        result = json.loads(stdout)
    except json.JSONDecodeError as exc:
        raise PrologError(f"Could not parse Prolog output as JSON: {stdout!r}") from exc

    if isinstance(result, dict) and result.get("error"):
        raise PrologError(result.get("message", "Unknown Prolog error"))

    return result
