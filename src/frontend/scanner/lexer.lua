local lexer = {};
function build(t)
	local n = {};
	for k, v in pairs(t) do
		n[v] = true;
	end;
	return n;
end;
lexer.operators = build({
	"+",
	"-",
	"*",
	"/",
	"^",
	"%",
	"==",
	"~=",
	"<=",
	">=",
	"<",
	">",
	"<<",
	">>",
	"#",
	"&",
	"~",
	"|",
	"..",
	"//",
	"="
});
lexer.syntax = build({
	"(",
	")",
	"{",
	"}",
	",",
	".",
	";",
	":"
});
lexer.delimiters = build({
	"'",
	"\"",
	"[[",
	"[=["
});
lexer.keywords = build({
	"break",
	"do",
	"else",
	"elseif",
	"end",
	"false",
	"for",
	"function",
	"if",
	"local",
	"nil",
	"repeat",
	"return",
	"then",
	"true",
	"until",
	"while",
	"not",
	"or",
	"and",
	"true",
	"false",
	"nil"
});
function getchars(input, size, pos)
	return input:sub(pos, pos + size - 1);
end;
function search(input, tab, pos)
	local i = pos;
	for k, _ in pairs(tab) do
		local len = #k;
		local char = getchars(input, len, i);
		if char == k then
			return char;
		end;
	end;
	return nil;
end;
function lexer.tokenize(input)
	local tokens = {};
	local i = 1;
	while i <= (#input) do
		local char = input:sub(i, i);
		if char == " " then
			i = i + 1;
		elseif getchars(input, 4, i) == "--[[" then
			local comment = "";
			i = i + 4;
			while getchars(input, 4, i) ~= "--]]" and getchars(input, 2, i) ~= "]]" and i <= (#input) do
				comment = comment .. input:sub(i, i);
				i = i + 1;
			end;
			local ending;
			if getchars(input, 4, i) == "--]]" then
				i = i + 4;
				ending = "--]]";
			elseif getchars(input, 2, i) == "]]" then
				i = i + 2;
				ending = "]]";
			end;
			table.insert(tokens, {
				type = "comment",
				value = comment,
				raw = "--[[" .. comment .. ending
			});
		elseif getchars(input, 2, i) == "--" then
			local comment = "";
			i = i + 2;
			while input:sub(i, i) ~= "\n" and i <= (#input) do
				comment = comment .. input:sub(i, i);
				i = i + 1;
			end;
			table.insert(tokens, {
				type = "comment",
				value = comment,
				raw = "--" .. comment
			});
		elseif lexer.delimiters[getchars(input, 3, i)] or lexer.delimiters[getchars(input, 2, i)] or lexer.delimiters[char] then
			local delimiter = lexer.delimiters[getchars(input, 3, i)] and getchars(input, 3, i) or (lexer.delimiters[getchars(input, 2, i)] and getchars(input, 2, i) or char);
			local str = "";
			local count = #delimiter;
			i = i + count;
			local end_delim = delimiter == "[=[" and "]=]" or (delimiter == "[[" and "]]" or delimiter);
			while i <= (#input) do
				if getchars(input, #end_delim, i) == end_delim then
					i = i + (#end_delim);
					break;
				end;
				str = str .. getchars(input, 1, i);
				i = i + 1;
			end;
			table.insert(tokens, {
				type = "string",
				value = tostring(str),
				raw = delimiter .. str .. end_delim
			});
		elseif lexer.operators[getchars(input, 2, i)] or lexer.operators[char] then
			local operator = lexer.operators[getchars(input, 2, i)] and getchars(input, 2, i) or char;
			table.insert(tokens, {
				type = "operator",
				value = operator,
				raw = operator
			});
			i = i + (#operator);
		elseif (getchars(input, 2, i)):match("^0[xX]") then
			local hex = getchars(input, 2, i);
			i = i + 2;
			local has_dot = false;
			local has_exponent = false;
			while (getchars(input, 1, i)):match("[0-9a-fA-F]") or not has_dot and getchars(input, 1, i) == "." do
				if getchars(input, 1, i) == "." then
					has_dot = true;
				end;
				hex = hex .. getchars(input, 1, i);
				i = i + 1;
			end;
			if (getchars(input, 1, i)):lower() == "p" then
				hex = hex .. "p";
				has_exponent = true;
				i = i + 1;
				if (getchars(input, 1, i)):match("[%+%-]") then
					hex = hex .. getchars(input, 1, i);
					i = i + 1;
				end;
				while (getchars(input, 1, i)):match("%d") do
					hex = hex .. getchars(input, 1, i);
					i = i + 1;
				end;
			end;
			if has_exponent then
				table.insert(tokens, {
					type = "float",
					value = hex,
					raw = hex
				});
			else
				table.insert(tokens, {
					type = "hexadecimal",
					value = tonumber(hex, 16),
					raw = hex
				});
			end;
		elseif char:match("[a-zA-Z_][a-zA-Z0-9_]*") then
			local identifier = "";
			while i <= (#input) and (getchars(input, 1, i)):match("^([_a-zA-Z][_a-zA-Z0-9]*)") or (getchars(input, 1, i)):match("%d") do
				identifier = identifier .. getchars(input, 1, i);
				i = i + 1;
			end;
			table.insert(tokens, {
				type = "identifier",
				value = identifier,
				raw = identifier
			});
		elseif char:match("[%d%-]") then
			local number = "";
			if char == "-" then
				number = "-";
				i = i + 1;
				char = getchars(input, 1, i);
			end;
			local float = false;
			local scientific = false;
			while char:match("[%d%.eE%+%-]") do
				if char == "." then
					if float then
						break;
					end;
					float = true;
				elseif char:lower() == "e" then
					if scientific then
						break;
					end;
					scientific = true;
					float = true;
				elseif char == "+" or char == "-" then
					local prev_char = number:sub(-1);
					if prev_char:lower() ~= "e" then
						break;
					end;
				end;
				number = number .. char;
				i = i + 1;
				char = getchars(input, 1, i);
			end;
			if scientific and (number:sub(-1)):lower() == "e" then
				number = number .. "0";
			end;
			table.insert(tokens, {
				type = float and "float" or "integer",
				value = tonumber(number),
				raw = number
			});
		elseif lexer.keywords[search(input, lexer.keywords, i)] then
			local keyword = search(input, lexer.keywords, i);
			table.insert(tokens, {
				type = "keyword",
				value = keyword,
				raw = keyword
			});
			i = i + (#keyword);
		elseif lexer.syntax[getchars(input, 1, i)] then
			local syntax = getchars(input, 1, i);
			table.insert(tokens, {
				type = "syntax",
				value = syntax,
				raw = syntax
			});
			i = i + (#syntax);
		else
			i = i + 1;
		end;
	end;
	return tokens;
end;
function Output(path)
	local f = io.open(path);
	local src = f:read("*all");
	f:close();
	for _, v in pairs(lexer.tokenize(src)) do
		print(string.format("Type: %s; Value: %s; Raw: %s;", tostring(v.type), tostring(v.value), tostring(v.raw)));
	end;
	print("------------------------------------------------------------------");
	local json = require("json");
	print(json.encode(lexer.tokenize(src)));
end;
return lexer, Output;
