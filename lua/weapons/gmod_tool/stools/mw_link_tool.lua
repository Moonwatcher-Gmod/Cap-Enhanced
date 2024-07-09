TOOL.AddToMenu = false
TOOL.Name		= "MW Link Tool"







function TOOL:Initialize()

self.Receiver = nil



end

function TOOL:LeftClick( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	if (CLIENT) then return true end
	
	self.Receiver = trace.Entity

	return true
end


function TOOL:RightClick( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	
	if (CLIENT) then return true end
	
	self.Receiver.Provider = trace.Entity

	self.Receiver = nil

	return true
end

function TOOL:Reload( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
	if (CLIENT) then return true end
	
	trace.Entity.Provider = nil

	return true
end




