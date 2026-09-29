"""
Static vocabulary describing every symptom, condition, hygiene and room
key the rule base (prolog/rules.pl) understands. Served via GET
/vocabulary so the Next.js form can render checkboxes/selects without
hard-coding the list twice, and kept in sync with rules.pl by hand --
see tests/test_api.py::test_vocabulary_matches_rules for a guard that
fails if the two drift apart.
"""

from __future__ import annotations

VOCABULARY = {
    "growth_stages": [
        {"value": "spawn_run", "label": "Spawn run (incubation)"},
        {"value": "pinning", "label": "Pinning"},
        {"value": "fruiting", "label": "Fruiting"},
    ],
    "symptoms": [
        {"value": "long_stem", "label": "Long stem"},
        {"value": "small_cap", "label": "Small / underdeveloped cap"},
        {"value": "pale_cap", "label": "Pale cap colour"},
        {"value": "brittle_cap", "label": "Brittle cap"},
        {"value": "dry_cracked_cap", "label": "Dry, cracked cap"},
        {"value": "pins_drying", "label": "Pins drying out"},
        {"value": "aborted_pins", "label": "Pins aborting before maturity"},
        {"value": "long_thin_stem", "label": "Long, thin stem"},
        {"value": "no_cap", "label": "No cap forming"},
        {"value": "poor_air_circulation", "label": "Poor air circulation"},
        {"value": "green_patches_on_substrate", "label": "Green patches on substrate"},
        {"value": "green_sporulation", "label": "Green sporulation"},
        {"value": "brown_spots_on_cap", "label": "Brown spots on cap"},
        {"value": "insects_present", "label": "Insects present"},
        {"value": "no_mycelium_growth", "label": "No mycelium growth"},
        {"value": "patchy_colonisation", "label": "Patchy colonisation"},
        {"value": "thin_stipe", "label": "Thin stipe"},
        {"value": "delayed_fruiting", "label": "Delayed fruiting-body formation"},
        {"value": "abnormal_shape", "label": "Abnormal fruiting-body shape"},
    ],
    "conditions": [
        {"key": "co2_level", "type": "category", "options": ["high", "fluctuating", "normal"], "label": "CO2 level (category)"},
        {"key": "co2_ppm", "type": "number", "unit": "ppm", "label": "CO2 reading (ppm)"},
        {"key": "light_hours", "type": "number", "unit": "hours/day", "label": "Light hours per day"},
        {"key": "humidity_percent", "type": "number", "unit": "%", "label": "Relative humidity (%)"},
        {"key": "temperature_drop", "type": "category", "options": ["present", "none"], "label": "Temperature drop offered to trigger pinning"},
        {"key": "fresh_air_exchange", "type": "category", "options": ["good", "poor"], "label": "Fresh-air exchange quality"},
        {"key": "colonisation", "type": "category", "options": ["complete", "incomplete"], "label": "Substrate colonisation"},
        {"key": "spawn_age", "type": "category", "options": ["fresh", "old"], "label": "Spawn age"},
        {"key": "spawn_source", "type": "category", "options": ["verified", "unverified"], "label": "Spawn source"},
        {"key": "free_water_on_caps", "type": "category", "options": ["present", "absent"], "label": "Free water sitting on caps"},
    ],
    "hygiene": [
        {"key": "substrate_sterilization", "options": ["good", "poor"], "label": "Substrate sterilisation"},
        {"key": "equipment_sterilization", "options": ["good", "poor"], "label": "Equipment sterilisation"},
    ],
    "room": [
        {"key": "bag_spacing", "options": ["normal", "crowded"], "label": "Bag/block spacing"},
        {"key": "window_screens", "options": ["present", "absent"], "label": "Window/door wire mesh screens"},
        {"key": "spent_substrate_disposal", "options": ["away", "near_growing_room"], "label": "Spent substrate disposal"},
    ],
    "days_since_spawning": {"type": "number", "unit": "days", "label": "Days since spawning"},
}
