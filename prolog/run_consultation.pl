% =====================================================================
%  run_consultation.pl
%  Command-line / subprocess entry point used by the FastAPI backend.
%
%  Usage:
%      swipl -q -f run_consultation.pl -g main -t halt
%
%  Reads one JSON object from stdin (the consultation request),
%  writes one JSON object to stdout (the diagnosis report), and exits.
%  Kept deliberately tiny and dependency-free so it can be called as a
%  subprocess from Python without needing a Prolog<->Python binding
%  such as pyswip.
% =====================================================================

:- ensure_loaded(engine).
:- use_module(library(http/json)).

main :-
    catch(
        ( json_read_dict(user_input, Request, [value_string_as(atom)]),
          consult_json(Request, Response),
          json_write_dict(current_output, Response, [width(0)]),
          nl
        ),
        Error,
        ( reset_case,
          format(atom(Msg), '~w', [Error]),
          ErrorDict = _{error: true, message: Msg},
          json_write_dict(current_output, ErrorDict, [width(0)]),
          nl
        )
    ).
