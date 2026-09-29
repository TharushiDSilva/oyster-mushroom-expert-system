% =====================================================================
%  engine.pl
%  Inference engine for the Oyster Mushroom Cultivation Problem
%  Diagnosis Expert System.
%
%  Loads facts.pl and rules.pl, then provides:
%    - case-fact management  (assert_case_facts/1, reset_case/0)
%    - backward chaining     (diagnose/1)
%    - forward chaining      (forward_chain/0)
%    - explanation building  (build_report/2)
%    - a JSON request/response entry point (consult_json/2), used by
%      run_consultation.pl (the script FastAPI invokes as a subprocess)
% =====================================================================

:- ensure_loaded(facts).
:- ensure_loaded(rules).

:- use_module(library(http/json)).
:- use_module(library(lists)).

% ---------------------------------------------------------------------
% Case facts: asserted per consultation from the grower's input, and
% retracted again before/after every run so consultations never leak
% into one another.
% ---------------------------------------------------------------------
:- dynamic(observed_symptom/1).
:- dynamic(current_condition/2).
:- dynamic(growth_stage/1).
:- dynamic(days_since/2).
:- dynamic(hygiene_practice/2).
:- dynamic(room_condition/2).

% Derived facts (forward chaining only -- backward chaining computes
% diagnose/1 fresh every time and does not assert anything).
:- dynamic(diagnosed/1).
:- dynamic(rule_fired/2).
:- dynamic(evidence_for/2).

reset_case :-
    retractall(observed_symptom(_)),
    retractall(current_condition(_, _)),
    retractall(growth_stage(_)),
    retractall(days_since(_, _)),
    retractall(hygiene_practice(_, _)),
    retractall(room_condition(_, _)),
    retractall(diagnosed(_)),
    retractall(rule_fired(_, _)),
    retractall(evidence_for(_, _)).

% ---------------------------------------------------------------------
% solve(+Conditions)
% Proves every goal in a rule's condition list, left to right, so a
% variable bound by an earlier goal (Stage, H, D, PPM, Min, Max, ...)
% is available to later goals -- this is what lets one rule/3 fact
% serve both diagnose/1 (backward chaining) and forward_chain/0
% (forward chaining).
% ---------------------------------------------------------------------
solve([]).
solve([Goal|Rest]) :-
    call(Goal),
    solve(Rest).

% ---------------------------------------------------------------------
% BACKWARD CHAINING
% diagnose(Problem) succeeds once for every rule whose conditions hold
% against the current case facts. Left undeclared as dynamic on
% purpose: it is a pure, re-computed-every-time view over rule/3 plus
% whatever case facts are currently asserted, never itself asserted.
% ---------------------------------------------------------------------
diagnose(Problem) :-
    rule(_RuleId, Conditions, Problem),
    solve(Conditions).

% diagnose_with_rule(Problem, RuleId, Conditions) is the same search,
% but also hands back which rule fired and its (now-bound) condition
% list, for building the explanation/evidence trail.
diagnose_with_rule(Problem, RuleId, Conditions) :-
    rule(RuleId, Conditions, Problem),
    solve(Conditions).

% All (Problem, RuleId, Conditions) triples currently provable.
all_diagnoses(Triples) :-
    findall(t(Problem, RuleId, Conditions),
            diagnose_with_rule(Problem, RuleId, Conditions),
            Triples).

% ---------------------------------------------------------------------
% FORWARD CHAINING
% Repeatedly scans rule/3, asserting diagnosed/1 (plus rule_fired/2
% and evidence_for/2) for every rule whose conditions currently hold,
% until a full pass derives nothing new (fixpoint). Demonstrates
% data-driven reasoning starting purely from the asserted case facts,
% independent of any single query.
% ---------------------------------------------------------------------
forward_chain :-
    forward_pass(Changed),
    ( Changed == true -> forward_chain ; true ).

forward_pass(Changed) :-
    findall(RuleId-Conclusion-Conditions,
            ( rule(RuleId, Conditions, Conclusion),
              \+ rule_fired(Conclusion, RuleId),
              solve(Conditions)
            ),
            NewOnes),
    ( NewOnes == []
    -> Changed = false
    ;  Changed = true,
       forall(member(RuleId-Conclusion-Conditions, NewOnes),
              record_derivation(Conclusion, RuleId, Conditions))
    ).

record_derivation(Conclusion, RuleId, Conditions) :-
    ( diagnosed(Conclusion) -> true ; assertz(diagnosed(Conclusion)) ),
    ( rule_fired(Conclusion, RuleId) -> true ; assertz(rule_fired(Conclusion, RuleId)) ),
    include(is_evidence_worthy, Conditions, Worthy),
    forall(member(Cond, Worthy),
           ( evidence_for(Conclusion, Cond) -> true ; assertz(evidence_for(Conclusion, Cond)) )).

