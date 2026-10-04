--[[
	Shield Core
	Copyright (C) 2011 Madman07
]]
--
include('shared.lua')
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_main_cat");
ENT.PrintName = SGLanguage.GetMessage("entity_shield_core");
end
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.SC_hud = surface.GetTextureID("VGUI/resources_hud/MCD")
local matBlurScreen = Material("pp/blurscreen")

function ENT:Draw()
    if self:GetNetworkedBool("ShouldClip", false) then
        self:UpdateClipping()
    else
        self:SetRenderClipPlaneEnabled(false)
    end

    self:DrawModel()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "SC")

    if (LocalPlayer():GetEyeTrace().Entity == self.Entity and EyePos():Distance(self.Entity:GetPos()) < 1024) then
        hook.Add("HUDPaint", tostring(self.Entity) .. "SC", function()
            surface.SetTexture(self.SC_hud)
            surface.SetDrawColor(Color(255, 255, 255, 155))
            surface.DrawTexturedRect(ScrW() / 2 - 24, ScrH() / 2 - 112, 126, 90)
            draw.DrawText("Shield Core", "header", ScrW() / 2 + 16, ScrH() / 2 - 103, Color(0, 255, 255, 255), 0)
            local enabled = 0

            if IsValid(self) then
                enabled = self:GetNWInt("HUD_Enable", 0)
            end

            local text = "Off"

            if (enabled == 1) then
                text = "On"
            elseif (enabled == 2) then
                text = "Depleted"
            end

            draw.DrawText("Shield: (" .. text .. ")", "center", ScrW() / 2 + 9, ScrH() / 2 - 77, Color(209, 238, 238, 255), 0)
            local percent = 0

            if IsValid(self) then
                percent = self:GetNWInt("HUD_Percent", 0)
            end

            percent = string.format("%G", percent)
            draw.SimpleText(percent .. "%", "center", ScrW() / 2 + 9, ScrH() / 2 - 62, Color(209, 238, 238, 255), 0)
        end)
    end
end

function ENT:UpdateClipping()
    local normal = self:GetUp()
    local distance = normal:Dot(self:GetPos() - normal)
    self:SetRenderClipPlaneEnabled(true)
    self:SetRenderClipPlane(normal, distance)
end

function ENT:OnRemove()
    hook.Remove("HUDPaint", tostring(self.Entity) .. "SC")
end

local VGUI = {}

