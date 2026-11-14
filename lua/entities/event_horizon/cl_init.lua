include("shared.lua");
include("modules/bullets.lua");
include("modules/collision.lua");

ENT.RenderGroup = RENDERGROUP_BOTH -- This FUCKING THING avoids the clipping bug I have had for ages since stargate BETA 1.0. DAMN!
if (SGLanguage and SGLanguage.GetMessage) then
	ENT.PrintName = SGLanguage.GetMessage("event_horizon");
	language.Add("event_horizon",SGLanguage.GetMessage("event_horizon"))
end

if(file.Exists("materials/VGUI/weapons/event_horizon_killicon.vmt","GAME")) then
	killicon.Add("event_horizon","VGUI/weapons/event_horizon_killicon",Color(255,255,255));
end

function ENT:Initialize()
	net.Receive("supergate_sounds"..self:EntIndex(),function(len)
		local SndPath = "sound/"..net.ReadString()

		sound.PlayFile(SndPath,"3d mono",function(snd,ercode,erstr)
			if (erstr) then print("[CAP] Supergate sound failed: " .. erstr) end
			if(IsValid(snd)) then
				snd:Set3DFadeDistance(10000,33000)
				snd:SetPos(self:GetPos())
				snd:SetVolume(2.5)
				snd:Set3DEnabled(true)
				snd:Play()
			end
		end)
	end)
end

--################# Think @aVoN
function ENT:Think()
	--###### Update the clientside self.Target (Necessary for the ENT:GetTeleportedVector function, if used clientside)
	self.Target = self.Entity:GetNWEntity("Target",self.Entity);
	--###### Clientside lights, yeah! Can be toggled by clients this causes much less lag when deactivated. Method below is from Catdaemon's harvester
	if(not StarGate.VisualsMisc("cl_stargate_dynlights")) then return end;
	if(not self.Entity:GetNWBool("activate_lights",false)) then return end;
	self.Brightness = math.Clamp((self.Brightness or 0) + FrameTime()*10,0,1); -- Make the light fade in!
	if((self.NextLight or 0) < CurTime()) then -- Fixes a crashing bug, which spawns more and more lights all over the time until the clientside "overflowed blubb" message appears
		self.NextLight = CurTime()+0.001;
		local dlight = DynamicLight(self:EntIndex());
		if(dlight) then
			dlight.Pos = self.Entity:GetPos()+self.Entity:GetForward()*50;
			if (self.Entity:GetNWBool("LightCustom",false)) then
				local col = self.Entity:GetColor() --GetNWVector("LightColor")
				dlight.r = col.r*0.3
				dlight.g = col.g*0.3
				dlight.b = col.b*0.3
			elseif (self.Entity:GetNWBool("LightSync",false)) then
				local r = self.Entity:GetNWVector("LightColR")
				local rand = math.random(r[1],r[2]);
				dlight.r = rand;
				dlight.g = rand;
				dlight.b = rand;
			else
				local r,g,b = self.Entity:GetNWVector("LightColR"),self.Entity:GetNWVector("LightColG"),self.Entity:GetNWVector("LightColB")
				dlight.r = math.random(r[1],r[2]);
				dlight.g = math.random(g[1],g[2]);
				dlight.b = math.random(b[1],b[2]);
			end
			dlight.Brightness = self.Brightness;
			dlight.Decay = math.random(300,350);
			dlight.Size = math.random(700,750);
			dlight.DieTime = CurTime()+1;
		end
	end
end

