// @note Add more convars here in the future as needed.
// very sorry, here's an example.
//  epoe.AddText(Color(255,0,255),"Wow clientside spam\n")
// Use EPOE, totally worth it.
// https://github.com/Metastruct/EPOE
if SERVER or CLIENT then
    local Help = "Activates any and all chat/epoe hooks that use this CVAR."
    local Name = "debug"
    CreateConVar(Name, 0, FCVAR_NONE, Help, 0, 1)
end
