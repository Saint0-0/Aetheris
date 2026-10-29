--[[
	Aetheris/Utils/SyntaxHighlight.luau

	Lexes Luau, JavaScript, Python and JSON into colour classes and renders
	them as escaped RichText for CodeView. Colours come from the caller's
	palette, so the same classes can be re-tinted per theme without changing
	their meaning.

	License: MPL-2.0 - https://mozilla.org/MPL/2.0/
	Copyright (c) 2026 Saint0-0
]]

local SyntaxHighlight = {}

type Token = { class: string, text: string }

-- Language rules; the lexer is a single ordered scan through these.
local LANGS: { [string]: any } = {
	lua = {
		lineComments = { "--" },
		blockComments = { { "--[[", "]]" }, { "--[=[", "=]" } },
		quotes = { { '"', '"', true }, { "'", "'", true }, { "`", "`", true } },
		longString = true,
		keywords = {
			"and",
			"break",
			"continue",
			"do",
			"else",
			"elseif",
			"end",
			"export",
			"for",
			"function",
			"if",
			"in",
			"local",
			"not",
			"or",
			"repeat",
			"return",
			"then",
			"type",
			"until",
			"while",
		},
		constants = { "false", "nil", "true" },
		builtins = {
			"assert",
			"bit32",
			"collectgarbage",
			"coroutine",
			"debug",
			"delay",
			"error",
			"game",
			"getmetatable",
			"ipairs",
			"math",
			"next",
			"os",
			"pairs",
			"pcall",
			"print",
			"rawequal",
			"rawget",
			"rawlen",
			"rawset",
			"require",
			"script",
			"select",
			"setmetatable",
			"string",
			"table",
			"task",
			"tick",
			"time",
			"tonumber",
			"tostring",
			"typeof",
			"unpack",
			"utf8",
			"warn",
			"workspace",
			"BrickColor",
			"CFrame",
			"Color3",
			"ColorSequence",
			"Enum",
			"Faces",
			"Axes",
			"Instance",
			"NumberRange",
			"NumberSequence",
			"Random",
			"Ray",
			"RaycastParams",
			"OverlapParams",
			"Rect",
			"Region3",
			"TweenInfo",
			"UDim",
			"UDim2",
			"Vector2",
			"Vector3",
		},
		operators = "+-*/%^#=~<>&|:#",
	},
	javascript = {
		lineComments = { "//" },
		blockComments = { { "/*", "*/" } },
		quotes = { { '"', '"', true }, { "'", "'", true }, { "`", "`", true } },
		keywords = {
			"async",
			"await",
			"break",
			"case",
			"catch",
			"class",
			"const",
			"continue",
			"debugger",
			"default",
			"delete",
			"do",
			"else",
			"export",
			"extends",
			"finally",
			"for",
			"function",
			"if",
			"import",
			"in",
			"instanceof",
			"let",
			"new",
			"return",
			"static",
			"super",
			"switch",
			"this",
			"throw",
			"try",
			"typeof",
			"var",
			"void",
			"while",
			"with",
			"yield",
			"of",
		},
		constants = { "false", "Infinity", "NaN", "null", "true", "undefined" },
		builtins = {
			"Array",
			"Boolean",
			"Date",
			"Error",
			"JSON",
			"Map",
			"Math",
			"Number",
			"Object",
			"Promise",
			"RegExp",
			"Set",
			"String",
			"Symbol",
			"console",
			"document",
			"exports",
			"fetch",
			"globalThis",
			"module",
			"process",
			"require",
			"setInterval",
			"setTimeout",
			"parseFloat",
			"parseInt",
			"isNaN",
			"window",
		},
		operators = "+-*/%=~<>&|!?",
	},
	python = {
		lineComments = { "#" },
		blockComments = {},
		quotes = { { '"', '"', true }, { "'", "'", true } },
		triple = true,
		stringPrefixes = { "f", "r", "b", "u", "rf", "rb", "fr", "br", "F", "R", "B", "U" },
		keywords = {
			"and",
			"as",
			"assert",
			"async",
			"await",
			"break",
			"case",
			"class",
			"continue",
			"def",
			"del",
			"elif",
			"else",
			"except",
			"finally",
			"for",
			"from",
			"global",
			"if",
			"import",
			"in",
			"is",
			"lambda",
			"match",
			"nonlocal",
			"not",
			"or",
			"pass",
			"raise",
			"return",
			"try",
			"while",
			"with",
			"yield",
		},
		constants = { "False", "None", "True" },
		builtins = {
			"abs",
			"all",
			"any",
			"bytearray",
			"bytes",
			"callable",
			"classmethod",
			"dict",
			"dir",
			"enumerate",
			"filter",
			"float",
			"format",
			"frozenset",
			"getattr",
			"globals",
			"hasattr",
			"hash",
			"id",
			"input",
			"int",
			"isinstance",
			"issubclass",
			"iter",
			"len",
			"list",
			"locals",
			"map",
			"max",
			"min",
			"next",
			"object",
			"open",
			"pow",
			"print",
			"property",
			"range",
			"repr",
			"reversed",
			"round",
			"set",
			"setattr",
			"sorted",
			"staticmethod",
			"str",
			"sum",
			"super",
			"tuple",
			"type",
			"vars",
			"zip",
			"self",
			"cls",
			"Exception",
			"IndexError",
			"KeyError",
			"RuntimeError",
			"StopIteration",
			"TypeError",
			"ValueError",
		},
		operators = "+-*/%=~<>&|^@!",
	},
	json = {
		lineComments = {},
		blockComments = {},
		quotes = { { '"', '"', true } },
		stringKeys = true, -- a quoted run followed by ':' is an object key
		keywords = {},
		constants = { "true", "false", "null" },
		builtins = {},
		operators = "-",
	},
}