--################# Draw (for the EH being translucent from behind) @aVoN
function ENT:Draw()
	self.BaseClass.Draw(self);
	local alpha = self.Entity:GetColor().a;
	--if((LocalPlayer():GetShootPos()-self.Entity:GetPos()):DotProduct(self.Entity:GetForward()) < 0) then -- Behind
	if ((EyePos()-self.Entity:GetPos()):DotProduct(self.Entity:GetForward()) < 0) then
		alpha = math.Clamp(alpha,1,150);
		-- We are looking from behind on the gate
	elseif(alpha == 150) then
		alpha = 255;
	end
	self.MaxAlpha = alpha;
	local color = self.Entity:GetColor()
	-- Just set the alpha if we aren't initializing it, or it will look ugly from behind
	if (not self.AllowBacksideDrawing) then
		if (self:GetNWBool("AllowBacksideDrawing",false)) then
			color.a = 255
			self.Entity:SetColor(color); -- fix for invisible eh
		end
		self.AllowBacksideDrawing = self:GetNWBool("AllowBacksideDrawing",false);
	end
	if(self.AllowBacksideDrawing) then -- This is getting set by the "eventhorizon_stabilize" effect
		color.a = alpha --math.Clamp(alpha,0,color.a)
		self.Entity:SetColor(color);
	end
end

--################# Sets the alpha of the gate and  @aVoN
function ENT:SetAlpha(alpha,min)
	local col = self:GetColor()
	if(min) then
		self.Entity:SetColor(Color(col.r,col.g,col.b,math.Clamp(alpha or 1,self.MaxAlpha or 1,255)));
	else
		self.Entity:SetColor(Color(col.r,col.g,col.b,math.Clamp(alpha or 1,1,self.MaxAlpha or 255)));
	end
end


--################# Draw teleport effect when entering/exiting the gate (somewhat inspired from catdaemon's Rings, LOL) @aVoN & Catdaemon

local started; -- When did we started the effect?
--################# FOV changing @aVoN
hook.Add("CalcView","StarGate.CalcView.TeleportEffect",
	function(p,pos,ang,fov)
		if(not started) then return end;
		local time = CurTime()-started;
		local mul = 1+math.cos(math.Clamp(time,0,1)*2*math.pi)*0.2; -- Will do the job in 1/4 second
		if(mul < 1 or time > 0.25) then
			started = nil;
			return;
		end
		local t = {
			origin = pos,
			angles = ang,
			fov=fov*mul,
		}
		return t;
	end
);

--################# White flash @aVoN
--local Material1 = StarGate.MaterialCopy("StargateEnterBlur","bluredges");
--local Material2 = StarGate.MaterialCopy("StargateEnterFizzle","effects/tp_eyefx/tpeye3");
hook.Add("HUDPaint","StarGate.HUDPaint.TeleportEffect",
	function()
		if(not started) then return end;
		local time = CurTime()-started;
		local mul = math.cos(math.Clamp(time,0,1)*2*math.pi); -- Will do the job in 1/4 second
		if(mul < 0 or time > 0.25) then
			started = nil;
			return;
		end
		surface.SetDrawColor(255,255,255,mul*255);
		surface.DrawRect(0,0,ScrW(),ScrH());
	end
);

--################# Start the FOV changed @aVoN
usermessage.Hook("StarGate.CalcView.TeleportEffectStart",
	function()
		started = CurTime();
	end
);


--########### All this handle's model clipping @RononDex
usermessage.Hook("StarGate.EventHorizon.ClipStart", function(um)
	local dir = um:ReadShort();
	local e = um:ReadEntity();
	local target = um:ReadEntity();
	if(not(IsValid(e) and IsValid(target))) then return end;
	local norm = target:GetForward()*dir;
	e.dir = dir;
	e:SetRenderClipPlaneEnabled(true);
	e:SetRenderClipPlane(norm, norm:Dot(target:GetPos()));
end)

usermessage.Hook( "StarGate.EventHorizon.ClipStop", function(um)
	local e = um:ReadEntity();
	if(not(IsValid(e))) then return end;
	e.dir = nil;
	e:SetRenderClipPlaneEnabled(false);
end)

usermessage.Hook( "StarGate.EventHorizon.PlayerKill", function(um)
	local e = um:ReadEntity();
	if(not(IsValid(e))) then return end;
	GAMEMODE:AddDeathNotice("#event_horizon",-1,"event_horizon",e:Name(),e:Team());
end)

local mat_Overlay = {}
local mats = {"effects/tp_eyefx/3tpeyefx_.vtf","effects/tp_eyefx/2tpeyefx_.vtf","effects/tp_eyefx/tpeyefx_.vtf"}

