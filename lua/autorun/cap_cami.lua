--"Common Admin Mod Interface" for letting admins restrict certain things, most likely through ULX

if SERVER then
    if not CAMI then return end --dont error if CAMI isnt installed

    CAMI.RegisterPrivilege({
        Name="cap - allow mk4 zpm",
        MinAccess="user",
        Description="Allow players to use the Mk4 ZPM type in ZPMs"
    })

    CAMI.RegisterPrivilege({
        Name="cap - allow tampered zpm",
        MinAccess="user",
        Description="Allow players to use the Tampered ZPM (nuke!) type in ZPMs"
    })
end