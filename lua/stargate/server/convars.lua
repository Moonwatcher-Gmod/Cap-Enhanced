--################################ DON'T EDIT THIS FILE YOU CAN MAKE CHANGES IN THE GAME!!!!!!!!!!!!!
-- Finally all default convar values in one file! @AlexALX
-- Arrays for save default values, used in cap settings menu.
StarGate.CAP_Convars = {}
StarGate.CAP_SGConvars = {}

local limits = {{"Destiny Small Turret", "destsmall", 4}, {"Destiny Medium Turret", "destmedium", 2}, {"Destiny MainWeapon", "destmain", 1}, {"Tollana Ion Cannon", "ioncannon", 6}, {"Ship Railgun", "shiprail", 6}, {"Stationary Railgun", "statrail", 2}, {"Drone Launcher", "launchdrone", 2}, {"MiniDrone Platform", "minidrone", 2}, {"Asgard Turret", "asgbeam", 2}, {"AG-3 Sattelites", "ag3", 6}, {"Gate Overloader", "overloader", 1}, {"Asuran Gate Weapon", "asuran_beam", 1}, {"Ori Beam Weapon", "ori_beam", 2}, {"Wraith Plasma Cannon", "wraith_cannon", 4}, {"Dakara Device", "dakara", 1}, {"Shaped Charge", "dirn", 1}, {"Horizon Platform", "horizon", 1}, {"Ori Sattelite", "ori", 1}, {"Staff Stationary", "staffstat", 2}, {"KINO Dispenser", "dispenser", 1}, {"Destiny Console", "destcon", 5}, {"Destiny Apple Core", "applecore", 1}, {"Destiny Node", "destiny_node", 4}, {"Lantean Holo Device", "lantholo", 1}, {"Shield Core", "shieldcore", 1}, {"Sodan Obelisk", "sod_obelisk", 4}, {"Ancient Obelisk", "anc_obelisk", 4}, {"MCD", "mcd", 1}, {"IMCD", "imcd", 1}, {"CAP Ships", "ships", 10}, {"Iris Computer", "iris_comp", 2}, {"AGV", "agv", 2}, {"call_forwarding_device", "call_forwarding_device", 2},{"ZPM Analyser","zpm_analyser", 1}, {"Vanir Plasma Cannon","vanir_cannon",2},{"Hatak Staff Cannon","hatak_cannon",2},{"Attero Device","attero_device",1}} --{"Ashend Defence System", "ashen", 20},

for _, val in pairs(limits) do
    CreateConVar("CAP_" .. val[2] .. "_max", tostring(val[3]), {FCVAR_NEVER_AS_STRING})
    StarGate.CAP_Convars["CAP_" .. val[2] .. "_max"] = val[3]
end

-- From stargate group system by AlexALX
local sgconvars = {{"stargate_candial_groups_dhd", 1}, {"stargate_candial_groups_menu", 1}, {"stargate_candial_groups_wire", 1}, {"stargate_sgu_find_range", 16000}, {"stargate_energy_dial", 1}, {"stargate_energy_dial_spawner", 0}, {"stargate_dhd_protect", 0}, {"stargate_dhd_protect_spawner", 0}, {"stargate_dhd_destroyed_energy", 1}, {"stargate_dhd_close_incoming", 1}, {"stargate_show_inbound_address", 2}, {"stargate_protect", 0}, {"stargate_protect_spawner", 1}, {"stargate_block_address", 2}, {"stargate_dhd_letters", 1}, {"stargate_energy_target", 1}, {"stargate_vgui_glyphs", 2}, {"stargate_dhd_menu", 1}, {"stargate_atlantis_override", 1}, {"stargate_dhd_ring", 1}, {"stargate_global_default", 0}, {"stargate_different_dial_menu", 0}, {"stargate_gatespawner_enabled", 1}, {"stargate_random_address", 1}, {"stargate_gatespawner_protect", 1}, {"stargate_physics_clipping", 1}, {"stargate_model_clipping", 1}, {"stargate_group_system", 1}}

-- Convars
for _, val in pairs(sgconvars) do
    local flags = {FCVAR_ARCHIVE}

    if (val[1] == "stargate_group_system") then
        flags = {FCVAR_NOTIFY, FCVAR_GAMEDLL, FCVAR_ARCHIVE}
    end

    CreateConVar(val[1], tostring(val[2]), flags)
    StarGate.CAP_SGConvars[val[1]] = val[2]
end

local count = cvars.GetConVarCallbacks("stargate_gatespawner_enabled") or {} -- add callback only once

if (table.Count(count) == 0) then
    cvars.AddChangeCallback("stargate_gatespawner_enabled", function(CVar, PreviousValue, NewValue)
        if (util.tobool(tonumber(PreviousValue)) == util.tobool(tonumber(NewValue)) or not (StarGate and StarGate.GateSpawner and StarGate.GateSpawner.InitialSpawn)) then return end
        timer.Remove("stargate_gatespawner_reload")

        timer.Create("stargate_gatespawner_reload", 0.5, 1, function()
            StarGate.GateSpawner.InitialSpawn(true)
        end)
    end)
end

local count = cvars.GetConVarCallbacks("stargate_gatespawner_protect") or {} -- add callback only once

if (table.Count(count) == 0) then
    cvars.AddChangeCallback("stargate_gatespawner_protect", function(CVar, PreviousValue, NewValue)
        if (util.tobool(tonumber(PreviousValue)) == util.tobool(tonumber(NewValue))) then return end

        if (StarGate and StarGate.GateSpawner and StarGate.GateSpawner.Spawned) then
            local protect = util.tobool(tonumber(NewValue))

            for k, v in pairs(StarGate.GateSpawner.Ents) do
                if (v.Entity and IsValid(v.Entity)) then
                    v.Entity.GateSpawnerProtected = protect
                    v.Entity:SetNWBool("GateSpawnerProtected", protect)
                end
            end
        end
    end)
end

local count = cvars.GetConVarCallbacks("stargate_group_system") or {} -- add callback only once

if (table.Count(count) == 0) then
    cvars.AddChangeCallback("stargate_group_system", function(CVar, PreviousValue, NewValue)
        net.Start("stargate_systemtype")
        net.WriteBit(util.tobool(NewValue))
        net.Broadcast()
    end)
end

util.AddNetworkString("stargate_systemtype")

-- send system type to client
local function FirstSpawn(ply)
    net.Start("stargate_systemtype")
    net.WriteBit(util.tobool(GetConVarNumber("stargate_group_system")))
    net.Send(ply)
end

hook.Add("PlayerInitialSpawn", "StarGate.SystemType", FirstSpawn)

function StarGate.LoadConvars()
    if (not file.Exists("moonwatcher/cfg/convars.txt", "DATA")) then return end
    local rtbl = {}
    local ini = INIParser:new("moonwatcher/cfg/convars.txt", false)

    if (ini) then
        if (ini.nodes.cap_convars and ini.nodes.cap_convars[1]) then
            for k, v in pairs(ini.nodes.cap_convars[1]) do
                -- for security
                if (StarGate.CAP_Convars[k] or k:find("sbox_max")) then
                    RunConsoleCommand(k, v)
                    rtbl[k] = v
                end
            end
        end
    end

    return rtbl
end

StarGate.LoadConvars()
