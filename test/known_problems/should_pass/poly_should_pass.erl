-module(poly_should_pass).

-gradualizer([solve_constraints]).

-export([find1/0,
         l/0]).

-spec lookup(T1, [{T1, T2}]) -> (none | T2).
lookup(_, []) -> none;
lookup(K, [{K, V}|_]) -> V;
lookup(K, [_|KVs]) -> lookup(K, KVs).

-spec find1() -> string().
find1() ->
    case lookup(0, [{0, "s"}]) of
        none -> "default";
        V -> V
    end.

-type t1() :: {}.
-type t2() :: binary().
-type list_of_unions() :: [t1() | t2()].

%% This fails with:
%%
%%   Lower bound [t1() | t2()] of type variable B_typechecker_3529_12 on line 25
%%   is not a subtype of t1() | t2()
%%
%% Now, why is that the case?
%% `return_list_of_unions/1' returns just that - a list of `t1() | t2()' unions.
%% This means that `takes_an_intersection/1' passed in to `lists:map/2' would be called with
%% a union as the arg, not a list.
%% This should mean that it would also return a `t1() | t2()' union, so the final return value from
%% `l/0' should be `[t1() | t2()]'.
%% However, the constraint solver is not able to tell that only one clause of the
%% multi-clause spec would suffice and it uses both clauses' return types as lower bound on `B'.
%%
%% In practice, this means that we should avoid functions
%% with intersection types like `(a()) -> b() & ([a()]) -> [b()]',
%% because the constraint solver can't cope with them.
%% We should instead define two separate functions: `(a()) -> b()' and `([a()]) -> [b()]',
%% and check outside of them which to call based on the type of the parameter.
-spec l() -> [t1() | t2()].
l() ->
    lists:map(fun takes_an_intersection/1, return_list_of_unions([])).

-spec takes_an_intersection(t1() | t2()) -> t1() | t2();
                           (list()) -> [t1() | t2()].
takes_an_intersection([]) -> [];
takes_an_intersection([_|_] = L) -> lists:map(fun takes_an_intersection/1, L);
takes_an_intersection(T) -> T.

-spec return_list_of_unions(list_of_unions()) -> list_of_unions().
return_list_of_unions(_L) -> [].
