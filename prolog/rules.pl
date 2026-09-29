% =====================================================================
%  rules.pl
%  Diagnostic rule base for the Oyster Mushroom Cultivation
%  Problem Diagnosis Expert System.
%
%  Every rule is represented ONCE, as a rule/3 fact:
%
%      rule(RuleId, ConditionList, Conclusion).
%
%  ConditionList is a list of ordinary Prolog goals. engine.pl's
%  solve/1 calls them left-to-right (so a later goal can use a
%  variable bound by an earlier one), which is exactly what backward
%  chaining (diagnose/1) and forward chaining (forward_chain/0) both
%  build on -- this file is the single source of truth for both
%  inference strategies described in the design document.
%
%  Rules are grouped exactly as in the design doc:
%    A. Environmental / airflow / light / pinning problems (R1-R13)
%    B. Contamination, disease and pest problems (R14-R24)
% =====================================================================

% No module wrapper: facts.pl, rules.pl and engine.pl are consulted
% together into one namespace (see engine.pl's :- initialization
% directive), because rules.pl's R24 calls diagnose/1 (defined in
% engine.pl) and engine.pl's solve/1 calls rule/3 (defined here) --
% a genuine mutual dependency that plain consultation handles cleanly
% without a circular use_module.

% ---------------------------------------------------------------------
% A. Environmental / airflow / light / pinning problems
% ---------------------------------------------------------------------

% R1 - classic "leggy" signature: long stem + small cap + high CO2 (KA09)
rule(r1,
     [observed_symptom(long_stem),
      observed_symptom(small_cap),
      current_condition(co2_level, high)],
     high_co2_stress).

% R2 - numeric-threshold alternative when a PPM reading is available (KA08)
rule(r2,
     [growth_stage(Stage),
      current_condition(co2_ppm, PPM),
      co2_threshold(Stage, Max),
      PPM > Max],
     high_co2_stress).

% R3 - light deficiency distinguished from CO2 stress via pale colour (KA10, KA11)
rule(r3,
     [observed_symptom(long_stem),
      observed_symptom(pale_cap),
      current_condition(light_hours, Hours),
      growth_stage(fruiting),
      photoperiod(fruiting, Min, _),
      Hours < Min],
     insufficient_light).

% R4 - brittle caps from too little light (KA11)
rule(r4,
     [observed_symptom(brittle_cap),
      current_condition(light_hours, Hours),
      Hours =< 4],
     insufficient_light).

% R5 - dry, cracked caps below the optimal fruiting humidity band (KA07, KA15)
rule(r5,
     [observed_symptom(dry_cracked_cap),
      growth_stage(fruiting),
      current_condition(humidity_percent, H),
      optimal_condition(fruiting, humidity, Min, _, percent),
      H < Min],
     low_humidity_stress).

% R6 - pins drying out under very low humidity (KA15)
rule(r6,
     [observed_symptom(pins_drying),
      current_condition(humidity_percent, H),
      H < 70],
     low_humidity_stress).

% R7 - no pins after 14+ days with CO2 still high (KA12)
rule(r7,
     [growth_stage(fruiting),
      days_since(spawning, D),
      D >= 14,
      current_condition(co2_level, high)],
     no_pinning).

% R8 - no pins after 14+ days because colonisation never completed (KA12)
rule(r8,
     [growth_stage(fruiting),
      days_since(spawning, D),
      D >= 14,
      current_condition(colonisation, incomplete)],
     no_pinning).

% R9 - no temperature drop offered to trigger pinning (KA06)
rule(r9,
     [growth_stage(fruiting),
      current_condition(temperature_drop, none)],
     delayed_pinning).

% R10 - pins aborting under fluctuating CO2 (KA14)
rule(r10,
     [observed_symptom(aborted_pins),
      current_condition(co2_level, fluctuating)],
     pin_abortion).

% R11 - pins aborting under low humidity (KA14)
rule(r11,
     [observed_symptom(aborted_pins),
      current_condition(humidity_percent, H),
      H < 75],
     pin_abortion).

% R12 - good airflow but insufficient humidity: long thin stems, no cap (KA13)
rule(r12,
     [observed_symptom(long_thin_stem),
      observed_symptom(no_cap),
      current_condition(fresh_air_exchange, good),
      current_condition(humidity_percent, H),
      H < 70],
     airflow_without_humidity).

% R13 - overcrowded bags reducing circulation (KA21)
rule(r13,
     [room_condition(bag_spacing, crowded),
      observed_symptom(poor_air_circulation)],
     overcrowding).

% ---------------------------------------------------------------------
% B. Contamination, disease and pest problems
% ---------------------------------------------------------------------

% R14 - green mold onset window 10-15 days after spawning (KA16)
rule(r14,
     [observed_symptom(green_patches_on_substrate),
      days_since(spawning, D),
      D >= 10,
      D =< 15],
     green_mold_contamination).

% R15 - green mold confirmed via its causal agent (KA16)
rule(r15,
     [observed_symptom(green_sporulation),
      disease_cause(green_mold_contamination, trichoderma_spp)],
     green_mold_contamination).

% R16 - bacterial brown blotch favoured by very high humidity (KA18)
rule(r16,
     [observed_symptom(brown_spots_on_cap),
      current_condition(humidity_percent, H),
      H > 90],
     bacterial_brown_blotch).

% R17 - bacterial brown blotch from free water sitting on caps (KA18)
rule(r17,
     [observed_symptom(brown_spots_on_cap),
      current_condition(free_water_on_caps, present)],
     bacterial_brown_blotch).

% R18/R19/R20 - general contamination from poor hygiene practices (KA17)
rule(r18,
     [hygiene_practice(substrate_sterilization, poor)],
     general_contamination).

rule(r19,
     [hygiene_practice(equipment_sterilization, poor)],
     general_contamination).

rule(r20,
     [room_condition(spent_substrate_disposal, near_growing_room)],
     general_contamination).

% R21 - pests entering through unscreened openings (KA19)
rule(r21,
     [observed_symptom(insects_present),
      room_condition(window_screens, absent)],
     pest_infestation).

% R22/R23 - poor spawn quality (KA20)
rule(r22,
     [observed_symptom(no_mycelium_growth),
      current_condition(spawn_age, old)],
     poor_spawn_quality).

rule(r23,
     [observed_symptom(patchy_colonisation),
      current_condition(spawn_source, unverified)],
     poor_spawn_quality).

% R24 - low-confidence, last-resort rule: only fires once the two most
% common environmental causes have been ruled out by negation as
% failure over the backward-chaining predicate diagnose/1 (KA22).
rule(r24,
     [observed_symptom(thin_stipe),
      observed_symptom(delayed_fruiting),
      observed_symptom(abnormal_shape),
      \+ diagnose(high_co2_stress),
      \+ diagnose(insufficient_light)],
     possible_viral_infection).
