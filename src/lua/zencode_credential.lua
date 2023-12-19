--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Saturday, 9th April 2022
--]]

-- ABC/COCONUT implementation in Zencode

local CRED = require_once('crypto_credential')
-- local G1 = ECP.generator()
local G2 = ECP2.generator()

local function import_issuer_pk_f(obj)
    local res = {}
    local supp = schema_get(obj, '.')
    if (type(supp) == 'zenroom.octet') then
        res.alpha = ECP2.from_zcash(supp:sub(1, 96))
        res.beta = ECP2.from_zcash(supp:sub(97, 192))
    else
        res.alpha = schema_get(obj, 'alpha', ECP2.new)
        res.beta = schema_get(obj, 'beta', ECP2.new)
    end
    return res
end

local function export_compressed_issuer_pk_f(obj)
    return obj.alpha:to_zcash()..obj.beta:to_zcash()
end

local function import_credential_request_f(obj)
    local req = {
        sign = {
            a = schema_get(obj.sign, 'a', ECP.new),
            b = schema_get(obj.sign, 'b', ECP.new)
        },
        pi_s = {
            rr = schema_get(obj.pi_s, 'rr', INT.new, O.from_base64),
            rm = schema_get(obj.pi_s, 'rm', INT.new, O.from_base64),
            rk = schema_get(obj.pi_s, 'rk', INT.new, O.from_base64),
            commit = schema_get(obj.pi_s, 'commit', INT.new, O.from_base64),
        },
        commit = schema_get(obj, 'commit', ECP.new),
        public = schema_get(obj, 'public', ECP.new)
    }
    zencode_assert(
        CRED.verify_pi_s(req),
        'Error in credential request: proof is invalid (verify_pi_s)'
    )
    return req
end

-- exported function (non local) for use in zencode_petition
function import_credential_proof_f(obj)
    return {
        nu = schema_get(obj, 'nu', ECP.new),
        kappa = schema_get(obj, 'kappa', ECP2.new),
        pi_v = {
            c = schema_get(obj.pi_v, 'c', INT.new, O.from_base64),
            rm = schema_get(obj.pi_v, 'rm', INT.new, O.from_base64),
            rr = schema_get(obj.pi_v, 'rr', INT.new, O.from_base64)
        },
        sigma_prime = {
            h_prime = schema_get(obj.sigma_prime, 'h_prime', ECP.new),
            s_prime = schema_get(obj.sigma_prime, 's_prime', ECP.new)
        }
    }
end

function export_credential_proof_f(obj)
    obj.pi_v.rr = obj.pi_v.rr:octet()
    obj.pi_v.rm = obj.pi_v.rm:octet()
    obj.pi_v.c = obj.pi_v.c:octet()
    return obj
end

ZEN:add_schema(
    {
        -- theta: blind proof of certification
        credential_proof = {
            import = import_credential_proof_f,
            export = export_credential_proof_f,
        },
        issuer_public_key = {
            import = import_issuer_pk_f
        },
        compressed_issuer_public_key = {
            import = import_issuer_pk_f,
            export = export_compressed_issuer_pk_f
        },
        credential_request = {
            import = import_credential_request_f
        }
    }
)

-- credential keypair operations
When("create credential key",function()
	initkeyring'credential'
	ACK.keyring.credential = INT.random()
end)

When("create credential key with secret key ''",function(sec)
	initkeyring'credential'
	local secret = have(sec)
	ACK.keyring.credential = INT.new(secret)
end)
When("create credential key with secret ''",function(sec)
	initkeyring'credential'
	local secret = have(sec)
	ACK.keyring.credential = INT.new(secret)
end)

When("create issuer key",function()
		initkeyring'issuer'
		ACK.keyring.issuer = CRED.issuer_keygen()
	end
)

When("create issuer public key",function()
	havekey'issuer'
	ACK.issuer_public_key = {
	   alpha = G2 * ACK.keyring.issuer.x,
	   beta = G2 * ACK.keyring.issuer.y
	}
	new_codec'issuer public key'
end)

When("create credential request", function()
	havekey'credential'
	ACK.credential_request = CRED.prepare_blind_sign(ACK.keyring.credential)
	new_codec('credential request')
end)

-- issuer's signature of credentials
ZEN:add_schema(
   {
      -- sigmatilde
      credential_signature = {
		 import = function(obj)
			return {
			   h = schema_get(obj, 'h', ECP.new),
			   b_tilde = schema_get(obj, 'b_tilde', ECP.new),
			   a_tilde = schema_get(obj, 'a_tilde', ECP.new)
			}
		 end
	  },
      -- aggsigma: aggregated signatures of ca issuers
	  credentials = {
		 import = function(obj)
			return {
			   h = schema_get(obj, 'h', ECP.new),
			   s = schema_get(obj, 's', ECP.new)
			}
		 end
	  }
   }
)
When("create credential signature",function()
		have 'credential request'
      havekey'issuer'
      ACK.credential_signature =
	 CRED.blind_sign(ACK.keyring.issuer, ACK.credential_request)
      ACK.verifier = {
	 alpha = G2 * ACK.keyring.issuer.x,
	 beta = G2 * ACK.keyring.issuer.y
      }
      new_codec'credential signature'
      new_codec'verifier'
   end
)
When("create credentials",function()
      have 'credential signature'
      havekey'credential'
      -- prepare output with an aggregated sigma credential
      -- requester signs the sigma with private key
      ACK.credentials =
	 CRED.aggregate_creds(ACK.keyring.credential, {ACK.credential_signature})
      new_codec'credentials'
   end
)

When("aggregate credentials in ''",function(creds)
      local cred_t = have(creds)
      havekey'credential'
      -- prepare output with an aggregated sigma credential
      -- requester signs the sigma with private key
      ACK.credentials =
		 CRED.aggregate_creds(ACK.keyring.credential, cred_t)
      new_codec'credentials'
   end
)

When("aggregate issuer public keys",function()
		have 'issuer public key'
		if not ACK.verifiers then
			ACK.verifiers = {}
		end
		for k, v in pairs(ACK.issuer_public_key) do
			ACK.verifiers[k] = v
		end
		-- TODO: aggregate all array
		new_codec'verifiers'
	end
)


When("aggregate verifiers in ''",function(issuers)
		local issuers_t = have(issuers)
		empty''
		local res = { alpha = nil, beta = nil}
		for k, v in pairs(issuers_t) do
		   if not res.alpha then res.alpha = v.alpha
			  else res.alpha = res.alpha + v.alpha end
		   if not res.beta then res.beta = v.beta
			  else res.beta = res.beta + v.beta end
		end
		ACK.verifiers = res
		new_codec'verifiers'
	end
)

When("create credential proof",function()
		have 'verifiers'
		have 'credentials'
		empty 'credential proof'
		havekey'credential'
		ACK.credential_proof =
			CRED.prove_cred(ACK.verifiers, ACK.credentials, ACK.keyring.credential)
		new_codec('credential proof')
	end
)
IfWhen("verify credential proof",function()
		have 'credential proof'
		have 'verifiers'
		zencode_assert(
			CRED.verify_cred(ACK.verifiers, ACK.credential_proof),
			'Credential proof does not validate'
		)
	end
)
