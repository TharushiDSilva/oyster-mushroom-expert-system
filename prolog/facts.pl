% =====================================================================
%  facts.pl
%  Static domain knowledge for the Oyster Mushroom Cultivation
%  Problem Diagnosis Expert System.
%
%  These facts represent the "textbook" knowledge the system was built
%  from (HORDI / Dept. of Agriculture Sri Lanka, University of Florida
%  IFAS, and peer-reviewed Pleurotus research). They never change
%  during a consultation; only case facts (see engine.pl) are
%  asserted/retracted per request.
%
%  See the project's Knowledge Acquisition Table (KA01-KA24) for the
%  provenance of every fact below; the KA id is noted alongside it.
% =====================================================================

% No module wrapper -- consulted into the same namespace as rules.pl
% and engine.pl (see the note at the top of rules.pl).

% ---------------------------------------------------------------------
% optimal_condition(Stage, Parameter, Min, Max, Unit).
% The ideal range of an environmental parameter for a growth stage.
% ---------------------------------------------------------------------
optimal_condition(spawn_run, temperature, 24, 28, celsius).      % KA05
optimal_condition(fruiting,  temperature, 20, 25, celsius).      % KA02
optimal_condition(pinning,   humidity,    85, 95, percent).      % KA07
optimal_condition(fruiting,  humidity,    80, 90, percent).      % KA07

% ---------------------------------------------------------------------
% co2_threshold(Stage, MaxPPM).
% The CO2 ceiling above which a stage is negatively affected.
% ---------------------------------------------------------------------
co2_threshold(fruiting, 1200).                                   % KA08
co2_threshold(pinning,  1000).                                   % KA08

% ---------------------------------------------------------------------
% photoperiod(Stage, MinHours, MaxHours).
% Recommended daily light hours for a stage.
% ---------------------------------------------------------------------
photoperiod(fruiting, 12, 18).                                   % KA11

% ---------------------------------------------------------------------
% substrate_component(Material).
% Accepted lignocellulosic substrate materials.
% ---------------------------------------------------------------------
substrate_component(sawdust).                                    % KA01
substrate_component(paddy_straw).                                % KA01
substrate_component(sugarcane_bagasse).                          % KA01
substrate_component(cotton_waste).                               % KA01

% ---------------------------------------------------------------------
% variety(Name, ColourDescription).
% Known Sri Lankan oyster mushroom varieties.
% ---------------------------------------------------------------------
variety(american_oyster, white).                                 % KA04
variety(abalone,         light_greyish_brown).                   % KA04
variety(pink_oyster,     pink).                                  % KA04

% ---------------------------------------------------------------------
% disease_cause(Problem, CausalAgent).
% ---------------------------------------------------------------------
disease_cause(green_mold_contamination, trichoderma_spp).        % KA16
disease_cause(bacterial_brown_blotch,   pseudomonas_tolaasii).   % KA18

% ---------------------------------------------------------------------
% disease_symptom(Problem, Symptom).
% ---------------------------------------------------------------------
disease_symptom(green_mold_contamination, green_patches_on_substrate). % KA16
disease_symptom(bacterial_brown_blotch,   brown_spots_on_cap).         % KA18

% ---------------------------------------------------------------------
% recommendation(Problem, Action).
% The management / corrective action for a diagnosed problem.
% ---------------------------------------------------------------------
recommendation(high_co2_stress,
    'Increase fresh-air exchange; fully change the air in the fruiting room every 8-10 minutes.'). % KA08, KA09
recommendation(insufficient_light,
    'Provide 12-18 hours/day of indirect fluorescent or LED light at reading intensity.').          % KA11
recommendation(low_humidity_stress,
    'Increase misting frequency and use a humidity tent; maintain 80-90% relative humidity.').      % KA07, KA15
recommendation(green_mold_contamination,
    'Remove the affected bag away from the growing room; re-sterilise equipment and improve substrate sterilisation for the next batch.'). % KA16
recommendation(bacterial_brown_blotch,
    'Reduce free water on caps, improve air movement, avoid late-day overhead misting, and use clean irrigation water.'). % KA18
recommendation(pest_infestation,
    'Fit wire mesh screens on all doors and windows and improve room sanitation.').                 % KA19
recommendation(poor_spawn_quality,
    'Source fresh spawn from a reputable supplier and discard old or discoloured spawn.').          % KA20
recommendation(overcrowding,
    'Reduce the number of bags per shelf/unit area to restore air circulation.').                   % KA21
recommendation(no_pinning,
    'Verify full colonisation, strengthen fresh-air exchange to lower CO2, and ensure a ~5C drop to fruiting temperature.'). % KA12
recommendation(pin_abortion,
    'Stabilise CO2 and humidity; avoid fluctuating fresh-air exchange during pin development.').     % KA14
recommendation(delayed_pinning,
    'Move blocks to a fruiting space roughly 5C cooler than the colonisation room to trigger pinning.'). % KA06
recommendation(airflow_without_humidity,
    'Add fresh-air exchange AND maintain 80-90% humidity together; one without the other still stalls fruiting.'). % KA13
recommendation(general_contamination,
    'Re-sterilise substrate and equipment, dispose of spent substrate away from the growing room, and tighten hygiene practices.'). % KA17
recommendation(possible_viral_infection,
    'Isolate and destroy affected blocks; source certified virus-free spawn for the next batch and disinfect the growing room.'). % KA22

% ---------------------------------------------------------------------
% problem_label(ProblemId, HumanReadableLabel).
% Cosmetic mapping used only when rendering output.
% ---------------------------------------------------------------------
problem_label(high_co2_stress,          'High CO2 Stress').
problem_label(insufficient_light,       'Insufficient Light').
problem_label(low_humidity_stress,      'Low Humidity Stress').
problem_label(no_pinning,               'No Pinning').
problem_label(delayed_pinning,          'Delayed Pinning').
problem_label(pin_abortion,             'Pin Abortion').
problem_label(airflow_without_humidity, 'Airflow Without Humidity').
problem_label(overcrowding,             'Overcrowding').
problem_label(green_mold_contamination, 'Green Mold Contamination').
problem_label(bacterial_brown_blotch,   'Bacterial Brown Blotch Disease').
problem_label(general_contamination,    'General Contamination').
problem_label(pest_infestation,         'Pest Infestation').
problem_label(poor_spawn_quality,       'Poor Spawn Quality').
problem_label(possible_viral_infection, 'Possible Viral Infection').
