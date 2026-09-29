% =====================================================================
%  test_rules.pl
%  PlUnit test suite for the Prolog knowledge base (facts.pl, rules.pl,
%  engine.pl). Exercises every rule R1-R24 individually (does it fire
%  when its conditions are met, does it stay silent otherwise), plus
%  the forward-chaining fixpoint and the JSON request/response layer.
%
%  Run with:
%      swipl -q -g run_tests -t halt tests/test_rules.pl
%  (run from the project root, or adjust the path below.)
% =====================================================================

:- use_module(library(plunit)).
:- ensure_loaded('../prolog/engine').

:- begin_tests(rules, [setup(user:reset_case), cleanup(user:reset_case)]).

% --- R1 / R2: high_co2_stress -----------------------------------------

test(r1_fires_on_leggy_symptoms_and_high_co2) :-
    user:reset_case,
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(small_cap)),
    assertz(user:current_condition(co2_level, high)),
    once(user:diagnose(high_co2_stress)).

test(r1_does_not_fire_without_high_co2, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(small_cap)),
    once(user:diagnose(high_co2_stress)).

test(r2_fires_on_ppm_above_threshold) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(co2_ppm, 1500)),
    once(user:diagnose(high_co2_stress)).

test(r2_does_not_fire_below_threshold, [fail]) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(co2_ppm, 800)),
    once(user:diagnose(high_co2_stress)).

% --- R3 / R4: insufficient_light ---------------------------------------

test(r3_fires_on_long_pale_low_light) :-
    user:reset_case,
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(pale_cap)),
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(light_hours, 4)),
    once(user:diagnose(insufficient_light)).

test(r3_does_not_fire_with_enough_light, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(pale_cap)),
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(light_hours, 14)),
    once(user:diagnose(insufficient_light)).

test(r4_fires_on_brittle_cap_minimal_light) :-
    user:reset_case,
    assertz(user:observed_symptom(brittle_cap)),
    assertz(user:current_condition(light_hours, 2)),
    once(user:diagnose(insufficient_light)).

% --- R5 / R6: low_humidity_stress --------------------------------------

test(r5_fires_on_dry_cracked_cap_below_optimal_humidity) :-
    user:reset_case,
    assertz(user:observed_symptom(dry_cracked_cap)),
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(humidity_percent, 60)),
    once(user:diagnose(low_humidity_stress)).

test(r6_fires_on_pins_drying_low_humidity) :-
    user:reset_case,
    assertz(user:observed_symptom(pins_drying)),
    assertz(user:current_condition(humidity_percent, 55)),
    once(user:diagnose(low_humidity_stress)).

test(r6_does_not_fire_with_adequate_humidity, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(pins_drying)),
    assertz(user:current_condition(humidity_percent, 85)),
    once(user:diagnose(low_humidity_stress)).

% --- R7 / R8: no_pinning ------------------------------------------------

test(r7_fires_no_pins_14_days_high_co2) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:days_since(spawning, 16)),
    assertz(user:current_condition(co2_level, high)),
    once(user:diagnose(no_pinning)).

test(r7_does_not_fire_before_day_14, [fail]) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:days_since(spawning, 10)),
    assertz(user:current_condition(co2_level, high)),
    once(user:diagnose(no_pinning)).

test(r8_fires_no_pins_incomplete_colonisation) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:days_since(spawning, 15)),
    assertz(user:current_condition(colonisation, incomplete)),
    once(user:diagnose(no_pinning)).

% --- R9: delayed_pinning -------------------------------------------------

test(r9_fires_without_temperature_drop) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(temperature_drop, none)),
    once(user:diagnose(delayed_pinning)).

test(r9_does_not_fire_with_temperature_drop, [fail]) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(temperature_drop, present)),
    once(user:diagnose(delayed_pinning)).

% --- R10 / R11: pin_abortion ---------------------------------------------

test(r10_fires_on_fluctuating_co2) :-
    user:reset_case,
    assertz(user:observed_symptom(aborted_pins)),
    assertz(user:current_condition(co2_level, fluctuating)),
    once(user:diagnose(pin_abortion)).

test(r11_fires_on_low_humidity) :-
    user:reset_case,
    assertz(user:observed_symptom(aborted_pins)),
    assertz(user:current_condition(humidity_percent, 65)),
    once(user:diagnose(pin_abortion)).

% --- R12: airflow_without_humidity ---------------------------------------

test(r12_fires_good_airflow_low_humidity) :-
    user:reset_case,
    assertz(user:observed_symptom(long_thin_stem)),
    assertz(user:observed_symptom(no_cap)),
    assertz(user:current_condition(fresh_air_exchange, good)),
    assertz(user:current_condition(humidity_percent, 55)),
    once(user:diagnose(airflow_without_humidity)).

% --- R13: overcrowding ----------------------------------------------------

test(r13_fires_on_crowded_bags_poor_circulation) :-
    user:reset_case,
    assertz(user:room_condition(bag_spacing, crowded)),
    assertz(user:observed_symptom(poor_air_circulation)),
    once(user:diagnose(overcrowding)).

% --- R14 / R15: green_mold_contamination -----------------------------------

test(r14_fires_within_onset_window) :-
    user:reset_case,
    assertz(user:observed_symptom(green_patches_on_substrate)),
    assertz(user:days_since(spawning, 12)),
    once(user:diagnose(green_mold_contamination)).

test(r14_does_not_fire_outside_onset_window, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(green_patches_on_substrate)),
    assertz(user:days_since(spawning, 25)),
    once(user:diagnose(green_mold_contamination)).

test(r15_fires_on_green_sporulation) :-
    user:reset_case,
    assertz(user:observed_symptom(green_sporulation)),
    once(user:diagnose(green_mold_contamination)).

