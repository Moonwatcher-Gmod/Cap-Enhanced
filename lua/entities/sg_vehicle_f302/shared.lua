ENT.Type = "vehicle"
ENT.Base = "sg_vehicle_base"
ENT.PrintName = "F-302"
ENT.Author	= "RononDex, Madman, Rafael De Jongh"
ENT.Category = "Ships"
if (SGLanguage!=nil and SGLanguage.GetMessage!=nil) then
ENT.Category = SGLanguage.GetMessage("entity_ships_cat");
end
list.Set("CAP.Entity", ENT.PrintName, ENT);

ENT.IsSGVehicleCustomView = true