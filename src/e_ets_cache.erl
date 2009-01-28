%% The contents of this file are subject to the Erlang Web Public License,
%% Version 1.0, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Web Public License along with this software. If not, it can be
%% retrieved via the world wide web at http://www.erlang-consulting.com/.
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%%
%% The Initial Developer of the Original Code is Erlang Training & Consulting
%% Ltd. Portions created by Erlang Training & Consulting Ltd are Copyright 2008,
%% Erlang Training & Consulting Ltd. All Rights Reserved.

%%%-------------------------------------------------------------------
%%% File    : e_ets_cache.erl
%%% @author Michal Ptaszek <info@erlang-consulting.com>
%%% @doc Module responsible for managing the ets cached xmerl records.
%%% @end
%%%-------------------------------------------------------------------
-module(e_ets_cache).

-export([read_file/1, install/0]).

install() ->
    ets:new(?MODULE, [named_table, public]).

%%
%% @spec read_file(Filename :: string()) -> term()
%% @doc Reads the file from ets cache.
%% If the file has not been cached or the original one has changed, 
%% the cache will be read once again.<br/>
%% When the specified file is missing 
%% the <b>erlang:error({Reason, File})</b> is called.
%% @end
%%
-spec(read_file/1 :: (string()) -> term()).	     
read_file(File) ->
    case valid_cache(File) of
	false ->
	    cache(File);
	CXML ->
	    binary_to_term(CXML)
    end.

-spec(valid_cache/1 :: (string()) -> false | binary()).	     
valid_cache(File) ->
    case ets:lookup(?MODULE, File) of
	[{_, Stamp, CXML}] ->
	    case filelib:last_modified(File) > Stamp of
		true ->
		    false;
		false ->
		    CXML
	    end;
	[] ->
	    false
    end.

-spec(cache/1 :: (string()) -> term()).	     
cache(File) ->
    XML = case xmerl_scan:file(File, []) of
	      {error, enoent} ->
		  case xmerl_scan:file(e_conf:template_root() ++ "/" ++ File, []) of
		      {error, Reason} ->
			  erlang:error({Reason, File});
		      {XML2, _} ->
			  XML2
		  end;
	      {error, Reason} ->
		  erlang:error(Reason);
	      {XML3, _} ->
		  XML3
	  end,
    
    ets:insert(?MODULE, {File, {date(), time()}, term_to_binary(XML)}),
    
    XML.