usermessage.Hook( "StarGate.EventHorizon.SecretStart", function(um)
	started = CurTime();
	local e = LocalPlayer();
	e:EmitSound( "stargate/travel.mp3" )
	local rnd = math.random(1,3);
	hook.Add("EntityEmitSound","Stargate.EH.Secret",function() return false end)
	hook.Add("PlayerBindPress","Stargate.EH.Secret",function() return true end)
	--timer.Create("Stargate.EH.Secret",0.1,1,function()
	hook.Add("PostRender","Stargate.EH.Secret",function()
		if ( mat_Overlay[rnd] == nil ) then
			--mat_Overlay = Material( "effects/tp_eyefx/tpeye3" )
			mat_Overlay[rnd] = StarGate.MaterialFromVMT(
				"SGTeleportSecret"..rnd,
				[["UnLitGeneric"
				{
					"$basetexture"		]]..mats[rnd]..[[
					"$nocull" 1
					"$additive"0
					"$vertexalpha" 1
					"$vertexcolor" 1
					"Proxies"
					{
						"AnimatedTexture"
						{
							"animatedtexturevar" "$basetexture"
							"animatedtextureframenumvar" "$frame"
							"animatedtextureframerate" 23
						}
					}
				}]]
			);
		end

		if ( mat_Overlay[rnd] == nil ) then return end

		render.UpdateScreenEffectTexture()

		render.SetMaterial( mat_Overlay[rnd] )
		render.DrawScreenQuad()
		return true;
	end)
	--end)
end)

usermessage.Hook( "StarGate.EventHorizon.SecretReset", function(um)
	local e = LocalPlayer();
	hook.Remove("PostRender","Stargate.EH.Secret");
	hook.Remove("EntityEmitSound","Stargate.EH.Secret");
	hook.Remove("PlayerBindPress","Stargate.EH.Secret");
	hook.Remove("RenderScreenspaceEffects","Stargate.EH.Secret");
	e.SGSecretEffect = false;
	started = CurTime();
end)

usermessage.Hook( "StarGate.EventHorizon.SecretOut", function(um)
	local e = LocalPlayer();
	hook.Remove("PostRender","Stargate.EH.Secret");
	hook.Remove("EntityEmitSound","Stargate.EH.Secret");
	hook.Remove("PlayerBindPress","Stargate.EH.Secret");
	started = CurTime();

	local rnd = math.random(1,10);

	if (e.SGSecretEffect) then
		hook.Remove("RenderScreenspaceEffects","Stargate.EH.Secret");
		e.SGSecretEffect = false;
	else
		e.SGSecretEffect = true;

		hook.Add( "RenderScreenspaceEffects", "Stargate.EH.Secret", function()
			if (rnd==1) then
				DrawSharpen(5,5.2)
			elseif (rnd==2) then
				DrawSharpen(5,5.2)
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
			elseif (rnd==3) then
				DrawSharpen(5,5.2)
				DrawTexturize(0.05, Material("none_mat_lol") ) -- haha black purple world :D
			elseif (rnd==4) then
				DrawSharpen(5,5.2)
				DrawMaterialOverlay("effects/strider_pinch_dudv",0.1)
			elseif (rnd==5) then
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
				DrawSobel(0.11)
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
			elseif (rnd==6) then
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
				DrawMaterialOverlay("effects/water_warp01",0.15)
			elseif (rnd==7) then
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
				DrawTexturize(1, Material("pp/texturize/pattern1.png") )
			elseif (rnd==8) then
				DrawTexturize(1, Material("pp/texturize/rainbow.png") )
				DrawMaterialOverlay("models/props_lab/tank_glass001",-0.1)
			elseif (rnd==9) then
				DrawTexturize(1, Material("pp/texturize/pattern1.png") )
				DrawMaterialOverlay("models/props_lab/tank_glass001",0.1)
			elseif (rnd==10) then
				DrawTexturize(1, Material("pp/texturize/lines.png") )
				DrawSharpen(2,5.2)
			end
			return true
		end)
	end
end)
-- Wormhole travel screen. The server sends WormHoleStart with a bool: true = Atlantis transition.
-- The animated textures are drawn through proxy-free copies of their materials, so we pick the
-- frame ourselves and every trip starts from the first frame (the .vmt proxies loop on the game clock).
local WORMHOLE_STYLES = {
	classic = {
		Texture = "williamdefly/wormhole",
		Sound = "stargate/travelnew.mp3",
		FPS = 30, -- Same rate as the .vmt
		Loop = true,
	},
	atlantis = {
		-- 150 frames at 30 fps = 5.0s, matches WORMHOLE_TRANSIT_TIME_ATLANTIS in init.lua
		Texture = "williamdefly/wormhole_atlantis",
		Sound = "stargate/wormhole_atlantis.mp3",
		FPS = 30,
		Loop = false, -- Hold the last (white) frame if a trip takes longer (e.g. routing paused)
	},
}