local PUNCT = {
	["("] = true,
	[")"] = true,
	["["] = true,
	["]"] = true,
	["{"] = true,
	["}"] = true,
	[","] = true,
	[";"] = true,
	[":"] = true,
}

local compiled: { [string]: any } = {}

local function toSet(list): { [string]: boolean }
	local set = {}
	for _, v in ipairs(list) do
		set[v] = true
	end
	return set
end

-- Unknown languages fall back to Lua rules.
local function compile(language: string?)
	local key = if LANGS[language :: string] then language :: string else "lua"
	local cached = compiled[key]
	if cached then
		return cached
	end
	local cfg = LANGS[key]
	local built = {
		lineComments = cfg.lineComments or {},
		blockComments = cfg.blockComments or {},
		quotes = cfg.quotes or {},
		longString = cfg.longString == true,
		triple = cfg.triple == true,
		stringKeys = cfg.stringKeys == true,
		stringPrefixes = cfg.stringPrefixes and toSet(cfg.stringPrefixes) or nil,
		keywords = toSet(cfg.keywords or {}),
		constants = toSet(cfg.constants or {}),
		builtins = toSet(cfg.builtins or {}),
		operators = cfg.operators or "+-*/%=~<>&|",
	}
	compiled[key] = built
	return built
end

local function lex(code: string, cfg: any): { Token }
	local tokens: { Token } = {}
	local n = #code
	local i = 1

	local function push(class: string, text: string)
		if text == "" then
			return
		end
		local last = tokens[#tokens]
		if last and last.class == class then
			last.text ..= text
		else
			tokens[#tokens + 1] = { class = class, text = text }
		end
	end

	local function at(pos: number, prefix: string): boolean
		return string.sub(code, pos, pos + #prefix - 1) == prefix
	end

	while i <= n do
		local c = string.sub(code, i, i)
		local matched = false

		-- Block comments first: for Lua "--[[" must win over the "--" line rule.
		for _, blk in ipairs(cfg.blockComments) do
			if at(i, blk[1]) then
				local closeAt = string.find(code, blk[2], i + #blk[1], true)
				local stop = if closeAt then closeAt + #blk[2] - 1 else n
				push("comment", string.sub(code, i, stop))
				i = stop + 1
				matched = true
				break
			end
		end
		if matched then
			continue
		end

		for _, lc in ipairs(cfg.lineComments) do
			if at(i, lc) then
				local nl = string.find(code, "\n", i, true)
				local stop = if nl then nl - 1 else n
				push("comment", string.sub(code, i, stop))
				i = stop + 1
				matched = true
				break
			end
		end
		if matched then
			continue
		end

		-- Lua long strings: [[...]] and [=[...]=] with matching '=' counts.
		if cfg.longString and c == "[" then
			local p = i + 1
			local eqCount = 0
			while p <= n and string.sub(code, p, p) == "=" do
				eqCount += 1
				p += 1
			end
			if p <= n and string.sub(code, p, p) == "[" then
				local closePat = "]" .. string.rep("=", eqCount) .. "]"
				local closeAt = string.find(code, closePat, p + 1, true)
				local stop = if closeAt then closeAt + #closePat - 1 else n
				push("string", string.sub(code, i, stop))
				i = stop + 1
				matched = true
			end
		end
		if matched then
			continue
		end

		-- Quoted strings (python triples handled via cfg.triple).
		for _, q in ipairs(cfg.quotes) do
			if c == q[1] then
				local open = q[1]
				if cfg.triple and at(i, string.rep(open, 3)) then
					open = string.rep(open, 3)
				end
				local p = i + #open
				local stop = nil
				while p <= n do
					local ch = string.sub(code, p, p)
					if q[3] and ch == "\\" then
						p += 2
					elseif at(p, open) then
						stop = p + #open - 1
						break
					else
						p += 1
					end
				end
				local finalStop = if stop then stop else n
				-- JSON: a string followed by ':' is an object key, not a value.
				local class = "string"
				if cfg.stringKeys then
					local scan = finalStop + 1
					while scan <= n and string.find(" \t\n\r", string.sub(code, scan, scan), 1, true) do
						scan += 1
					end
					if string.sub(code, scan, scan) == ":" then
						class = "key"
					end
				end
				push(class, string.sub(code, i, finalStop))
				i = finalStop + 1
				matched = true
				break
			end
		end
		if matched then
			continue
		end

		if string.match(c, "[%a_]") then
			local p = i
			while p <= n and string.match(string.sub(code, p, p), "[%w_]") do
				p += 1
			end
			local ident = string.sub(code, i, p - 1)
			local identLen = #ident
			local nextChar = string.sub(code, i + identLen, i + identLen)

			-- Python string prefixes (f"", r"", ...) colour as the string itself.
			if cfg.stringPrefixes and cfg.stringPrefixes[ident] and string.find(nextChar, "[\"']") then
				push("string", ident)
				i += identLen
				continue
			end

			if cfg.keywords[ident] then
				push("keyword", ident)
			elseif cfg.constants[ident] then
				push("constant", ident)
			elseif cfg.builtins[ident] then
				push("builtin", ident)
			elseif nextChar == "(" then
				push("func", ident)
			elseif string.match(ident, "^[A-Z]") then
				push("type", ident)
			else
				push("plain", ident)
			end
			i += identLen
			continue
		end

		-- Numbers: hex/binary/decimals, exponents, no ".." run-on.
		if string.match(c, "%d") or (c == "." and string.match(string.sub(code, i + 1, i + 1), "%d")) then
			local p = i
			local prev = ""
			while p <= n do
				local ch = string.sub(code, p, p)
				local isWord = string.match(ch, "[%w_]") ~= nil
				-- '.' only continues a number when the next char isn't another '.' (Lua's "..").
				local isDot = ch == "." and string.sub(code, p + 1, p + 1) ~= "."
				local isExpSign = (ch == "+" or ch == "-") and (prev == "e" or prev == "E")
				if isWord or isDot or isExpSign then
					prev = ch
					p += 1
				else
					break
				end
			end
			push("number", string.sub(code, i, p - 1))
			i = p
			continue
		end

		-- Lua concat before the generic operator run so ".." stays one token.
		if c == "." and at(i, "...") then
			push("operator", "...")
			i += 3
			continue
		elseif c == "." and at(i, "..") then
			push("operator", "..")
			i += 2
			continue
		elseif string.find(cfg.operators, c, 1, true) then
			local p = i
			while p <= n and string.find(cfg.operators, string.sub(code, p, p), 1, true) do
				p += 1
			end
			push("operator", string.sub(code, i, p - 1))
			i = p
			continue
		end

		if PUNCT[c] then
			push("punct", c)
			i += 1
			continue
		end

		push("plain", c)
		i += 1
	end

	return tokens
end

local function escapeRich(text: string): string
	text = string.gsub(text, "&", "&amp;")
	text = string.gsub(text, "<", "&lt;")
	text = string.gsub(text, ">", "&gt;")
	return text
end

local function colorHex(c): string
	return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

-- Exposed for tests and debugging; Render is the production path.
function SyntaxHighlight.Tokenize(code: string?, language: string?): { Token }
	return lex(if type(code) == "string" then code else "", compile(language))
end

-- Every font span is closed before a line break, so callers can split on "\n" safely.
function SyntaxHighlight.Render(code: string?, language: string?, palette: { [string]: any }?): string
	local tokens = lex(if type(code) == "string" then code else "", compile(language))
	local parts = {}
	for _, token in ipairs(tokens) do
		local color = palette and palette[token.class]
		local text = escapeRich(token.text)
		if not color then
			table.insert(parts, text)
		else
			local hex = colorHex(color)
			local first = true
			for _, piece in ipairs(string.split(text, "\n")) do
				if not first then
					table.insert(parts, "\n")
				end
				if piece ~= "" then
					table.insert(parts, '<font color="' .. hex .. '">' .. piece .. "</font>")
				end
				first = false
			end
		end
	end
	return table.concat(parts)
end

return SyntaxHighlight
