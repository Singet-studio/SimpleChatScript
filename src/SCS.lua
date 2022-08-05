local module = {}

-- SimpleChatScript v0.1 --
-- This script is written by Kollobz for Singlet Studio --
-- You are not allowed to edit, copy or use it without Singlet Studio permission --

-- Some constants --

-- Exceptions --
Exceptions = require(script:WaitForChild("Exceptions"))
_G.SCSVars = {}
_G.SCSSVars = {}

-- Types of token --
-- STRING - string value token --
-- NUMBER - numeric value token --
-- REFERENCE - variable reference token --
-- SUBCALL - inner call token --
-- STATIC_SUBCALL - inner subcall without returning anything --
TOKEN_TYPES =
	{
		STRING = 0,
		NUMBER = 1,
		REFERENCE = 2,
		SUBCALL = 3,
		STATIC_SUBCALL = 4
	}

-- Types of arguments --
-- STRING - string argument --
-- NUMBER - numeric argument --
-- ANY - any of these --
ARGUMENT_TYPES = 
	{
		STRING = 0,
		NUMBER = 1,
		ANY = 2
	}

-- Argument type prompts --
AG_PROMPTS =
	{
		"STRING",
		"NUMBER",
		"ANY"
	}

-- Some character groups used while parsing --
NUMBERS = "0123456789."
VAR_ALLOWED_CHARS = "qwertyuiopasdfghjklzxcvbnm_"
-- These characters ignored while parsing --
IGNORED_CHARS = " \t\n"

-- Methods --

-- Token class --

Token = {}

-- Constructor --

function Token:new(tStart, tEnd, tt, v)
	local _obj = {}

	_obj.pStart = tStart	-- Token start
	_obj.pEnd = tEnd		-- Token end
	_obj.tType = tt			-- Token type
	_obj.value = v			-- Token value

	setmetatable(_obj, Token)

	self.__index = self

	return _obj
end

_G.SCSSVars.SCSVer = Token:new(0, 0, TOKEN_TYPES.NUMBER, "0.16")	-- SCS version server variable
print("Using SCS ver ".._G.SCSSVars.SCSVer.value)				-- Console prompt of SCS version

-- Additional methods --

function ContainsChar(char, str)		-- Returns true if charset str contains given character, else false
	for i = 1, #str, 1 do
		if (str:sub(i, i) == char) then
			return true
		end
	end
	return false
end

function ContainsKey(k, tbl)			-- Returns true if given table tbl contains key k, else false
	for key, _ in pairs(tbl) do
		if (k == key) then
			return true
		end
	end
	return false
end

