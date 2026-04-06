-module(integrity_test).

-include_lib("eunit/include/eunit.hrl").

new_test() ->
    ?assertMatch(<<"http://myhost.com:8080/my/path?color=red#Section%205">>,
        liburi:to_string(liburi:new(<<"http">>, <<>>, <<"myhost.com">>, 8080, <<"my/path">>, <<"color=red">>, <<"Section 5">>))).

append_path_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 8080, <<"/my/path">>, <<"color=red">>, <<"Section 5">>),
    T1 = liburi:append_path(T0, <<"additional/path">>),
    ?assertMatch(<<"http://myhost.com:8080/my/path/additional/path?color=red#Section%205">>, liburi:to_string(T1)).

append_path_trailing_slash_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 8080, <<"/my/path/">>, <<>>, <<>>),
    T1 = liburi:append_path(T0, <<"extra">>),
    ?assertMatch(<<"/my/path/extra">>, liburi:path(T1)).

append_path_leading_slash_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 80, <<"/base">>, <<>>, <<>>),
    T1 = liburi:append_path(T0, <<"/child">>),
    ?assertMatch(<<"/base/child">>, liburi:path(T1)).

append_path_both_slashes_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 80, <<"/base/">>, <<>>, <<>>),
    T1 = liburi:append_path(T0, <<"/child">>),
    ?assertMatch(<<"/base/child">>, liburi:path(T1)).

append_path_empty_new_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 80, <<"/existing">>, <<>>, <<>>),
    T1 = liburi:append_path(T0, <<>>),
    ?assertMatch(<<"/existing">>, liburi:path(T1)).

append_path_empty_existing_test() ->
    T0 = liburi:new(<<"http">>, <<"">>, <<"myhost.com">>, 80, <<>>, <<>>, <<>>),
    T1 = liburi:append_path(T0, <<"new/stuff">>),
    ?assertMatch(<<"new/stuff">>, liburi:path(T1)).

parse_scheme_test() ->
    ?assertMatch({<<"http">>, <<"//test.com/">>}, liburi_parser:parse_scheme(<<"http://test.com/">>)),
    ?assertMatch({<<>>, <<"/test">>}, liburi_parser:parse_scheme(<<"/test">>)),
    ?assertMatch({<<"mailto">>, <<"x@test.com">>}, liburi_parser:parse_scheme(<<"mailto:x@test.com">>)).

parse_authority_test() ->
    ?assertMatch({<<"test.com">>, <<"/here">>}, liburi_parser:parse_authority(<<"//test.com/here">>)),
    ?assertMatch({<<"test.com">>, <<"">>}, liburi_parser:parse_authority(<<"//test.com">>)),
    ?assertMatch({<<>>, <<"/test">>}, liburi_parser:parse_authority(<<"/test">>)).

parse_user_info_test() ->
    ?assertMatch({<<"user">>, <<"test.com">>}, liburi_parser:parse_user_info(<<"user@test.com">>)),
    ?assertMatch({<<"">>, <<"user.test.com">>}, liburi_parser:parse_user_info(<<"user.test.com">>)).

parse_host_port_test() ->
    ?assertMatch({<<"test.com">>, 8080}, liburi_parser:parse_host_port(<<"test.com:8080">>)),
    ?assertMatch({<<"test.com">>, undefined}, liburi_parser:parse_host_port(<<"test.com">>)).

parse_path_test() ->
    ?assertMatch({<<"/a/b/c">>, <<"">>}, liburi_parser:parse_path(<<"/a/b/c">>)),
    ?assertMatch({<<"/a/b/c">>, <<"?n=5">>}, liburi_parser:parse_path(<<"/a/b/c?n=5">>)),
    ?assertMatch({<<"/a/b/c">>, <<"#anchor">>}, liburi_parser:parse_path(<<"/a/b/c#anchor">>)),
    ?assertMatch({<<"/">>, <<"">>}, liburi_parser:parse_path(<<"">>)).

parse_query_test() ->
    ?assertMatch({<<"a=b">>, <<"">>}, liburi_parser:parse_query(<<"?a=b">>)),
    ?assertMatch({<<"a=b">>, <<"#anchor">>}, liburi_parser:parse_query(<<"?a=b#anchor">>)),
    ?assertMatch({<<"">>, <<"#anchor">>}, liburi_parser:parse_query(<<"#anchor">>)),
    ?assertMatch({<<"">>, <<"">>}, liburi_parser:parse_query(<<"">>)).

