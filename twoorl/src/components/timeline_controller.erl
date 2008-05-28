%% This file is part of Twoorl.
%% 
%% Twoorl is free software: you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation, either version 3 of the License, or
%% (at your option) any later version.
%% 
%% Twoorl is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%% 
%% You should have received a copy of the GNU General Public License
%% along with Twoorl.  If not, see <http://www.gnu.org/licenses/>.
%%
%% Copyright Yariv Sadan, 2008
%%
%% @author Yariv Sadan <yarivsblog@gmail.com> [http://yarivsblog.com]
%% @copyright Yariv Sadan, 2008

-module(timeline_controller).
-compile(export_all).
-include("twoorl.hrl").

private() ->
    true.

index(A) ->
    {data, undefined}.

show(A) ->
    show(A, undefined).

show(A, Usr) when not is_list(Usr), Usr =/= undefined ->
    show(A, [Usr:id()]);

show(A, UsrIds) ->
    show(A, UsrIds, []).

show(A, UsrIds, Opts) ->
    OrderBy = {order_by, {created_on, desc}},
    
    %% this function is a prime optimization candidate
    Total = 
	if UsrIds =/= undefined ->
		msg:count('*', {usr_id, in, UsrIds});
	   true ->
		msg:count('*')
	end,
    {replace, 
     {ewc, paging,
      [A, fun(Limit) ->
		  if UsrIds =/= undefined ->
			  msg:find({usr_id,in,UsrIds}, [OrderBy, Limit]);
		     true ->
			  msg:find_with([OrderBy, Limit])
		  end
	  end,
       fun(Msgs) ->
	       {ewc, timeline, show_msgs, [A, Msgs, Opts]}
       end,
       [{total, Total}]]}}.

show_msgs(A, Msgs) ->
    show_msgs(A, Msgs, []).

show_msgs(A, Msgs, Opts) ->
    Opts1 =
	case proplists:get_value(big_first, Opts) of
	    undefined ->
		Opts;
	    true ->
		[{is_big, true} | Opts]
	end,
    if Msgs == [] ->
	    [];
       true ->
	    [{ewc, timeline, show_msg, [A, hd(Msgs), Opts1]} |
	     [{ewc, timeline, show_msg, [A, Msg, Opts]} || Msg <- tl(Msgs)]]
    end.

show_msg(A, Msg) ->
    show_msg(A, Msg, []).

show_msg(_A, Msg, Opts) ->
    Username = msg:usr_username(Msg),
    UsrLink = case proplists:get_value(hide_user, Opts) of
		  true ->
		      undefined;
		  _ -> twoorl_util:user_link(Username)
	      end,
    CreatedOn = msg:created_on(Msg),
    CreatedOn1 = twoorl_util:get_time_since(CreatedOn),
    IsBig = proplists:get_value(is_big, Opts) == true,
    
    {data, {UsrLink, msg:body(Msg), CreatedOn1, IsBig}}.