% ---------------------------------------------------------------------
% EXPLANATION BUILDING
% ---------------------------------------------------------------------

% condition_text(+Goal, -Text) renders one (now-bound) condition goal
% as a short, human-readable clause used inside the explanation
% sentence.
condition_text(observed_symptom(S), Text) :-
    !, format(atom(Text), '~w was observed', [S]).
condition_text(current_condition(K, V), Text) :-
    !, format(atom(Text), '~w is ~w', [K, V]).
condition_text(growth_stage(S), Text) :-
    !, format(atom(Text), 'the crop is in the ~w stage', [S]).
condition_text(days_since(Event, D), Text) :-
    !, format(atom(Text), '~w days have passed since ~w', [D, Event]).
condition_text(hygiene_practice(P, S), Text) :-
    !, format(atom(Text), '~w hygiene was reported ~w', [P, S]).
condition_text(room_condition(F, S), Text) :-
    !, format(atom(Text), 'room condition ~w is ~w', [F, S]).
condition_text(\+ diagnose(Problem), Text) :-
    !, ( problem_label(Problem, Label) -> true ; Label = Problem ),
    format(atom(Text), '~w was ruled out', [Label]).
condition_text(\+ Goal, Text) :-
    !, condition_text(Goal, Inner),
    format(atom(Text), 'no evidence that ~w', [Inner]).
condition_text(disease_cause(P, A), Text) :-
    !, format(atom(Text), '~w is the documented cause of ~w', [A, P]).
condition_text(Goal, Text) :-
    % Fallback for numeric-comparison / lookup goals (co2_threshold/2,
    % optimal_condition/5, photoperiod/3, plain comparisons, etc.)
    format(atom(Text), '~w', [Goal]).

% Only the "positive" (non comparison/lookup-only) conditions are
% surfaced as evidence; numeric comparisons and threshold lookups are
% folded into the sentence but not duplicated as separate evidence
% lines, since they only make sense alongside the values they compare.
is_evidence_worthy(observed_symptom(_)).
is_evidence_worthy(current_condition(_, _)).
is_evidence_worthy(growth_stage(_)).
is_evidence_worthy(days_since(_, _)).
is_evidence_worthy(hygiene_practice(_, _)).
is_evidence_worthy(room_condition(_, _)).
is_evidence_worthy(\+ _).

evidence_list(Conditions, EvidenceTexts) :-
    include(is_evidence_worthy, Conditions, Worthy),
    maplist(condition_text, Worthy, EvidenceTexts).

explanation_sentence(Problem, RuleIds, Conditions, Text) :-
    ( problem_label(Problem, Label) -> true ; Label = Problem ),
    evidence_list(Conditions, EvidenceTexts),
    atomic_list_concat(EvidenceTexts, '; ', EvidenceStr),
    atomic_list_concat(RuleIds, ', ', RuleStr),
    upcase_atom(RuleStr, RuleStrUpper),
    format(atom(Text), 'Because ~w, rule(s) ~w concluded: ~w.',
           [EvidenceStr, RuleStrUpper, Label]).

% ---------------------------------------------------------------------
% build_report(+Mode, -Report)
% Mode = backward | forward. Report is a list of dicts, one per
% distinct diagnosed problem, each carrying everything the UI needs:
% problem id, label, evidence, rules applied, explanation and
% recommendation.
% ---------------------------------------------------------------------
build_report(backward, Report) :-
    all_diagnoses(Triples),
    group_by_problem(Triples, Grouped),
    maplist(triple_group_to_dict, Grouped, Report).

build_report(forward, Report) :-
    forward_chain,
    findall(Problem, diagnosed(Problem), Problems0),
    list_to_set(Problems0, Problems),
    maplist(forward_problem_to_dict, Problems, Report).

% --- backward-chaining grouping -----------------------------------
group_by_problem(Triples, Grouped) :-
    findall(Problem, member(t(Problem, _, _), Triples), Problems0),
    list_to_set(Problems0, Problems),
    maplist(collect_for_problem(Triples), Problems, Grouped).

collect_for_problem(Triples, Problem, Problem-RuleIds-AllConditions) :-
    findall(RuleId-Conditions,
            member(t(Problem, RuleId, Conditions), Triples),
            Pairs),
    pairs_keys_values(Pairs, RuleIds, ConditionLists),
    append(ConditionLists, AllConditionsDup),
    list_to_set(AllConditionsDup, AllConditions).