function VGUI:Init()
    -- SHIELD CORE MENU
    local DermaPanel = vgui.Create("DFrame")
    DermaPanel:SetSize(370, 425)
    DermaPanel:SetPos(ScrW() / 10, ScrH() / 10)
    DermaPanel:SetTitle("Shield Core Control Panel")
    DermaPanel:SetVisible(true)
    DermaPanel:SetDraggable(true) -- Can be moved around (drag the title bar)
    DermaPanel:ShowCloseButton(true)
    DermaPanel:SetScreenLock(true)
    DermaPanel:MakePopup()
    local applied = false

    -- Closing the window in any way other than OK cancels the changes
    DermaPanel.OnClose = function()
        if (not applied and IsValid(e)) then
            LocalPlayer():ConCommand("SC_Close" .. e:EntIndex())
        end
    end

    DermaPanel.Paint = function(pnl, w, h)
        -- Thanks Overv, http://www.facepunch.com/threads/1041686-What-are-you-working-on-V4-John-Lua-Edition
        -- Blurred background, lined up with the screen wherever the window is
        local x, y = pnl:LocalToScreen(0, 0)
        surface.SetMaterial(matBlurScreen)
        surface.SetDrawColor(255, 255, 255, 255)
        matBlurScreen:SetFloat("$blur", 5)
        render.UpdateScreenEffectTexture()
        surface.DrawTexturedRect(-x, -y, ScrW(), ScrH())
        surface.SetDrawColor(60, 70, 85, 190)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(40, 50, 65, 230) -- Title bar
        surface.DrawRect(0, 0, w, 24)
        surface.SetDrawColor(110, 170, 255, 255) -- Border
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    local image = vgui.Create("TGAImage", DermaPanel)
    image:SetSize(10, 10)
    image:SetPos(10, 10)
    image:LoadTGAImage("materials/gui/cap_logo.tga", "MOD")

    --///// TABS
    local Sheet = vgui.Create("DPropertySheet", DermaPanel)
    Sheet:SetPos(25, 40)
    Sheet:SetSize(320, 250)
    local sheet_col = Color(100, 100, 100, 255)
    local sheet_x = 310
    local sheet_y = 220
    local Sheet_Size = vgui.Create("DPanel", Sheet)
    Sheet_Size:SetPos(0, 0)
    Sheet_Size:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Size.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    local Sheet_Ang = vgui.Create("DPanel", Sheet)
    Sheet_Ang:SetPos(0, 0)
    Sheet_Ang:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Ang.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    local Sheet_Pos = vgui.Create("DPanel", Sheet)
    Sheet_Pos:SetPos(0, 0)
    Sheet_Pos:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Pos.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    local Sheet_Visual = vgui.Create("DPanel", Sheet)
    Sheet_Visual:SetPos(0, 0)
    Sheet_Visual:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Visual.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    local Sheet_Other = vgui.Create("DPanel", Sheet)
    Sheet_Other:SetPos(0, 0)
    Sheet_Other:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Other.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    Sheet:AddSheet("Size", Sheet_Size, "icon16/user.png", false, false, "Size of the buble.")
    Sheet:AddSheet("Angle", Sheet_Ang, "icon16/user.png", false, false, "Angles of the buble.")
    Sheet:AddSheet("Position", Sheet_Pos, "icon16/user.png", false, false, "Position of the buble.")
    Sheet:AddSheet("Visual", Sheet_Visual, "icon16/user.png", false, false, "Model and color of the buble.")
    Sheet:AddSheet("Other", Sheet_Other, "icon16/user.png", false, false, "Other settings.")
    local Sheet_Access = vgui.Create("DPanel", Sheet)
    Sheet_Access:SetPos(0, 0)
    Sheet_Access:SetSize(Sheet:GetWide(), Sheet:GetTall())

    Sheet_Access.Paint = function()
        draw.RoundedBox(6, 0, 0, sheet_x, sheet_y, sheet_col)
    end

    Sheet:AddSheet("Access", Sheet_Access, "icon16/key.png", false, false, "Who and what may pass.")
    --////// Const
    local Slider_pos_x = 25
    local Slider_pos_y1 = 20
    local Slider_pos_y2 = 60
    local Slider_pos_y3 = 100
    local Slider_size_x = 250
    local Slider_size_y = 50
    local Button_size_x = 75
    local Button_size_y = 25
    --////// SIZE
    local min_size, max_size = e:GetNWFloat("MinSize", 100), e:GetNWFloat("MaxSize", 4096) -- Server config ([shield_core])
    local Size_x = vgui.Create("DNumSlider", Sheet_Size)
    Size_x:SetPos(Slider_pos_x, Slider_pos_y1)
    Size_x:SetSize(Slider_size_x, Slider_size_y)
    Size_x:SetText("Size x:")
    Size_x:SetMin(min_size)
    Size_x:SetMax(max_size)
    Size_x:SetValue(e:GetNWVector("Size", Vector(100, 100, 100)).x)
    Size_x:SetDecimals(0)

    Size_x.OnValueChanged = function(Size_x, fValue)
        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. VGUI.Size_x:GetValue() .. " " .. VGUI.Size_y:GetValue() .. " " .. VGUI.Size_z:GetValue())
    end

    local Size_y = vgui.Create("DNumSlider", Sheet_Size)
    Size_y:SetPos(Slider_pos_x, Slider_pos_y2)
    Size_y:SetSize(Slider_size_x, Slider_size_y)
    Size_y:SetText("Size y:")
    Size_y:SetMin(min_size)
    Size_y:SetMax(max_size)
    Size_y:SetValue(e:GetNWVector("Size", Vector(100, 100, 100)).y)
    Size_y:SetDecimals(0)

    Size_y.OnValueChanged = function(Size_y, fValue)
        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. VGUI.Size_x:GetValue() .. " " .. VGUI.Size_y:GetValue() .. " " .. VGUI.Size_z:GetValue())
    end

    local Size_z = vgui.Create("DNumSlider", Sheet_Size)
    Size_z:SetPos(Slider_pos_x, Slider_pos_y3)
    Size_z:SetSize(Slider_size_x, Slider_size_y)
    Size_z:SetText("Size z:")
    Size_z:SetMin(min_size)
    Size_z:SetMax(max_size)
    Size_z:SetValue(e:GetNWVector("Size", Vector(100, 100, 100)).z)
    Size_z:SetDecimals(0)

    Size_z.OnValueChanged = function(Size_z, fValue)
        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. VGUI.Size_x:GetValue() .. " " .. VGUI.Size_y:GetValue() .. " " .. VGUI.Size_z:GetValue())
    end

    -- Keep proportions: moving one size slider scales the other two with it
    local KeepRatio = vgui.Create("DCheckBoxLabel", Sheet_Size)
    KeepRatio:SetPos(Slider_pos_x, 165)
    KeepRatio:SetText("Keep proportions")
    KeepRatio:SetValue(false)
    KeepRatio:SizeToContents()
    local syncing = false
    local last_size = {x = Size_x:GetValue(), y = Size_y:GetValue(), z = Size_z:GetValue()}

    local function SizeChanged(axis)
        if (syncing) then return end
        local sliders = {x = Size_x, y = Size_y, z = Size_z}
        if (KeepRatio:GetChecked() and last_size[axis] > 0) then
            local factor = sliders[axis]:GetValue() / last_size[axis]
            syncing = true
            for k, slider in pairs(sliders) do
                if (k ~= axis) then slider:SetValue(math.Clamp(last_size[k] * factor, min_size, max_size)) end
            end
            syncing = false
        end
        last_size = {x = Size_x:GetValue(), y = Size_y:GetValue(), z = Size_z:GetValue()}
        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. Size_x:GetValue() .. " " .. Size_y:GetValue() .. " " .. Size_z:GetValue())
    end

    Size_x.OnValueChanged = function() SizeChanged("x") end
    Size_y.OnValueChanged = function() SizeChanged("y") end
    Size_z.OnValueChanged = function() SizeChanged("z") end

    local Reset_Size = vgui.Create("DButton")
    Reset_Size:SetParent(Sheet_Size)
    Reset_Size:SetText("Reset")
    Reset_Size:SetPos(200, 160)
    Reset_Size:SetSize(Button_size_x, Button_size_y)

    Reset_Size.DoClick = function(btn0)
        VGUI.Size_x:SetValue(100)
        VGUI.Size_y:SetValue(100)
        VGUI.Size_z:SetValue(100)
        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. VGUI.Size_x:GetValue() .. " " .. VGUI.Size_y:GetValue() .. " " .. VGUI.Size_z:GetValue())
    end

    --////// ANGLE
    local Angle_x = vgui.Create("DNumSlider", Sheet_Ang)
    Angle_x:SetPos(Slider_pos_x, Slider_pos_y1)
    Angle_x:SetSize(Slider_size_x, Slider_size_y)
    Angle_x:SetText("Pitch:")
    Angle_x:SetMin(-180)
    Angle_x:SetMax(180)
    Angle_x:SetValue(e:GetNWAngle("Ang", Angle(100, 100, 100)).x)
    Angle_x:SetDecimals(0)

    Angle_x.OnValueChanged = function(Angle_x, fValue)
        LocalPlayer():ConCommand("SC_Angle" .. e:EntIndex() .. " " .. VGUI.Angle_x:GetValue() .. " " .. VGUI.Angle_y:GetValue() .. " " .. VGUI.Angle_z:GetValue())
    end

    local Angle_y = vgui.Create("DNumSlider", Sheet_Ang)
    Angle_y:SetPos(Slider_pos_x, Slider_pos_y2)
    Angle_y:SetSize(Slider_size_x, Slider_size_y)
    Angle_y:SetText("Yaw:")
    Angle_y:SetMin(-180)
    Angle_y:SetMax(180)
    Angle_y:SetValue(e:GetNWAngle("Ang", Angle(100, 100, 100)).y)
    Angle_y:SetDecimals(0)

    Angle_y.OnValueChanged = function(Angle_y, fValue)
        LocalPlayer():ConCommand("SC_Angle" .. e:EntIndex() .. " " .. VGUI.Angle_x:GetValue() .. " " .. VGUI.Angle_y:GetValue() .. " " .. VGUI.Angle_z:GetValue())
    end

    local Angle_z = vgui.Create("DNumSlider", Sheet_Ang)
    Angle_z:SetPos(Slider_pos_x, Slider_pos_y3)
    Angle_z:SetSize(Slider_size_x, Slider_size_y)
    Angle_z:SetText("Roll:")
    Angle_z:SetMin(-180)
    Angle_z:SetMax(180)
    Angle_z:SetValue(e:GetNWAngle("Ang", Angle(100, 100, 100)).z)
    Angle_z:SetDecimals(0)

    Angle_z.OnValueChanged = function(Angle_z, fValue)
        LocalPlayer():ConCommand("SC_Angle" .. e:EntIndex() .. " " .. VGUI.Angle_x:GetValue() .. " " .. VGUI.Angle_y:GetValue() .. " " .. VGUI.Angle_z:GetValue())
    end

    local Reset_Ang = vgui.Create("DButton")
    Reset_Ang:SetParent(Sheet_Ang)
    Reset_Ang:SetText("Reset")
    Reset_Ang:SetPos(200, 160)
    Reset_Ang:SetSize(Button_size_x, Button_size_y)

    Reset_Ang.DoClick = function(btn1)
        VGUI.Angle_x:SetValue(0)
        VGUI.Angle_y:SetValue(0)
        VGUI.Angle_z:SetValue(0)
        LocalPlayer():ConCommand("SC_Angle" .. e:EntIndex() .. " " .. VGUI.Angle_x:GetValue() .. " " .. VGUI.Angle_y:GetValue() .. " " .. VGUI.Angle_z:GetValue())
    end

    --////// POSITION
    local Pos_x = vgui.Create("DNumSlider", Sheet_Pos)
    Pos_x:SetPos(Slider_pos_x, Slider_pos_y1)
    Pos_x:SetSize(Slider_size_x, Slider_size_y)
    Pos_x:SetText("Position x:")
    Pos_x:SetMin(-512)
    Pos_x:SetMax(512)
    Pos_x:SetValue(e:GetNWVector("Pos", Vector(100, 100, 100)).x)
    Pos_x:SetDecimals(0)

    Pos_x.OnValueChanged = function(Pos_x, fValue)
        LocalPlayer():ConCommand("SC_Pos" .. e:EntIndex() .. " " .. VGUI.Pos_x:GetValue() .. " " .. VGUI.Pos_y:GetValue() .. " " .. VGUI.Pos_z:GetValue())
    end

    local Pos_y = vgui.Create("DNumSlider", Sheet_Pos)
    Pos_y:SetPos(Slider_pos_x, Slider_pos_y2)
    Pos_y:SetSize(Slider_size_x, Slider_size_y)
    Pos_y:SetText("Position y:")
    Pos_y:SetMin(-512)
    Pos_y:SetMax(512)
    Pos_y:SetValue(e:GetNWVector("Pos", Vector(100, 100, 100)).y)
    Pos_y:SetDecimals(0)

    Pos_y.OnValueChanged = function(Pos_y, fValue)
        LocalPlayer():ConCommand("SC_Pos" .. e:EntIndex() .. " " .. VGUI.Pos_x:GetValue() .. " " .. VGUI.Pos_y:GetValue() .. " " .. VGUI.Pos_z:GetValue())
    end

    local Pos_z = vgui.Create("DNumSlider", Sheet_Pos)
    Pos_z:SetPos(Slider_pos_x, Slider_pos_y3)
    Pos_z:SetSize(Slider_size_x, Slider_size_y)
    Pos_z:SetText("Position z:")
    Pos_z:SetMin(-512)
    Pos_z:SetMax(512)
    Pos_z:SetValue(e:GetNWVector("Pos", Vector(100, 100, 100)).z)
    Pos_z:SetDecimals(0)

    Pos_z.OnValueChanged = function(Pos_z, fValue)
        LocalPlayer():ConCommand("SC_Pos" .. e:EntIndex() .. " " .. VGUI.Pos_x:GetValue() .. " " .. VGUI.Pos_y:GetValue() .. " " .. VGUI.Pos_z:GetValue())
    end

    local Reset_Pos = vgui.Create("DButton")
    Reset_Pos:SetParent(Sheet_Pos)
    Reset_Pos:SetText("Reset")
    Reset_Pos:SetPos(200, 160)
    Reset_Pos:SetSize(Button_size_x, Button_size_y)

    Reset_Pos.DoClick = function(btn2)
        VGUI.Pos_x:SetValue(0)
        VGUI.Pos_y:SetValue(0)
        VGUI.Pos_z:SetValue(0)
        LocalPlayer():ConCommand("SC_Pos" .. e:EntIndex() .. " " .. VGUI.Pos_x:GetValue() .. " " .. VGUI.Pos_y:GetValue() .. " " .. VGUI.Pos_z:GetValue())
    end

    --////// COLOR
    local Col = vgui.Create("DColorMixer", Sheet_Visual)
    Col:SetSize(160, 160)
    Col:SetPos(25, 20)
    local r_get = e:GetNWVector("Col", Vector(170, 189, 255)).x
    local g_get = e:GetNWVector("Col", Vector(170, 189, 255)).y
    local b_get = e:GetNWVector("Col", Vector(170, 189, 255)).z
    Col:SetColor(Color(r_get, g_get, b_get, 255))

    local last_col = ""

    Col.Think = function(aa)
        Col:ConVarThink()
        local r = Col:GetColor().r
        local g = Col:GetColor().g
        local b = Col:GetColor().b
        local col = r .. " " .. g .. " " .. b
        if (col == last_col) then return end -- Was sent to the server every frame
        last_col = col
        --[[VGUI.col_r:SetText("R: "..tostring(r));
		VGUI.col_r:SizeToContents();

		VGUI.col_g:SetText("G: "..tostring(g));
		VGUI.col_g:SizeToContents();

		VGUI.col_b:SetText("B: "..tostring(b));
		VGUI.col_b:SizeToContents();   ]]
        LocalPlayer():ConCommand("SC_Visual_Col" .. e:EntIndex() .. " " .. r .. " " .. g .. " " .. b)
    end

    --[[
	local col_r = vgui.Create("DLabel", Sheet_Visual);
	col_r:SetPos( 25, 130);
	col_r:SetText("R: "..tostring(Col:GetColor().r));
	col_r:SizeToContents();

	local col_g = vgui.Create("DLabel", Sheet_Visual);
	col_g:SetPos( 25, 150);
	col_g:SetText("G: "..tostring(Col:GetColor().g));
	col_g:SizeToContents();

	local col_b = vgui.Create("DLabel", Sheet_Visual);
	col_b:SetPos( 25, 170);
	col_b:SetText("B: "..tostring(Col:GetColor().b));
	col_b:SizeToContents();  ]]
    --///// MODEL
    local Model_box = vgui.Create("DComboBox", Sheet_Visual)
    Model_box:SetPos(200, 20)
    Model_box:SetSize(80, 30)

    --Model_box:SetMultiple( false )
    Model_box.Paint = function()
        surface.SetDrawColor(155, 155, 155, 125)
        surface.SetFont("default")
        surface.SetTextColor(255, 255, 255, 255)
        surface.DrawRect(0, 0, Model_box:GetWide(), Model_box:GetTall())
    end

    local sph = Model_box:AddChoice("Sphere")
    local box = Model_box:AddChoice("Box")
    local atla = Model_box:AddChoice("Atlantis")
    Model_box:SetToolTip("Select your shield model.")
    local mod_get = e:GetNWString("Mod", "models/Madman07/shields/sphere.mdl")

    if (mod_get == "models/Madman07/shields/sphere.mdl") then
        Model_box:ChooseOption("Sphere", 1)
    elseif (mod_get == "models/Madman07/shields/box.mdl") then
        Model_box:ChooseOption("Box", 2)
    elseif (mod_get == "models/Madman07/shields/atlantis.mdl") then
        Model_box:ChooseOption("Atlantis", 3)
    end

    Model_box.OnSelect = function(panel, index, value)
        LocalPlayer():ConCommand("SC_Visual_Model" .. e:EntIndex() .. " " .. index)
    end

    --/// Variables
    VGUI.col_r = col_r
    VGUI.col_g = col_g
    VGUI.col_b = col_b
    VGUI.Size_x = Size_x
    VGUI.Size_y = Size_y
    VGUI.Size_z = Size_z
    VGUI.Angle_x = Angle_x
    VGUI.Angle_y = Angle_y
    VGUI.Angle_z = Angle_z
    VGUI.Pos_x = Pos_x
    VGUI.Pos_y = Pos_y
    VGUI.Pos_z = Pos_z
    --///// OTHER
    local menudata = string.Explode(" ", e:GetNWString("MenuData", "0 0 0 0 5 0 0 0 0 0"))
    local Power = vgui.Create("DNumSlider", Sheet_Other)
    Power:SetPos(25, 40)
    Power:SetSize(250, 50)
    Power:SetText("Faster - Stronger:")
    Power:SetMin(-5)
    Power:SetMax(5)
    Power:SetValue(tonumber(menudata[1]))
    Power:SetDecimals(2)
    Power:SetToolTip("Increasing the Strength will result into slower Regeneration and more Energy Usage.")
    Power.OnValueChanged = function(Power, fValue) end
    local Immunity = vgui.Create("DCheckBoxLabel", Sheet_Other)
    Immunity:SetPos(25, 100)
    Immunity:SetText("Immunity")
    Immunity:SetValue(tobool(menudata[2]))
    Immunity:SizeToContents()
    Immunity:SetToolTip("When this is enabled, the owner of the shield can always go or shoot through\nno matter if he was inside the shield when it was turned on or not.")
    local Draw_B = vgui.Create("DCheckBoxLabel", Sheet_Other)
    Draw_B:SetPos(25, 120)
    Draw_B:SetText("Always show Bubble")
    Draw_B:SetValue(tobool(menudata[3]))
    Draw_B:SizeToContents()
    Draw_B:SetToolTip("Different bubble effect (looks like Atlantis shield).")
    local Atlantis = vgui.Create("DCheckBoxLabel", Sheet_Other)
    Atlantis:SetPos(25, 140)
    Atlantis:SetText("Atlantis Type")
    Atlantis:SetValue(tobool(menudata[4]))
    Atlantis:SizeToContents()
    Atlantis:SetToolTip("When this is enabled, shield is active as long, as it have enought power. Be carefull, it drains power really fast.")
    local AntiNoclip = vgui.Create("DCheckBoxLabel", Sheet_Other)
    AntiNoclip:SetPos(25, 160)
    AntiNoclip:SetText("Anti Noclip")
    AntiNoclip:SetValue(tobool(menudata[6]))
    AntiNoclip:SizeToContents()
    AntiNoclip:SetToolTip("When this is enabled, players in noclip can't fly through the shield.")
    local Containment = vgui.Create("DCheckBoxLabel", Sheet_Other)
    Containment:SetPos(25, 180)
    Containment:SetText("Containment")
    Containment:SetValue(tobool(menudata[7]))
    Containment:SizeToContents()
    Containment:SetToolTip("Keep things in instead of out: anything can enter, nothing inside can leave.\nExplosions inside (e.g. a naquadah bomb) stay inside.")
    local RisingEdge = vgui.Create("DCheckBoxLabel", Sheet_Other)
    RisingEdge:SetPos(25, 200)
    RisingEdge:SetText("Rising edge")
    RisingEdge:SetValue(tobool(menudata[10]))
    RisingEdge:SizeToContents()
    RisingEdge:SetToolTip("Rise and lower over 5 seconds with a glowing edge, also without \"Always show Bubble\".\nIt only blocks where it has risen to.")
    --///// ACCESS
    local Frequency = vgui.Create("DNumSlider", Sheet_Access)
    Frequency:SetPos(25, 15)
    Frequency:SetSize(260, 40)
    Frequency:SetText("Frequency:")
    Frequency:SetMin(0)
    Frequency:SetMax(1500)
    Frequency:SetDecimals(0)
    Frequency:SetValue(tonumber(menudata[8]) or 0)
    Frequency:SetToolTip("Contraptions with an active Shield Identifier on this frequency may pass. 0 = off.")
    local FireFrequency = vgui.Create("DNumSlider", Sheet_Access)
    FireFrequency:SetPos(25, 55)
    FireFrequency:SetSize(260, 40)
    FireFrequency:SetText("Fire frequency:")
    FireFrequency:SetMin(0)
    FireFrequency:SetMax(1500)
    FireFrequency:SetDecimals(0)
    FireFrequency:SetValue(tonumber(menudata[9]) or 0)
    FireFrequency:SetToolTip("Weapons firing on this frequency (within 50) hit five times softer. 0 = off.\nE.g. staff weapons 325, Asuran beam 575, Asgard/Ori beams 850.")
    local AccessInfo = vgui.Create("DLabel", Sheet_Access)
    AccessInfo:SetPos(25, 100)
    AccessInfo:SetSize(265, 90)
    AccessInfo:SetWrap(true)
    AccessInfo:SetContentAlignment(7)
    AccessInfo:SetText("Always allowed through: whoever was inside when the shield came up, players in the Wire \"Allowed Players\" input, and with Immunity (Other tab) you and your prop protection friends. These apply without switching the shield off.")
    local NumPad = vgui.Create("CtrlNumPad", Sheet_Other)
    NumPad:SetPos(200, 100)
    NumPad.NumPad1:SetValue(menudata[5])
    --NumPad:SetConVar1( "shield_core_activate" )
    NumPad:SetLabel1("Activate shield")
    NumPad:SetSize(100, 50)
    --//////// BUTTONS
    --//////// WHAT OK WILL DO (updated while you edit)
    local start = {
        Size = e:GetNWVector("Size", Vector(100, 100, 100)),
        Ang = e:GetNWAngle("Ang", Angle(0, 0, 0)),
        Pos = e:GetNWVector("Pos", Vector(0, 0, 0)),
        Col = e:GetNWVector("Col", Vector(170, 189, 255)),
        Mod = e:GetNWString("Mod", ""),
        Menu = menudata,
    }

    -- Energy estimate (same formula the server uses, ENT:EstimateEnergy in shared.lua)
    local EnergyLabel = vgui.Create("DLabel", DermaPanel)
    EnergyLabel:SetPos(25, 298)
    EnergyLabel:SetSize(320, 18)
    EnergyLabel:SetTextColor(Color(255, 230, 140))

    local Hint = vgui.Create("DLabel", DermaPanel)
    Hint:SetPos(25, 318)
    Hint:SetSize(320, 45)
    Hint:SetWrap(true)
    Hint:SetContentAlignment(7)

    local function Differs(a, b)
        return math.abs(a[1] - b[1]) + math.abs(a[2] - b[2]) + math.abs(a[3] - b[3]) > 0.5
    end

    Hint.Think = function()
        if (not IsValid(e)) then return end
        if (e.EstimateEnergy) then
            local per_second, engage = e:EstimateEnergy(Vector(Size_x:GetValue(), Size_y:GetValue(), Size_z:GetValue()), e:ShapeFromModel(e:GetNWString("Mod", "")), Power:GetValue())
            local text = string.format("Energy: %s/s while up, %s to switch on", string.Comma(math.Round(per_second)), string.Comma(math.Round(engage)))
            if (Atlantis:GetChecked()) then text = string.format("Energy: Atlantis type, hits drain energy. %s to switch on", string.Comma(math.Round(engage))) end
            if (EnergyLabel:GetText() ~= text) then EnergyLabel:SetText(text) end
        end
        local rebuild = e:GetNWString("Mod", "") ~= start.Mod
            or Differs(Vector(Angle_x:GetValue(), Angle_y:GetValue(), Angle_z:GetValue()), Vector(start.Ang.p, start.Ang.y, start.Ang.r))
            or Differs(Vector(Pos_x:GetValue(), Pos_y:GetValue(), Pos_z:GetValue()), start.Pos)
            or Differs(e:GetNWVector("Col", start.Col), start.Col)
            or math.abs(Power:GetValue() - (tonumber(start.Menu[1]) or 0)) > 0.001
            or Draw_B:GetChecked() ~= tobool(start.Menu[3]) or Atlantis:GetChecked() ~= tobool(start.Menu[4])
            or AntiNoclip:GetChecked() ~= tobool(start.Menu[6]) or RisingEdge:GetChecked() ~= tobool(start.Menu[10])
        local resize = Differs(Vector(Size_x:GetValue(), Size_y:GetValue(), Size_z:GetValue()), start.Size)
        local text, col
        if (rebuild) then
            text, col = "OK switches the shield off and rebuilds it (shape, angle, position, colour, strength or the other options changed).", Color(255, 170, 90)
        elseif (resize) then
            text, col = "OK keeps the shield up and smoothly resizes it.", Color(140, 220, 140)
        else
            text, col = "OK keeps the shield up. Immunity, Containment, the frequencies and the key apply immediately.", Color(200, 220, 255)
        end
        if (Hint:GetText() ~= text) then
            Hint:SetText(text)
            Hint:SetTextColor(col)
        end
    end

    local MenuButtonClose = vgui.Create("DButton")
    MenuButtonClose:SetParent(DermaPanel)
    MenuButtonClose:SetText("Cancel")
    MenuButtonClose:SetPos(270, 385)
    MenuButtonClose:SetSize(Button_size_x, Button_size_y)
    MenuButtonClose:SetToolTip("Close without changing anything.")

    MenuButtonClose.DoClick = function(btn)
        DermaPanel:Close() -- OnClose sends SC_Close
    end

    local MenuButtonCreate = vgui.Create("DButton")
    MenuButtonCreate:SetParent(DermaPanel)
    MenuButtonCreate:SetText("OK")
    MenuButtonCreate:SetPos(185, 385)
    MenuButtonCreate:SetSize(Button_size_x, Button_size_y)

    MenuButtonCreate.DoClick = function(btn)
        local Imm = 0
        local Draw = 0
        local Atl = 0
        local ANC = 0
        local Cont = 0

        if (Immunity:GetChecked()) then
            Imm = 1
        end

        if (Draw_B:GetChecked()) then
            Draw = 1
        end

        if (Atlantis:GetChecked()) then
            Atl = 1
        end

        if (AntiNoclip:GetChecked()) then
            ANC = 1
        end

        if (Containment:GetChecked()) then
            Cont = 1
        end

        LocalPlayer():ConCommand("SC_Size" .. e:EntIndex() .. " " .. VGUI.Size_x:GetValue() .. " " .. VGUI.Size_y:GetValue() .. " " .. VGUI.Size_z:GetValue())
        LocalPlayer():ConCommand("SC_Angle" .. e:EntIndex() .. " " .. VGUI.Angle_x:GetValue() .. " " .. VGUI.Angle_y:GetValue() .. " " .. VGUI.Angle_z:GetValue())
        LocalPlayer():ConCommand("SC_Pos" .. e:EntIndex() .. " " .. VGUI.Pos_x:GetValue() .. " " .. VGUI.Pos_y:GetValue() .. " " .. VGUI.Pos_z:GetValue())
        LocalPlayer():ConCommand("SC_Visual_Col" .. e:EntIndex() .. " " .. Col:GetColor().r .. " " .. Col:GetColor().g .. " " .. Col:GetColor().b)
        LocalPlayer():ConCommand("SC_Apply" .. e:EntIndex() .. " " .. Power:GetValue() .. " " .. Imm .. " " .. Draw .. " " .. Atl .. " " .. NumPad.NumPad1:GetValue() .. " " .. ANC .. " " .. Cont .. " " .. math.Round(Frequency:GetValue()) .. " " .. math.Round(FireFrequency:GetValue()) .. " " .. (RisingEdge:GetChecked() and 1 or 0))
        applied = true
        DermaPanel:Close()
    end
end

vgui.Register("ShieldCoreEntry", VGUI)

function ShieldCorePanel(um)
    e = um:ReadEntity()
    if (not IsValid(e)) then return end
    local Window = vgui.Create("ShieldCoreEntry")
    Window:SetMouseInputEnabled(true)
    Window:SetVisible(true)
end

usermessage.Hook("ShieldCorePanel", ShieldCorePanel)