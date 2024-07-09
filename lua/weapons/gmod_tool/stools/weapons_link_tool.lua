TOOL.AddToMenu = false
TOOL.Category = "Weapons"
TOOL.Name	= "Weapon Link Tool"
--TOOL.Topic["name"] = "Weapon Link Tool"
--TOOL.Topic["desc"] = "Link weapons to be controlled by wire from apple Core"
--TOOL.Topic[0] = "LeftClick: Select weapons. RightClick: Link to apple core. Reload: Cancel link (on apple core: Remove all links)."

local ent_table = {}



function TOOL:LeftClick( trace )
	if (!trace.Entity:IsValid()) or (trace.Entity:IsPlayer()) then return end
		if (trace.Entity:GetClass() == "sg_turret_destmain") or(trace.Entity:GetClass() == "sg_turret_destmed") or (trace.Entity:GetClass() == "sg_turret_destsmall")
		or (trace.Entity:GetClass() == "sg_turret_shiprail") or (trace.Entity:GetClass() == "sg_turret_tollan") or (trace.Entity:GetClass() == "asgard_beam")
		or (trace.Entity:GetClass() == "ori_beam_cannon") or (trace.Entity:GetClass() == "vanir_plasma_cannon") or (trace.Entity:GetClass() == "wraith_plasma_cannon") then
		local In, Out = WireLib.GetPorts(trace.Entity)
		trace.Entity:SetColor(Color(100,255,255,255))
		table.insert(ent_table, 1, trace.Entity)
		
		return true
	else
		return
	end
end


function TOOL:RightClick( trace )
	if (!trace.Entity:IsValid()) or (!trace.Entity:GetClass() == "apple_core") then return end

	if (table.IsEmpty(ent_table)) then return end

	for k,v in pairs(ent_table) do
		table.insert(trace.Entity.Weapons, 1, v)
	end
	trace.Entity:CountWeaps()

	for k,v in pairs(ent_table) do
		v:SetColor(Color(255,255,255,255))
	end
	ent_table = {}
end


function TOOL:Reload(trace)

	if(trace.Entity:GetClass() == "apple_core") then
		trace.Entity:ClearWeaps()
		return
	end



	if (table.IsEmpty(ent_table)) then return end
	for k,v in pairs(ent_table) do
		v:SetColor(Color(255,255,255,255))
	end
	ent_table = {}
end

--TOOL:Register();