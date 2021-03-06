%%%
%%% QuickCheck example, checking properties some C code
%%%
%%% Created by Ken Friis Larsen <kflarsen@diku.dk>

-module(bsearch_eqc).
-include_lib("eqc/include/eqc.hrl").
-compile(export_all).


index([], _K, _I) ->
    -1;
index([K | _T], K, I) ->
    I;
index([_ | T], K, I) ->
    index(T, K, I+1).



prop_binsearch_buggy() ->
    ?SETUP(fun () -> eqc_c:start(bsearch),
                     fun() -> ok end
           end,
    ?FORALL({K, L}, {int(), list(int())},
            begin
                Sorted = lists:usort(L),
                P = eqc_c:create_array(int, Sorted),
                Size = length(Sorted),

                fails(equals(index(Sorted, K, 0),
                             catch bsearch:binsearch3(P, Size, K)))
            end)).


prop_binsearch() ->
    ?SETUP(fun () -> eqc_c:start(bsearch),
                     fun() -> ok end
           end,
    ?FORALL({K, L}, {int(), list(int())},
            begin
                Sorted = lists:usort(L),
                P = eqc_c:create_array(int, Sorted),
                Size = length(Sorted),

                equals(index(Sorted, K, 0),
                       bsearch:binsearch4(P, Size, K))
            end)).



% Version, where we generate keys actually found in the list with much
% higher probability.
prop_binsearch_better_examples() ->
    ?SETUP(fun () -> eqc_c:start(bsearch),
                     fun() -> ok end
           end,
    ?FORALL(L, list(int()),
    ?LETSHRINK(K, good_key(L),
            begin
                Sorted = lists:usort(L),
                P = eqc_c:create_array(int, Sorted),
                Size = length(Sorted),

                ?WHENFAIL(io:format("Trying to find key: ~p~n", [K]),
                equals(index(Sorted, K, 0),
                       bsearch:binsearch4(P, Size, K)))
            end))).

good_key(L) ->
    frequency([ {1, int()} | 
                [ {9, elements(lists:usort(L))} || L /= [] ]]
              ).


% Deferred equality gives us the property that we always return the
% smallest index, which means that we can deal the duplicate elements
% in the testing (hence we use lists:sort instead of lists:usort).
prop_binsearch_deferred_equality() ->
    ?SETUP(fun () -> eqc_c:start(bsearch),
                     fun() -> ok end
           end,
    ?FORALL(L, list(int()),
    ?LETSHRINK(K, good_key(L),
            begin
                Sorted = lists:sort(L),
                P = eqc_c:create_array(int, Sorted),
                Size = length(Sorted),

                ?WHENFAIL(io:format("Trying to find key: ~p~n", [K]),
                equals(index(Sorted, K, 0),
                       bsearch:binsearch8(P, Size, K)))
            end))).

% Helper function for buggy deferred equality functions
prop_binsearch_deferred_equality_buggy(Fun) ->
    ?SETUP(fun () -> eqc_c:start(bsearch),
                     fun() -> ok end
           end,
    ?FORALL(L, list(int()),
    ?LETSHRINK(K, good_key(L),
            begin
                Sorted = lists:sort(L),
                P = eqc_c:create_array(int, Sorted),
                Size = length(Sorted),

                fails(equals({Sorted, K, index(Sorted, K, 0)},
                             {Sorted, K, catch bsearch:Fun(P, Size, K)}))
            end))).

prop_binsearch5() -> prop_binsearch_deferred_equality_buggy(binsearch5). 
prop_binsearch6() -> prop_binsearch_deferred_equality_buggy(binsearch6). 
prop_binsearch7() -> prop_binsearch_deferred_equality_buggy(binsearch7). 
