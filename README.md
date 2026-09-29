# Oyster Mushroom Cultivation Expert System

A rule-based expert system for diagnosing common cultivation problems in oyster mushroom (*Pleurotus* spp.) farming. Built with **SWI-Prolog** for the knowledge base and inference engine, **FastAPI** as the backend bridge, and **Next.js/React** for the consultation interface.

Built as the practical assignment for the *Logic Programming and Artificial Cognitive Systems* (LPACS) module, University of Moratuwa.

## Features

- 32 domain facts and 24 diagnostic rules encoding cultivation thresholds, disease causes/symptoms, and corrective recommendations
- Two independent inference strategies over the same rule base:
  - **Backward chaining** — SLD resolution via `diagnose/1`
  - **Forward chaining** — fixpoint rule-firing via `forward_chain/0`
- A full explanation facility — every diagnosis reports the supporting evidence and the rule(s) that fired, not just the conclusion
- 40 SWI-Prolog PlUnit tests + 16 pytest API tests, all passing
- Every rule traceable to a documented source (HORDI / Dept. of Agriculture Sri Lanka, University of Florida IFAS Extension, peer-reviewed *Pleurotus* research, and practical cultivation guides)

## Architecture

```
User -> Next.js/React UI -> FastAPI backend -> SWI-Prolog inference engine
                                                (facts.pl + rules.pl + engine.pl)
```

FastAPI translates the submitted form into Prolog case facts and invokes SWI-Prolog as a short-lived subprocess per request — no long-running Prolog server or Python-Prolog binding is needed.

## Project layout

```
oyster-mushroom-expert-system/
├── prolog/      facts.pl, rules.pl, engine.pl, run_consultation.pl
├── backend/     FastAPI app (main.py, models.py, prolog_bridge.py, vocabulary.py)
├── frontend/    Next.js + React + Tailwind UI
└── tests/       test_rules.pl (PlUnit), test_api.py (pytest)
```

## Requirements

- SWI-Prolog 9.x (`swipl` on PATH)
- Python 3.10+ with pip
- Node.js 20.9+ with npm

## Setup

```powershell
# 1. Install SWI-Prolog: https://www.swi-prolog.org/Download.html
swipl --version

# 2. Backend dependencies
cd backend
pip install -r requirements.txt

# 3. Frontend dependencies
cd ../frontend
npm install
copy .env.local.example .env.local
```

## Running

```powershell
# Terminal 1 - backend
cd backend
python -m uvicorn main:app --reload --port 8000

# Terminal 2 - frontend
cd frontend
npm run dev
```

Then open http://localhost:3000. No separate step is needed to "start" Prolog — FastAPI invokes `swipl` as a subprocess for every consultation.

## Running the test suites

```powershell
swipl -q -g run_tests -t halt tests/test_rules.pl
cd backend
pytest ../tests/test_api.py
```

## Example API request

```
POST http://localhost:8000/consult
Content-Type: application/json

{
  "growth_stage": "fruiting",
  "days_since_spawning": 16,
  "symptoms": ["long_stem", "small_cap"],
  "conditions": { "co2_level": "high" }
}
```

## Knowledge base

- **Facts** (`prolog/facts.pl`) — 32 static facts: environmental thresholds, substrate materials, varieties, disease causes/symptoms, and 14 corrective recommendations.
- **Rules** (`prolog/rules.pl`) — 24 diagnostic rules (`rule(RuleId, Conditions, Conclusion)`), each cited to a Knowledge Acquisition id and a source document — see the project report for the full Rule Source Table and reference list.
- **Inference** (`prolog/engine.pl`) — implements both backward chaining (`diagnose/1`) and forward chaining (`forward_chain/0`) over the same rule base, plus the explanation facility (`evidence_for/2`, `rule_fired/2`).

## Author

**Tharushi De Silva** (De Silva W.T.W.), 224035N — University of Moratuwa
Logic Programming and Artificial Cognitive Systems (LPACS)

## License

Academic coursework project — for evaluation purposes.