query_to_proplist_test() ->
    ?assertMatch([], liburi:query_to_proplist(<<>>)),
    ?assertMatch([{<<"a">>, <<"b">>}], liburi:query_to_proplist(<<"a=b&">>)),
    ?assertMatch([{<<"a">>, <<>>}], liburi:query_to_proplist(<<"a=">>)),
    ?assertMatch([{<<"a">>, null}, {<<"b">>, <<"c">>}], liburi:query_to_proplist(<<"a&b=c">>)),
    ?assertMatch([{<<"a&b">>, <<"!t=f">>}], liburi:query_to_proplist(<<"a%26b=!t%3Df">>)).

to_query_test() ->
    ?assertMatch(<<"one&two=2&three=two%20%2B%20one">>, liburi:to_query([one, {<<"two">>, 2}, {<<"three">>, <<"two + one">>}])).

proplist_query_test() ->
    QueryPropList = [{<<"foo">>, <<"bar">>}, {<<"baz">>, <<"back">>}],
    Uri0 = liburi:from_string(<<"http://myhost.com:8080/my/path?color=red#Section%205">>),
    Uri1 = liburi:q(Uri0, QueryPropList),
    ?assertMatch(<<"http://myhost.com:8080/my/path?foo=bar&baz=back#Section%205">>, liburi:to_string(Uri1)).

no_path_test() ->
    Uri0 = liburi:from_string(<<"https://something.free.domain.com?a=1&b=2">>),
    ?assertMatch(<<"https">>, liburi:scheme(Uri0)),
    ?assertMatch(443, liburi:port(Uri0)),
    ?assertMatch(<<"something.free.domain.com">>, liburi:host(Uri0)),
    ?assertMatch(<<"/">>, liburi:path(Uri0)),
    ?assertMatch( [{<<"a">>,<<"1">>},{<<"b">>,<<"2">>}], liburi:q(Uri0)).

unquote_test() ->
    ?assertMatch(<<"ab">>, liburi:unquote(<<"ab">>)),
    ?assertMatch(<<"a b">>, liburi:unquote(<<"a+b">>)),
    ?assertMatch(<<"a b">>, liburi:unquote(<<"a%20b">>)).

quote_test() ->
    ?assertMatch(<<"abc123">>, liburi:quote(<<"abc123">>)),
    ?assertMatch(<<"abc%20123">>, liburi:quote(<<"abc 123">>)).

escape_test() ->
    ?assertMatch(<<"%20">>, liburi_utils:escape($\s)).

port_undefined_test() ->
    Uri = liburi:new(<<"http">>, <<"">>, <<"example.com">>, undefined, <<"/">>, <<>>, <<>>),
    ?assertEqual(undefined, liburi:port(Uri)).

port_set_test() ->
    Uri = liburi:new(<<"http">>, <<"">>, <<"example.com">>, 3000, <<"/">>, <<>>, <<>>),
    ?assertEqual(3000, liburi:port(Uri)).

port_set_undefined_test() ->
    Uri0 = liburi:new(<<"http">>, <<"">>, <<"example.com">>, 8080, <<"/">>, <<>>, <<>>),
    Uri1 = liburi:port(Uri0, undefined),
    ?assertEqual(undefined, liburi:port(Uri1)),
    Raw = liburi:to_string(Uri1),
    ?assertMatch(nomatch, binary:match(Raw, <<":8080">>)).

path_with_spaces_test() ->
    Uri = liburi:new(<<"http">>, <<"">>, <<"example.com">>, undefined, <<"/hello world">>, <<>>, <<>>),
    Raw = liburi:to_string(Uri),
    %% The raw string must not contain a literal space in the path
    ?assertMatch(nomatch, binary:match(Raw, <<" ">>)),
    %% But the path accessor returns the unquoted form
    ?assertMatch(<<"/hello world">>, liburi:path(Uri)).

