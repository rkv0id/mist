-module(raw_ffi).

-export([exchange/3]).

%% Sends Head, then Filler bytes in 64 KB chunks until all are sent or the
%% server closes, then reads until close. Returns {Sent, Received}: how many
%% filler bytes went out and what came back (empty when the connection was
%% reset before a response could be read).
exchange(Port, Head, Filler) ->
  {ok, S} = gen_tcp:connect("localhost", Port, [binary, {active, false}, {send_timeout, 5000}]),
  ok = gen_tcp:send(S, Head),
  Sent = send_filler(S, Filler, 0),
  Received = recv_all(S, <<>>),
  gen_tcp:close(S),
  {Sent, Received}.

send_filler(_S, 0, Sent) -> Sent;
send_filler(S, Left, Sent) ->
  N = min(Left, 65536),
  case gen_tcp:send(S, binary:copy(<<"a">>, N)) of
    ok -> send_filler(S, Left - N, Sent + N);
    {error, _} -> Sent
  end.

recv_all(S, Acc) ->
  case gen_tcp:recv(S, 0, 5000) of
    {ok, Data} -> recv_all(S, <<Acc/binary, Data/binary>>);
    {error, _} -> Acc
  end.
