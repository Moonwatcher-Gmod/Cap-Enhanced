local SWEP = {Primary = {}, Secondary = {}} -- I don't know what this does

if (StarGate == nil or StarGate.CheckModule == nil or not StarGate.CheckModule("weapon")) then return end

if (SGLanguage != nil and SGLanguage.GetMessage != nil) then
    --SWEP.PrintName = SGLanguage.GetMessage("weapon_misc_adria_dialer") --there is no language for this yet
    SWEP.PrintName = "Adria Dialer"
    SWEP.Category = SGLanguage.GetMessage("weapon_misc_cat")
    SWEP.ClassName = "adria_dialer"
end

list.Set("CAP.Weapon", SWEP.PrintName or "", SWEP)

SWEP.Author = "Nova Astral"
SWEP.Purpose = "Dial the previous gate address"
SWEP.Instructions = "LMB - Dial previous gate address"
SWEP.DrawCrosshair = true
SWEP.SlotPos = 10
SWEP.Slot = 3
SWEP.Spawnable = false
SWEP.Weight = 1
SWEP.Primary.Ammo = "none" --This stops it from giving pistol ammo when you get the swep
SWEP.Primary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = true

SWEP.ViewModel = "models/weapons/v_models/v_hdevice.mdl"
SWEP.WorldModel = "models/w_hdevice.mdl"
SWEP.HoldType = "slam"

function SWEP:CanPrimaryAttack() return false end
function SWEP:CanSecondaryAttack() return false end
function SWEP:Holster() return true end
function SWEP:ShouldDropOnDie() return false end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)

    self:DrawShadow(false)

    self.Active = false
    self.tent = nil

    self.DHDs = { 
        "dhd_atlantis",
        "dhd_city",
        "dhd_concept",
        "dhd_infinity",
        "dhd_sg1",
        "dhd_universe"
    }
end

function SWEP:ButtonPress(v,ent)
    if(IsValid(ent)) then
        if(v >= 1 and v < 256) then
            local symbols = "A-Z1-9@#!*"

            if (GetConVar("stargate_group_system"):GetBool()) then
                symbols = "A-Z0-9@#*"
            end

            local char = string.char(v):upper()

            if (v>=128 and v<=137) then -- numpad 0-9
                char = string.char(v-80):upper() 
            elseif (v==139) then -- numpad *
                char = string.char(42):upper()
            end 

            if(char:find("["..symbols.."]")) then -- Only alphanumerical and the @, #
                ent:ButtonMode(char)
            end
        end
    end
end

function SWEP:StopDial()
    self.Active = false

    timer.Remove("adriadial"..self:EntIndex())
    timer.Remove("stopdial"..self:EntIndex())

    if(IsValid(self.tent)) then
        if(self.tent.ButtonsMode) then 
            self.tent:ResetButtons() 
        end

        self.tent.ButtonsMode = false
        self.tent:SetNWBool("ButtonsMode",false)

        if(self.tent:GetWire("Disable DHD") <1) then 
            self.tent.Disabled = false
        else
            self.tent:SetNWBool("Disabled",true)
        end
    end
end

if SERVER then
    function SWEP:PrimaryAttack()
        if(self.Active == false) then
            local tr = self.Owner:GetEyeTrace()
            local ent = tr.Entity
            self.tent = tr.Entity

            if(IsValid(ent) and self.Owner:GetShootPos():Distance(tr.HitPos) < 50) then
                local gate = ent:FindGate()
                if(IsValid(gate) and gate.Active == false and table.HasValue(self.DHDs,ent:GetClass())) then
                    self.Active = true

                    ent.Disabled = true
                    ent.ButtonsMode = true
                    ent:SetNWBool("Disabled",false)
                    ent:SetNWBool("ButtonsMode",true)
                    
                    if not ent.ButtonsMode then
                        ent:ResetButtons()
                    end

                    timer.Create("adriadial"..self:EntIndex(),0.05,0,function()
                        local button = math.random(48,90) --0-Z

                        if(IsValid(ent)) then
                            self:ButtonPress(button,ent)
                        end
                    end)

                    timer.Create("stopdial"..self:EntIndex(),math.random(5,20),1,function()
                        if(IsValid(ent)) then
                            self:StopDial()

                            if(IsValid(gate)) then
                                gate:DialGate(gate.OldDialedAddress,true)
                            end
                        end
                    end)
                end
            end
        end
    end

    function SWEP:SecondaryAttack()
        if(self.Active == true) then
            self:StopDial()
        end
    end

    function SWEP:OnRemove() -- When the player dies
        timer.Remove("adriadial"..self:EntIndex())
        timer.Remove("stopdial"..self:EntIndex())

        if(IsValid(self.tent)) then
            if(self.tent.ButtonsMode) then 
                self.tent:ResetButtons() 
            end

            self.tent.ButtonsMode = false
            self.tent:SetNWBool("ButtonsMode",false)

            if(self.tent:GetWire("Disable DHD") <1) then 
                self.tent.Disabled = false
            else
                self.tent:SetNWBool("Disabled",true)
            end
        end
    end
end

timer.Simple(0.1, function() weapons.Register(SWEP,"adria_dialer", true) end) --Putting this in a timer stops bugs from happening if the weapon is given while the game is paused