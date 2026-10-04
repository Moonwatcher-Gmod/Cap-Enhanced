--[[
	Shield Core impact ripple
	Hands the hit to the shield, which draws an expanding ring along its surface
	(ENT:AddRipple / ENT:DrawRipples in entities/shield_core_buble/cl_init.lua).
]]--

function EFFECT:Init(data)
	local shield = data:GetEntity();
	if (IsValid(shield) and shield.AddRipple) then
		shield:AddRipple(data:GetOrigin(), data:GetScale());
	end
end

function EFFECT:Think()
	return false;
end

function EFFECT:Render()
end