for name,style in pairs(WORMHOLE_STYLES) do
	style.Material = CreateMaterial("CAP_WormholeTravel_"..name,"UnlitGeneric",{
		["$basetexture"] = style.Texture,
	})
	local tex = style.Material:GetTexture("$basetexture")
	style.Frames = math.max(1, tex and tex:GetNumAnimationFrames() or 1)
	util.PrecacheSound(style.Sound)
end

local wormhole_style = WORMHOLE_STYLES.classic
local wormhole_start = 0

local function StopWormholeScreen()
	LocalPlayer():StopSound(wormhole_style.Sound)
	hook.Remove("HUDDrawScoreBoard", "Wormholeefffect")
	hook.Remove("EntityEmitSound","Lib.EH.WormHole");
	hook.Remove("PlayerBindPress","Lib.EH.WormHole");
end

usermessage.Hook( "Lib.EventHorizon.WormHoleStart", function(um)
	StopWormholeScreen() -- In case a previous trip's screen is still up
	wormhole_style = um:ReadBool() and WORMHOLE_STYLES.atlantis or WORMHOLE_STYLES.classic
	wormhole_start = RealTime() -- Restart the animation for this trip
	-- Started before the hook below, which mutes every other sound during the trip
	LocalPlayer():EmitSound(wormhole_style.Sound)
	hook.Add("EntityEmitSound","Lib.EH.WormHole",function() return false end)
	hook.Add("PlayerBindPress","Lib.EH.WormHole",function() return true end)
	hook.Add( "HUDDrawScoreBoard", "Wormholeefffect", function()
		local style = wormhole_style
		local frame = math.floor((RealTime() - wormhole_start) * style.FPS)
		if (style.Loop) then
			frame = frame % style.Frames
		else
			frame = math.min(frame, style.Frames - 1)
		end
		style.Material:SetInt("$frame", frame)
		-- DrawTexturedRect uses whatever draw color the last HUD element left behind, which can be
		-- black or fully transparent - set it explicitly so the wormhole is always visible
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(style.Material)
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
	end )
end)

usermessage.Hook( "Lib.EventHorizon.WormHoleStart_video", function(um)
	started = CurTime();
	local e = LocalPlayer();
	e:EmitSound("stargate/travelnew.mp3")
	hook.Add("EntityEmitSound","Lib.EH.WormHole",function() return false end)
	hook.Add("PlayerBindPress","Lib.EH.WormHole",function() return true end)
	hook.Add("PreRender","Lib.EH.WormHole",function()
		render.UpdateScreenEffectTexture()
		render.SetMaterial(Material("williamdefly/wormhole2"))
		render.DrawScreenQuad()
		return true;
	end)
end)


usermessage.Hook( "Lib.EventHorizon.WormHoleReset", StopWormholeScreen)
usermessage.Hook( "Lib.EventHorizon.WormHoleOut", StopWormholeScreen)
usermessage.Hook( "Lib.EventHorizon.WormHoleStop", StopWormholeScreen)

--universe_travel_end.mp3
