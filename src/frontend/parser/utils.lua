local function scan(Chunk, type, callback)
	for k, v in pairs(Chunk) do
		local currentChunk = Chunk[i];
		if type(currentChunk) ~= "table" or currentChunk == nil then
			return;
		end;
		if currentChunk.type and currentChunk.type == type then
			callback(currentChunk);
		end;
		scan(currentChunk, type, callback);
	end;
end;