function MakeRef(ref: string): Token	-- Creates REFERENCE token to given variable
	return Token:new(0, #ref, TOKEN_TYPES.REFERENCE, ref)
end

-- Lexer --

ReturnStack = {}	-- Code return stack

function MakeStringToken(literal, position)		-- Creates STRING token from given literal starting at given position
	if (literal:sub(position, position) == '"') then
		position = position + 1
	end

	local made_str = ""
	local start = position

	while (literal:sub(position, position) ~= '"') do
		if(position == #literal) then
			Exceptions.SyntaxError:throw("quote was never closed")
			return nil
		end
		made_str = made_str..literal:sub(position, position)
		position = position + 1
	end

	return Token:new(start, position, TOKEN_TYPES.STRING, made_str)
end

function MakeSubcallToken(literal, position)	-- Creates SUBCALL token from given literal starting at given position
	local madeSubcall = ""
	local start = position
	if (literal:sub(position, position) == "(") then
		position = position + 1
	end
	while (literal:sub(position, position) ~= ")") do
		if (position == #literal) then
			Exceptions.SyntaxError:throw("subcall was never ended")
			return nil
		end
		madeSubcall = madeSubcall..literal:sub(position, position)
		position = position + 1
	end
	
	return Token:new(start, position, TOKEN_TYPES.SUBCALL, madeSubcall)
end

function MakeStaticSubcall(literal, position)	-- Creates STATIC_SUBCALL token from given literal starting at given position
	local madeSubcall = ""
	local start = position
	if (literal:sub(position, position) == "<") then
		position = position + 1
	end
	while (literal:sub(position, position) ~= ">") do
		if (position == #literal) then
			Exceptions.SyntaxError:throw("static subcall was never ended")
			return nil
		end
		madeSubcall = madeSubcall..literal:sub(position, position)
		position = position + 1
	end
	
	return Token:new(start, position, TOKEN_TYPES.STATIC_SUBCALL, madeSubcall)
end

function MakeNumberToken(literal, position)		-- Creates NUMBER token from given literal starting at given position
	local made_num = ""
	local start = position

	while(ContainsChar(literal:sub(position, position), NUMBERS)) do
		made_num = made_num..literal:sub(position, position)
		position = position + 1
	end

	return Token:new(start, position, TOKEN_TYPES.NUMBER, made_num)
end

function MakeReferenceToken(literal, position)	-- Creates REFERENCE token from given literal starting at given position
	local made_ref = ""
	local start = position

	while(ContainsChar(string.lower(literal:sub(position, position)), VAR_ALLOWED_CHARS)) do
		made_ref = made_ref..literal:sub(position, position)
		position = position + 1
	end

	return Token:new(start, position, TOKEN_TYPES.REFERENCE, made_ref)
end

function LiteralEval(literal, position)			-- Creates token from given literal starting at given position
	local literal_start = literal:sub(position, position)

	if (literal_start == '"') then													-- STRING
		local tok = MakeStringToken(literal, position)
		if (tok == nil) then
			return nil
		end
		return {tok, #tok.value + 1}
	elseif (ContainsChar(literal_start, NUMBERS)) then								-- NUMBER
		local tok = MakeNumberToken(literal, position)
		return {tok, #tok.value}
	elseif (ContainsChar(string.lower(literal_start), VAR_ALLOWED_CHARS)) then		-- REFERENCE
		local tok = MakeReferenceToken(literal, position)
		return {tok, #tok.value}
	elseif (literal_start == "<") then												-- STATIC_SUBCALL
		local tok = MakeStaticSubcall(literal, position)
		if (tok == nil) then
			return nil
		end
		return {tok, #tok.value + 1}
	elseif (literal_start == "(") then												-- SUBCALL
		local tok = MakeSubcallToken(literal, position)
		if (tok == nil) then
			return nil
		end
		return {tok, #tok.value + 1}
	else
		return {nil, 1}
	end
end

function LuaEval(luaValue): Token				-- Creates token from given lua value
	local tp = type(luaValue)

	if (tp == "string") then													-- STRING
		return Token:new(1, #luaValue, TOKEN_TYPES.STRING, '"'..luaValue..'"')
	elseif (tp == "number") then												-- NUMBER
		return Token:new(1, #tostring(luaValue), TOKEN_TYPES.NUMBER, tostring(luaValue))
	else
		Exceptions.ConvertationException("no alternative SimpleScript type to "..tp)
	end
end

-- Evaluator --

AvailableMethods = {}

function IsValidMethod(method: string): boolean			-- Returns true if given method existsts and registered
	for methodName, _ in pairs(AvailableMethods) do
		if (methodName == method) then
			return true
		end
	end
	return false
end

function VerifyArg(arg: Token, expArg: number): boolean	-- Returns true if given value matches given expected type
	if (expArg == ARGUMENT_TYPES.ANY) then
		return true
	elseif (arg.tType == expArg) then
		return true
	else
		return false
	end
end

function VerifyArgs(args, expectedArgs): boolean		-- Returns true if all given values match given expected types
	for i = 1, #args, 1 do
		local a = args[i]
		local ea = expectedArgs[i]

		if(ea == ARGUMENT_TYPES.ANY) then
			continue
		else
			if (a.tType == TOKEN_TYPES.REFERENCE) then
				if (ContainsKey(a.value, _G.SCSVars)) then
					a = _G.SCSVars[a]
				elseif (ContainsKey(a.value, _G.SCSSVars)) then
					a = _G.SCSSVars[a]
				end
			end
			if (a.tType ~= ea) then
				return false
			end
		end
	end

	return true
end

function ConvertArg(arg: Token)					-- Converts SCS value to lua value
	if (arg.tType == TOKEN_TYPES.STRING) then
		return arg.value
	elseif (arg.tType == TOKEN_TYPES.NUMBER) then
		return tonumber(arg.value)
	elseif (arg.tType == TOKEN_TYPES.REFERENCE) then
		if (ContainsKey(arg.value, _G.SCSVars)) then
			return ConvertArg(_G.SCSVars[arg.value])
		elseif (ContainsKey(arg.value, _G.SCSSVars)) then
			return ConvertArg(_G.SCSSVars[arg.value])
		else
			Exceptions.ReferenceException:throw(
				string.format(
					"unknwon variable %s",
					arg.value
				)
			)
			return
		end
	end
end

function ConvertArgs(args)				-- Converts SCS values to lua values
	local a = {}
	for i = 1, #args, 1 do
		table.insert(a, ConvertArg(args[i]))
	end
	return a
end

function EvalChatCommand(command: string): nil			-- Evaluates given command
	local MethodToken = MakeReferenceToken(command, 1)
	if (IsValidMethod(MethodToken.value) ~= true) then
		Exceptions.SyntaxError:throw("unknown method "..MethodToken.value)
		return
	end
	local method = AvailableMethods[MethodToken.value]
	local position = #MethodToken.value + 1
	local args = {}
	local evalNextArg = true
	local arg
	while position < #command do
		position = position + 1
		while ContainsChar(command:sub(position, position), IGNORED_CHARS) do
			position = position + 1
		end
		if (evalNextArg) then
			arg = LiteralEval(command, position)
		else
			evalNextArg = true
		end
		if (arg == nil) then
			return
		end
		if (arg[1].tType == TOKEN_TYPES.SUBCALL) then
			EvalChatCommand(arg[1].value)
			arg = {ReturnStack[1], arg[1].pEnd - arg[1].pStart}
			evalNextArg = false
			if (arg == nil) then
				Exceptions.EvaluationException:throw("subcall returned nil. Try to replace it with static subcall")
				return
			end
			table.remove(ReturnStack, 1)
		elseif (arg[1].tType == TOKEN_TYPES.STATIC_SUBCALL) then
			EvalChatCommand(arg[1].value)
			position = position + arg[2]
			continue;
		end
		position = position + arg[2]
		if (arg[1] ~= nil) then
			table.insert(args, arg[1])
		else
			Exceptions.SyntaxError:throw("cannot evaluate literal at "..tostring(position))
		end
	end

	if (VerifyArgs(args, method.args) == true) then
		local callArgs = ConvertArgs(args)
		local ret = method.func(callArgs)
		table.insert(ReturnStack, 1, ret)
	else
		Exceptions.SyntaxError:throw("invalid arguments")
	end
end

-- SimpleScript API --

MethodDelegate = {}			-- Delegate of lua function to SCS

function MethodDelegate:new(nm: string, funct, arg, accessLvl: number)
	local _delegate =
		{
			name = nm,
			func = funct,
			args = arg,
			lvl = accessLvl
		}

	setmetatable(_delegate, MethodDelegate)
	self.__index = self
	return _delegate
end

function RegisterMethod(delegate: MethodDelegate): boolean	-- Registers given method in SCS
	if (IsValidMethod(delegate.name)) then
		return false
	else
		AvailableMethods[delegate.name] = delegate
		return true
	end
end

function SetVar(name: string, value: any)			-- Sets SCS variable value to given
	_G.SCSVars[name] = LuaEval(value)
end

function SetVarT(name: string, value: Token)		-- Sets SCS variable raw value to given
	_G.SCSVars[name] = value
end

function GetVar(name: string)						-- Returns SCS variable value by it's name
	if (not ContainsKey(name, _G.SCSVars)) then
		return nil
	end
	return ConvertArg(_G.SCSVars[name])
end

function GetVarT(name: string)						-- Returns SCS variable raw value by it's name
	if (not ContainsKey(name, _G.SCSVars)) then
		return nil
	end
	return _G.SCSVars[name]
end

function GetSVar(name: string)						-- Returns SCS server variable value by it's name
	if (not ContainsKey(name, _G.SCSSVars)) then
		return nil
	end
	return ConvertArg(_G.SCSSVars[name])
end

function GetSVarT(name: string)						-- Returns SCS server variable raw value by it's name
	if (not ContainsKey(name, _G.SCSSVars)) then
		return nil
	end
	return _G.SCSVars[name]
end

function SetSVar(name: string, value: any)			-- Sets SCS server variable value to given
	_G.SCSSVars[name] = LuaEval(value)
end

function SetSVarT(name: string, value: Token)		-- Sets SCS server variable raw value to given
	_G.SCSSVars[name] = value
end

function FlushReturnStack()
	ReturnStack = {}
end

function GetReturnStack()
	return ReturnStack
end

module =
	{
		LuaEval = LuaEval,
		EvaluateCommand = EvalChatCommand,
		MethodDelegate = MethodDelegate,
		RegisterMethod = RegisterMethod,
		SetVar = SetVar,
		SetVarT = SetVarT,
		SetSVar = SetSVar,
		SetSVarT = SetSVarT,
		GetVar = GetVar,
		GetVarT = GetVarT,
		GetSVar = GetSVar,
		GetSVarT = GetSVarT,
		ArgTypes = ARGUMENT_TYPES,
		MakeRef = MakeRef,
		FlushReturnStack = FlushReturnStack,
		GetReturnStack = GetReturnStack
	}

-- Builtins

-- Method functions --

function SCSOut(args)
	print(args[1])
end

function SCSVar(args)
	_G.SCSVars[args[1]] = LuaEval(args[2])
	return MakeRef(args[1])
end

function SCSSVar(args)
	_G.SCSSVars[args[1]] = LuaEval(args[2])
	return MakeRef(args[1])
end

-- Method delegates

local outDelegate = MethodDelegate:new(
	"out",
	SCSOut,
	{ARGUMENT_TYPES.ANY},
	0
)
local varDelegate = MethodDelegate:new(
	"var",
	SCSVar,
	{ARGUMENT_TYPES.STRING, ARGUMENT_TYPES.ANY},
	0
)
local svarDelegate = MethodDelegate:new(
	"svar",
	SCSSVar,
	{ARGUMENT_TYPES.STRING, ARGUMENT_TYPES.ANY},
	10
)

-- Method registration --

RegisterMethod(outDelegate)
RegisterMethod(varDelegate)
RegisterMethod(svarDelegate)

return module
