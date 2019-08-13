-- This file is part of Zenroom (https://zenroom.dyne.org)
--
-- Copyright (C) 2018-2019 Dyne.org foundation
-- designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Affero General Public License as
-- published by the Free Software Foundation, either version 3 of the
-- License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.



--- Zencode data internals

-- the main security concern in this Zencode module is that no data
-- passes without validation from IN to ACK or from inline input.

-- GIVEN

Given("I introduce myself as ''", function(name) ZEN:Iam(name) end)
Given("I am known as ''", function(name) ZEN:Iam(name) end)

local have_a = function(name)
   ZEN:pick(name)
   ZEN:ack(name)
end
Given("I have a valid ''", have_a)
Given("I have a ''", have_a)

local have_my = function(name)
   ZEN:pickin(ACK.whoami, name)
   ZEN:ack(name)
end
Given("I have my valid ''", have_my)
Given("I have my ''", have_my)
Given("I have my '' key", have_my)
Given("I have my valid '' key", have_my)

local have_in = function(s, n)
   ZEN:pickin(s, n)
   ZEN:ack(n)
end
Given("I have inside '' a valid ''", have_in)
Given("I have inside '' a valid '' key", have_in)

Given("I set '' to ''", function(k,v)
		 ZEN.assert(not TMP[k], "Cannot overwrite TMP["..k.."]")
		 TMP[k] = JSON.autoconv(v)
end)

-- this enforces identity of schema with key name
Given("the '' is valid", function(k)
		 ZEN:ack(k)
end)

--- WHEN

When("I draft the string ''", function(s) ZEN:draft(s) end)


--- THEN

Then("print '' ''", function(k,v)
		OUT[k] = v
end)

Then("print all data", function()
		OUT = ACK
		OUT.whoami = nil
end)
Then("print my data", function()
		ZEN:Iam() -- sanity checks
		OUT[ACK.whoami] = ACK
		OUT[ACK.whoami].whoami = nil
end)
Then("print my ''", function(obj)
		ZEN:Iam()
		ZEN.assert(ACK[obj], "Data not found in ACK: "..obj)
		if not OUT[ACK.whoami] then OUT[ACK.whoami] = { } end
		OUT[ACK.whoami][obj] = ACK[obj]
end)
Then("print my draft", function()
		ZEN:draft() -- sanity checks
		OUT[ACK.whoami] = { draft = ACK.draft:string() }
end)

function _print_my_draft_as(conv)
   ZEN:draft()
   OUT[ACK.whoami] = { draft = ZEN:convert(ACK.draft, conv) }
end
Then("print as '' my draft", _print_mydraft_as)
Then("print my draft as ''", _print_mydraft_as)

Then("print as '' my ''", function(conv,obj)
		ZEN:draft()
		OUT[ACK.whoami] = { draft = ZEN:convert(ACK[obj], conv) }
end)

Then("print the ''", function(key)
		OUT[key] = ACK[key]
end)
Then("print as '' the ''", function(conv, obj)
		OUT[obj] = ZEN:convert(ACK[obj], conv)
end)
Then("print as '' the '' inside ''", function(conv, obj, section)
		ZEN.assert(ACK[section][obj], "Not found "..obj.." inside "..section)
		OUT[obj] = ZEN:convert(ACK[section][obj], conv)
end)

-- debug functions
Given("debug", function() ZEN.debug() end)
When("debug",  function() ZEN.debug() end)
Then("debug",  function() ZEN.debug() end)