% --- R16 / R17: bacterial_brown_blotch -------------------------------------

test(r16_fires_on_brown_spots_high_humidity) :-
    user:reset_case,
    assertz(user:observed_symptom(brown_spots_on_cap)),
    assertz(user:current_condition(humidity_percent, 95)),
    once(user:diagnose(bacterial_brown_blotch)).

test(r17_fires_on_brown_spots_free_water) :-
    user:reset_case,
    assertz(user:observed_symptom(brown_spots_on_cap)),
    assertz(user:current_condition(free_water_on_caps, present)),
    once(user:diagnose(bacterial_brown_blotch)).

% --- R18/R19/R20: general_contamination -------------------------------------

test(r18_fires_on_poor_substrate_sterilisation) :-
    user:reset_case,
    assertz(user:hygiene_practice(substrate_sterilization, poor)),
    once(user:diagnose(general_contamination)).

test(r19_fires_on_poor_equipment_sterilisation) :-
    user:reset_case,
    assertz(user:hygiene_practice(equipment_sterilization, poor)),
    once(user:diagnose(general_contamination)).

test(r20_fires_on_spent_substrate_near_room) :-
    user:reset_case,
    assertz(user:room_condition(spent_substrate_disposal, near_growing_room)),
    once(user:diagnose(general_contamination)).

% --- R21: pest_infestation ---------------------------------------------------

test(r21_fires_on_insects_and_no_screens) :-
    user:reset_case,
    assertz(user:observed_symptom(insects_present)),
    assertz(user:room_condition(window_screens, absent)),
    once(user:diagnose(pest_infestation)).

test(r21_does_not_fire_with_screens_present, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(insects_present)),
    assertz(user:room_condition(window_screens, present)),
    once(user:diagnose(pest_infestation)).

% --- R22/R23: poor_spawn_quality ----------------------------------------------

test(r22_fires_on_no_growth_old_spawn) :-
    user:reset_case,
    assertz(user:observed_symptom(no_mycelium_growth)),
    assertz(user:current_condition(spawn_age, old)),
    once(user:diagnose(poor_spawn_quality)).

test(r23_fires_on_patchy_colonisation_unverified_source) :-
    user:reset_case,
    assertz(user:observed_symptom(patchy_colonisation)),
    assertz(user:current_condition(spawn_source, unverified)),
    once(user:diagnose(poor_spawn_quality)).

% --- R24: possible_viral_infection (negation as failure) ----------------------

test(r24_fires_when_other_causes_ruled_out) :-
    user:reset_case,
    assertz(user:observed_symptom(thin_stipe)),
    assertz(user:observed_symptom(delayed_fruiting)),
    assertz(user:observed_symptom(abnormal_shape)),
    once(user:diagnose(possible_viral_infection)).

test(r24_does_not_fire_when_high_co2_stress_present, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(thin_stipe)),
    assertz(user:observed_symptom(delayed_fruiting)),
    assertz(user:observed_symptom(abnormal_shape)),
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(small_cap)),
    assertz(user:current_condition(co2_level, high)),
    once(user:diagnose(possible_viral_infection)).

test(r24_does_not_fire_when_insufficient_light_present, [fail]) :-
    user:reset_case,
    assertz(user:observed_symptom(thin_stipe)),
    assertz(user:observed_symptom(delayed_fruiting)),
    assertz(user:observed_symptom(abnormal_shape)),
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(pale_cap)),
    assertz(user:growth_stage(fruiting)),
    assertz(user:current_condition(light_hours, 2)),
    once(user:diagnose(possible_viral_infection)).

% --- No false positives on an empty / healthy case ----------------------------

test(no_diagnosis_for_healthy_crop) :-
    user:reset_case,
    findall(P, user:diagnose(P), Ps),
    Ps == [].

% --- Forward chaining reaches the same conclusions as backward chaining -------

test(forward_chaining_matches_backward_for_co2_scenario) :-
    user:reset_case,
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(small_cap)),
    assertz(user:current_condition(co2_level, high)),
    user:forward_chain,
    user:diagnosed(high_co2_stress),
    user:rule_fired(high_co2_stress, r1).

% --- Multiple independent rules can fire together on richer input -------------

test(multiple_diagnoses_on_combined_symptoms) :-
    user:reset_case,
    assertz(user:growth_stage(fruiting)),
    assertz(user:days_since(spawning, 16)),
    assertz(user:observed_symptom(long_stem)),
    assertz(user:observed_symptom(small_cap)),
    assertz(user:current_condition(co2_level, high)),
    findall(P, user:diagnose(P), Ps0),
    sort(Ps0, Ps),
    Ps == [high_co2_stress, no_pinning].

% --- JSON request/response layer (consult_json/2) ------------------------------

test(consult_json_backward_mode_returns_diagnoses) :-
    Request = _{growth_stage: "fruiting", days_since_spawning: 16,
                symptoms: ["long_stem", "small_cap"],
                conditions: _{co2_level: "high"}},
    user:consult_json(Request, Response),
    get_dict(diagnoses, Response, Diagnoses),
    length(Diagnoses, N),
    N >= 1.

test(consult_json_numeric_condition) :-
    Request = _{growth_stage: "fruiting", conditions: _{co2_ppm: 1600}},
    user:consult_json(Request, Response),
    get_dict(diagnoses, Response, [First|_]),
    get_dict(problem, First, high_co2_stress).

test(consult_json_empty_request_returns_no_diagnoses) :-
    Request = _{},
    user:consult_json(Request, Response),
    get_dict(diagnoses, Response, []).

:- end_tests(rules).