triple_group_to_dict(Problem-RuleIds-Conditions, Dict) :-
    ( problem_label(Problem, Label) -> true ; Label = Problem ),
    evidence_list(Conditions, EvidenceTexts),
    explanation_sentence(Problem, RuleIds, Conditions, Explanation),
    ( recommendation(Problem, Rec) -> true ; Rec = 'No specific recommendation on file; consult an extension officer.' ),
    maplist(upcase_atom, RuleIds, RuleIdsUpper),
    Dict = _{
        problem: Problem,
        label: Label,
        evidence: EvidenceTexts,
        rules_applied: RuleIdsUpper,
        explanation: Explanation,
        recommendation: Rec
    }.

% --- forward-chaining rendering -------------------------------------
forward_problem_to_dict(Problem, Dict) :-
    ( problem_label(Problem, Label) -> true ; Label = Problem ),
    findall(RuleId, rule_fired(Problem, RuleId), RuleIds),
    findall(Text, ( evidence_for(Problem, Cond), condition_text(Cond, Text) ), EvidenceTexts0),
    list_to_set(EvidenceTexts0, EvidenceTexts),
    maplist(upcase_atom, RuleIds, RuleIdsUpper),
    atomic_list_concat(EvidenceTexts, '; ', EvidenceStr),
    atomic_list_concat(RuleIdsUpper, ', ', RuleStr),
    ( recommendation(Problem, Rec) -> true ; Rec = 'No specific recommendation on file; consult an extension officer.' ),
    format(atom(Explanation), 'Because ~w, rule(s) ~w concluded: ~w.', [EvidenceStr, RuleStr, Label]),
    Dict = _{
        problem: Problem,
        label: Label,
        evidence: EvidenceTexts,
        rules_applied: RuleIdsUpper,
        explanation: Explanation,
        recommendation: Rec
    }.

% ---------------------------------------------------------------------
% JSON REQUEST / RESPONSE
% ---------------------------------------------------------------------

% assert_case_facts(+Dict)
% Translates the request dict (already normalised by FastAPI, see
% backend/prolog_bridge.py) into asserted case facts.
assert_case_facts(Dict) :-
    ( get_dict(growth_stage, Dict, StageAtomIn) ->
        atom_string(Stage, StageAtomIn), assertz(growth_stage(Stage))
    ; true ),
    ( get_dict(days_since_spawning, Dict, Days) ->
        assertz(days_since(spawning, Days))
    ; true ),
    ( get_dict(symptoms, Dict, Symptoms) ->
        forall(member(SymIn, Symptoms),
               ( atom_string(Sym, SymIn), assertz(observed_symptom(Sym)) ))
    ; true ),
    ( get_dict(conditions, Dict, Conditions) ->
        assert_conditions(Conditions)
    ; true ),
    ( get_dict(hygiene, Dict, Hygiene) ->
        assert_kv(Hygiene, hygiene_practice)
    ; true ),
    ( get_dict(room, Dict, Room) ->
        assert_kv(Room, room_condition)
    ; true ).

assert_conditions(Conditions) :-
    dict_pairs(Conditions, _, Pairs),
    forall(member(KeyIn-Value, Pairs),
           assert_one_condition(KeyIn, Value)).

% Numeric readings are asserted as current_condition(key, Number).
% String/category readings are asserted as current_condition(key, atom).
assert_one_condition(KeyIn, Value) :-
    atom_string(Key, KeyIn),
    ( number(Value) ->
        assertz(current_condition(Key, Value))
    ; ( atom_string(Atom, Value), assertz(current_condition(Key, Atom)) )
    ).

assert_kv(Dict, Functor) :-
    dict_pairs(Dict, _, Pairs),
    forall(member(KeyIn-ValueIn, Pairs),
           ( atom_string(Key, KeyIn),
             atom_string(Value, ValueIn),
             Fact =.. [Functor, Key, Value],
             assertz(Fact) )).

% consult_json(+RequestDict, -ResponseDict)
% RequestDict is the parsed JSON body sent by FastAPI:
%   { growth_stage, days_since_spawning, symptoms, conditions,
%     hygiene, room, mode }
% mode defaults to "backward"; pass "forward" to run forward chaining
% instead (used by the /consult?mode=forward demonstration endpoint).
consult_json(RequestDict, ResponseDict) :-
    reset_case,
    assert_case_facts(RequestDict),
    ( get_dict(mode, RequestDict, ModeIn) ->
        atom_string(Mode, ModeIn)
    ; Mode = backward
    ),
    build_report(Mode, Diagnoses),
    ResponseDict = _{mode: Mode, diagnoses: Diagnoses},
    reset_case.
