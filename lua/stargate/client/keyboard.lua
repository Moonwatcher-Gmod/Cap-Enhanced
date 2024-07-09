--[[
	Stargate Lib for GarrysMod10
	Copyright (C); 2007  aVoN

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option); any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
]]
-- Saves all Schemes.
StarGate.KeyBoard.Schemes = StarGate.KeyBoard.Schemes or {}
StarGate.KeyBoard.MouseWheel = {} -- Used in the PlayerBindPress hook
StarGate.KeyBoard.Keys = {}

-- automatic keys, i'm not sure how much keys can be, on my side it was 170.
-- i must done this because there is no function "input.GetKeyFromName".
for k = 1, 300 do
    local name = input.GetKeyName(k)

    if (name and name ~= "") then
        StarGate.KeyBoard.Keys[name:upper()] = k
    end
end

--######################################
--############# Keyboard Layout object
--######################################
-- Load the player's config file, so we won't block the wrong binds, if their key isn't down in PlayerBindPress
StarGate.KeyBoard.BINDS = {}
local CFG = string.Explode("\n", file.Read("cfg/config.cfg", "GAME") or "")

for _, v in pairs(CFG) do
    if (v:find("bind%s")) then
        local var = string.Explode('" "', ((v:gsub("bind", "")):Trim()):gsub("[%s]+", " "))
        StarGate.KeyBoard.BINDS[var[2]:gsub('"', ""):Trim():lower()] = var[1]:gsub('"', ""):lower()
    end
end

if (not file.IsDir("moonwatcher/keyboard", "DATA")) then
    file.CreateDir("moonwatcher/keyboard")
end

--################### Creates one new KeyBoard Scheme @aVoN
function StarGate.KeyBoard:New(name)
    if (StarGate.KeyBoard.Schemes[name]) then return StarGate.KeyBoard.Schemes[name] end -- It already exists. Return this instead
    local t = {}
    t.Name = name
    StarGate.KeyBoard.Schemes[name] = t

    setmetatable(t, {
        __index = self
    })

    t.__Keys = {}

    -- Load keysettings
    for k, v in pairs(util.KeyValuesToTable(file.Read("moonwatcher/keyboard/" .. name:lower() .. ".txt", "DATA") or "")) do
        t.__Keys[tonumber(k)] = v
    end

    t.Active = false -- Default is deactivated

    return t
end

--################### Retrieves any keyboardlayout by name, so you can set new keys on it, if necessary. @aVoN
-- If that layout does not exist, it will be created
function StarGate.KeyBoard:Get(name)
    return StarGate.KeyBoard.Schemes[name] or self:New(name)
end

--################### This creates a new instance of the keyboard layout, bound to given vehicle @aVoN
--[[
Note: A keyboard-layout can be of course turned on/off and used "as is". But if you have SEVERAL vehicles
(e.g. in multiplayer, another player spawns a vehicle too), you should create a new instance, bound to every vehicle it uses (create a new in ENT:Initialize() by calling this function on an existing KeyBoard layout)
This avoids issues, where one vehicle by another player turns off the keyboard layout of your vehicle.
BUT: On a new instance, you can ONLY use instance:SetActive() and instance:GetActive() on. Nothing else! Any tries to bind a new key here will FAIL
--]]
function StarGate.KeyBoard:CreateInstance(vehicle)
    local t = {}
    t.Parent = self
    t.Vehicle = vehicle

    -- Index the keyboard layout, we create an instance of
    setmetatable(t, {
        __index = self
    })

    -- Create an "autodisable" hook, if the given "vehicle" is an entity
    if (IsValid(vehicle)) then
        vehicle.__OnRemove = vehicle.OnRemove

        vehicle.OnRemove = function(self)
            self.__OnRemove(self) -- Call original "OnRemove";
            t:SetActive(false) -- Set out instance to disabled
        end
    end

    return t
end

--################### SetActive @aVoN
function StarGate.KeyBoard:SetActive(b)
    if (self.Parent) then
        self.Parent.__ActiveVehicle = self.Parent.__ActiveVehicle or self.Vehicle -- First comes, first gets

        if (self.Parent.__ActiveVehicle == self.Vehicle) then
            self.Parent.Active = b

            if (not b) then
                self.Parent.__ActiveVehicle = nil
            end
        end
    else
        self.Active = b
    end
end

--################### GetActive @aVoN
function StarGate.KeyBoard:GetActive()
    return self.Active
end

--################### Creates one new KeyBoard Scheme.  @aVoN
-- name is that key's name. Like FWD for forward. Keep this as short as possible! key is the NAME of that key. E.g. KP_INS
function StarGate.KeyBoard:SetKey(name, key)
    for k, v in pairs(self.__Keys) do
        -- Forbid double binds
        if (v == name) then
            self.__Keys[k] = nil
        end
    end

    self.__Keys[key] = name
    file.Write("moonwatcher/keyboard/" .. self.Name:lower() .. ".txt", util.TableToKeyValues(self.__Keys or {}))
end