path_quoted_roundtrip_test() ->
    Uri0 = liburi:new(<<"http">>, <<"">>, <<"example.com">>, undefined, <<"/">>, <<>>, <<>>),
    Uri1 = liburi:path(Uri0, <<"/foo bar/baz">>),
    Raw = liburi:to_string(Uri1),
    ?assertMatch(nomatch, binary:match(Raw, <<" ">>)),
    ?assertMatch(<<"/foo bar/baz">>, liburi:path(Uri1)).

empty_path_produces_slash_in_raw_test() ->
    Uri = liburi:new(<<"http">>, <<"">>, <<"example.com">>, undefined, <<>>, <<>>, <<>>),
    Raw = liburi:to_string(Uri),
    %% Raw should contain "example.com/" (host followed by slash)
    ?assertMatch({_, _}, binary:match(Raw, <<"example.com/">>)).

from_http_1_1_no_user_info_test() ->
    Uri = liburi:from_http_1_1(<<"https">>, <<"example.com:443">>, <<"/path?q=1">>),
    ?assertEqual(<<"">>, liburi:user_info(Uri)),
    ?assertEqual(<<"example.com">>, liburi:host(Uri)),
    ?assertEqual(443, liburi:port(Uri)),
    ?assertEqual(<<"/path">>, liburi:path(Uri)),
    ?assertEqual([{<<"q">>, <<"1">>}], liburi:q(Uri)).

to_query_empty_test() ->
    ?assertEqual(<<>>, liburi:to_query([])).

to_query_single_pair_test() ->
    ?assertEqual(<<"key=val">>, liburi:to_query([{<<"key">>, <<"val">>}])).

to_query_multiple_pairs_test() ->
    Result = liburi:to_query([{<<"a">>, <<"1">>}, {<<"b">>, <<"2">>}]),
    ?assertEqual(<<"a=1&b=2">>, Result).

scheme_setter_test() ->
    Uri0 = liburi:from_string(<<"http://example.com/path">>),
    Uri1 = liburi:scheme(Uri0, <<"https">>),
    ?assertEqual(<<"https">>, liburi:scheme(Uri1)),
    Raw = liburi:to_string(Uri1),
    ?assertMatch({0, _}, binary:match(Raw, <<"https://">>)).

host_setter_test() ->
    Uri0 = liburi:from_string(<<"http://old.com/path">>),
    Uri1 = liburi:host(Uri0, <<"new.com">>),
    ?assertEqual(<<"new.com">>, liburi:host(Uri1)),
    Raw = liburi:to_string(Uri1),
    ?assertMatch({_, _}, binary:match(Raw, <<"new.com">>)).

frag_setter_test() ->
    Uri0 = liburi:from_string(<<"http://example.com/path">>),
    Uri1 = liburi:frag(Uri0, <<"top">>),
    ?assertEqual(<<"top">>, liburi:frag(Uri1)),
    Raw = liburi:to_string(Uri1),
    ?assertMatch({_, _}, binary:match(Raw, <<"#top">>)).

frag_with_spaces_test() ->
    Uri0 = liburi:from_string(<<"http://example.com/path">>),
    Uri1 = liburi:frag(Uri0, <<"my section">>),
    ?assertEqual(<<"my section">>, liburi:frag(Uri1)),
    Raw = liburi:to_string(Uri1),
    %% Fragment should be percent-encoded in raw
    ?assertMatch(nomatch, binary:match(Raw, <<"#my section">>)),
    ?assertMatch({_, _}, binary:match(Raw, <<"#my%20section">>)).

user_info_setter_test() ->
    Uri0 = liburi:from_string(<<"http://example.com/path">>),
    Uri1 = liburi:user_info(Uri0, <<"alice">>),
    ?assertEqual(<<"alice">>, liburi:user_info(Uri1)),
    Raw = liburi:to_string(Uri1),
    ?assertMatch({_, _}, binary:match(Raw, <<"alice@example.com">>)).

raw_query_setter_test() ->
    Uri0 = liburi:from_string(<<"http://example.com/path">>),
    Uri1 = liburi:raw_query(Uri0, <<"x=1&y=2">>),
    ?assertEqual([{<<"x">>, <<"1">>}, {<<"y">>, <<"2">>}], liburi:q(Uri1)),
    ?assertEqual(<<"x=1&y=2">>, liburi:raw_query(Uri1)).
