local lexer = require("./src/frontend/scanner/lexer") 
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
Output("input.lua")