--################### Sets a default-key of there isn#t any set yet  @aVoN
-- name is that key's name. Like FWD for forward. Keep this as short as possible! key is the NAME of that key. E.g. KP_INS
function StarGate.KeyBoard:SetDefaultKey(name, key)
    local key = StarGate.KeyBoard.Keys[(key or ""):upper()]
    if (not key) then return end

    for k, v in pairs(self.__Keys) do
        if (v == name) then return end -- We already have such a bind
    end

    self:SetKey(name, key)
end

--################### Get's the key which is bound to this keystring @aVoN
function StarGate.KeyBoard:GetKey(key)
    for k, v in pairs(self.__Keys) do
        if (v == key) then return input.GetKeyName(k) end
    end
end

--Litle helper function, which decides if it's a keyboard key or a mouse key
local LastVGUIOpen

local function IsKeyDown(k, allow_opened_vgui)
    -- VGUI is opened - Do not allow any hooks to be called
    if (not allow_opened_vgui) then
        if (vgui.CursorVisible()) then
            LastVGUIOpen = CurTime()

            return false
        end

        -- This needs some delay. Otherwise, if we press the mouse ona VGUI and this VGUI now closes (e.g. Dialmenu), you imediately start a SHOOT event
        if (LastVGUIOpen) then
            if (LastVGUIOpen + 0.2 > CurTime()) then return false end
            LastVGUIOpen = nil
        end
    end

    if (k == MOUSE_LEFT or k == MOUSE_RIGHT or k == MOUSE_MIDDLE or k == MOUSE_4 or k == MOUSE_5) then
        -- Mousewheel is done at the end of this file in a PlayerBindPress hook
        return input.IsMouseDown(k)
    elseif (k == MOUSE_WHEEL_DOWN) then
        return StarGate.KeyBoard.MouseWheel["MWHEELDOWN"] or false
    elseif (k == MOUSE_WHEEL_UP) then
        return StarGate.KeyBoard.MouseWheel["MWHEELUP"] or false
    end

    return input.IsKeyDown(k)
end

--######################################
--############# Keypress "Hook"
--######################################
--################### The Think which will fire an key-event to the server @aVoN
function StarGate.KeyBoard.Think(GetKeyIsDown)
    local p = LocalPlayer()

    for name, scheme in pairs(StarGate.KeyBoard.Schemes) do
        -- Just do this if the scheme is currently active
        if (scheme:GetActive()) then
            for k, v in pairs(scheme.__Keys) do
                local down = IsKeyDown(k)

                -- This is used in StarGate.KeyBoard.PlayerBindPress to disallow a pressed bind in the case, the pressed key is used in a keyboard layout. Otherwise, you e.g. "get in noclip" and "drive forward" with your ship
                if (GetKeyIsDown) then
                    if (down and input.GetKeyName(k) == GetKeyIsDown) then return true end
                else
                    if (down and not (StarGate.KeyBoard.Pressed[p][name][v] == true)) then
                        StarGate.KeyBoard:SetKeyPressed(p, name, v)
                    elseif (not down and StarGate.KeyBoard.Pressed[p][name][v] == true) then
                        StarGate.KeyBoard:SetKeyReleased(p, name, v)
                    end
                end
            end
        end
    end
end

hook.Add("Think", "StarGate.KeyBoard.Think", StarGate.KeyBoard.Think)

--################### For MouseWheelUp and Down @aVoN
local function UndoTimer(key, name)
    StarGate.KeyBoard.MouseWheel[key] = nil

    if (name) then
        StarGate.KeyBoard:SetKeyReleased(LocalPlayer(), name, key)
    end
end

function StarGate.KeyBoard.PlayerBindPress(p, bind)
    local bind = bind:Trim():lower()
    local key

    -- DOWN
    if (bind == "invnext") then
        key = "MWHEELDOWN"
    elseif (bind == "invprev") then
        -- UP
        key = "MWHEELUP"
    end

    if (key) then
        StarGate.KeyBoard.MouseWheel[key] = true
        local already_undone -- Here, to avoid calling the timer twice
        local p = LocalPlayer()

        for name, scheme in pairs(StarGate.KeyBoard.Schemes) do
            -- Just do this if the scheme is currently active
            if (scheme:GetActive()) then
                if (scheme.__Keys[key]) then
                    already_undone = true
                    StarGate.KeyBoard:SetKeyPressed(p, name, key)

                    -- Undo this. generally, one mouse-wheel action does not really take longer than 0.1 seconds
                    timer.Simple(0.1, function()
                        UndoTimer(key, name)
                    end)

                    return true
                end
            end
        end

        if (not already_undone) then
            -- Undo this. generally, one mouse-wheel action does not really take longer than 0.1 seconds
            timer.Simple(0.1, function()
                UndoTimer(key)
            end)
        end
    end

    -- A key is down in this keyboard-layout. Is it because of this key here? If yes, block this bind. If not, don't do it!
    if (StarGate.KeyBoard.Think(input.LookupBinding(bind))) then return true end
end

hook.Add("PlayerBindPress", "StarGate.KeyBoard.PlayerBindPress", StarGate.KeyBoard.PlayerBindPress)