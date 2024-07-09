spawnmenu.AddContentType("mw_npc", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local gmod_npcweapon = GetConVar("gmod_npcweapon") or CreateConVar("gmod_npcweapon", "", {FCVAR_ARCHIVE})

    if (not obj.weapon) then
        obj.weapon = gmod_npcweapon:GetString()
    end

    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("npc")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip("Admin Only")
        end
    end

    icon:SetAdminOnly(obj.admin)
    icon:SetNPCWeapon(obj.weapon)
    icon:SetColor(Color(244, 164, 96, 255))
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    icon:SetTooltip(Tooltip)

    icon.DoClick = function()
        local weapon = obj.weapon

        if (gmod_npcweapon:GetString() ~= "") then
            weapon = gmod_npcweapon:GetString()
        end

        RunConsoleCommand("cap_spawnnpc", obj.spawnname, weapon)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()
        local weapon = obj.weapon

        if (gmod_npcweapon:GetString() ~= "") then
            weapon = gmod_npcweapon:GetString()
        end

        menu:AddOption("Copy to Clipboard", function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption("Spawn Using Toolgun", function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "2")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
            RunConsoleCommand("cap_creator_arg", weapon)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

spawnmenu.AddContentType("mw_entity", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("entity")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip("Admin Only")
        end
    end

    icon:SetAdminOnly(obj.admin)
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    if (obj.info and obj.info ~= "") then
        Tooltip = Format("%s\n\n%s", Tooltip, obj.info)
    end

    icon:SetTooltip(Tooltip)
    icon:SetColor(Color(205, 92, 92, 255))

    icon.DoClick = function()
        RunConsoleCommand("cap_spawnsent", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()

        menu:AddOption("Copy to Clipboard", function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption("Spawn Using Toolgun", function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "0")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

spawnmenu.AddContentType("mw_weapon", function(container, obj)
    if (not obj.material) then return end
    if (not obj.nicename) then return end
    if (not obj.spawnname) then return end
    local icon = vgui.Create("ContentIcon", container)
    icon:SetContentType("weapon")
    icon:SetSpawnName(obj.spawnname)
    icon:SetName(obj.nicename)
    icon:SetMaterial(obj.material)

    icon.SetAdminOnly = function(self, admin)
        if (admin) then
            self.imgAdmin = vgui.Create("DImage", self)
            self.imgAdmin:SetImage("icon16/shield.png")
            self.imgAdmin:SetSize(16, 16)
            self.imgAdmin:SetPos(self:GetWide() - 22, 5)
            self.imgAdmin:SetTooltip("Admin Only")
        end
    end

    icon:SetAdminOnly(obj.admin)
    local Tooltip = Format("%s", obj.nicename)

    if (obj.author) then
        Tooltip = Format("%s\n" .. SGLanguage.GetMessage("cap_menu_author") .. ": %s", Tooltip, obj.author)
    end

    if (obj.info and obj.info ~= "") then
        Tooltip = Format("%s\n\n%s", Tooltip, obj.info)
    end

    icon:SetTooltip(Tooltip)
    icon:SetColor(Color(135, 206, 250, 255))

    icon.DoClick = function()
        RunConsoleCommand("cap_giveswep", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.DoMiddleClick = function()
        RunConsoleCommand("cap_spawnswep", obj.spawnname)
        surface.PlaySound("ui/buttonclickrelease.wav")
    end

    icon.OpenMenu = function(icon)
        local menu = DermaMenu()

        menu:AddOption("Copy to Clipboard", function()
            SetClipboardText(obj.spawnname)
        end)

        menu:AddOption("Spawn Using Toolgun", function()
            RunConsoleCommand("gmod_tool", "cap_creator")
            RunConsoleCommand("cap_creator_type", "3")
            RunConsoleCommand("cap_creator_name", obj.spawnname)
        end)

        menu:Open()
    end

    if (IsValid(container)) then
        container:Add(icon)
    end

    return icon
end)

local function MWAddTab(Categorised, pnlContent, tree, node)
    --
    -- Add a tree node for each category
    --
    for CategoryName, v in SortedPairs(Categorised) do
        -- Add a node to the tree
        local icon = "icon16/bricks.png"
        local enttype = v[1].__enttype
        local adminonly, disabled = "ent_groups_only", "cap_disabled_ent"

        if (enttype == "mw_weapon") then
            icon = "icon16/gun.png"
            adminonly, disabled = "swep_groups_only", "cap_disabled_swep"
        end
    end
end

hook.Add("MWTab", "AddEntityContent", function(pnlContent, tree, node)
    local Categorised = {}
    -- Add this list into the tormoil
    local SpawnableEntities = list.Get("MW.Entity")

    if (SpawnableEntities) then
        for k, v in pairs(SpawnableEntities) do
            v.Category = v.Category or "Other"
            v.__ClassName = k
            v.__enttype = "mw_entity"
            Categorised[v.Category] = Categorised[v.Category] or {}
            table.insert(Categorised[v.Category], v)
        end
    end

    MWAddTab(Categorised, pnlContent, tree, node)
    Categorised = {}
    -- Loop through the weapons and add them to the menu
    local Weapons = list.Get("MW.Weapon")

    -- Build into categories
    for k, weapon in pairs(Weapons) do
        weapon.__ClassName = k
        weapon.__enttype = "mw_weapon"
        Categorised[weapon.Category] = Categorised[weapon.Category] or {}
        table.insert(Categorised[weapon.Category], weapon)
    end

    MWAddTab(Categorised, pnlContent, tree, node)
	Categorised = {}
    -- Get a list of available NPCs
    local NPCList = list.Get("MW.NPC")

    -- Categorize them
    for k, v in pairs(NPCList) do
        local Category = v.Category or "Other"
        local Tab = Categorised[Category] or {}
        --Tab[ k ] = v
        v.__enttype = "mw_npc"
        v.__ClassName = k
        Categorised[Category] = Tab
        table.insert(Categorised[Category], v)
    end

    MWAddTab(Categorised, pnlContent, tree, node)



    if (MW.CheckModule("misc")) then
        local node = tree:AddNode("Props"), "icon16/folder.png", true
        --node.DoPopulate = function(self)
        local self = node
        -- If we've already populated it - forget it.
        if (self.PropPanel) then return end
        self.PropPanel = vgui.Create("ContentContainer", pnlContent)
        self.PropPanel:SetVisible(false)
        --self.PropPanel:SetTriggerSpawnlistChange( false )
        local spl = {"Misc", "CapBuild", "CatWalkBuild"} -- for order

        for i = 1, 3 do
            local spawnlist = MW.SpawnList[spl[i]]

            if (spawnlist) then
                local models = node:AddNode("Props" .. i, "icon16/page.png")

                models.DoPopulate = function(self)
                    -- If we've already populated it - forget it.
                    if (self.PropPanel) then return end
                    self.PropPanel = vgui.Create("ContentContainer", pnlContent)
                    self.PropPanel:SetVisible(false)
                    --self.PropPanel:SetTriggerSpawnlistChange( false )
                    local lines = MW.SpawnList[spl[i]]

                    for _, l in pairs(lines) do
                        if (not l or l == "") then continue end
                        local cp = spawnmenu.GetContentType("model")

                        if (cp) then
                            cp(self.PropPanel, {
                                model = l
                            })
                        end
                    end
                end

                models.DoClick = function(self)
                    self:DoPopulate()
                    pnlContent:SwitchPanel(self.PropPanel)
                end
            end
        end
        --end
        --[[
	-- If we click on the node populate it and switch to it.
	node.DoClick = function( self )

		self:DoPopulate()
		--pnlContent:SwitchPanel( self.PropPanel );
		local FirstNode = node:GetChildNode( 0 )
		if ( IsValid( FirstNode ) ) then
			FirstNode:InternalDoClick()
		end

	end ]]
    end

    local node = tree:AddNode(SGLanguage.GetMessage("spawninfo_title"), "icon16/information.png", true)
    --[[
	local multi_url = SGLanguage.GetMessage("spawninfo_multi_url");
	if (not SGLanguage.ValidMessage("spawninfo_multi_url")) then
		multi_url = StarGate.HTTP.MULTI;
	end]]
    local cats = {{SGLanguage.GetMessage("spawninfo_news"), StarGate.HTTP.NEWS, "icon16/newspaper.png"}, {SGLanguage.GetMessage("spawninfo_wiki"), StarGate.HTTP.WIKI, "icon16/page_white_text.png"}, {SGLanguage.GetMessage("spawninfo_forum"), StarGate.HTTP.FORUM, "icon16/group.png"}, {SGLanguage.GetMessage("spawninfo_fp"), StarGate.HTTP.FACEPUNCH, "icon16/transmit_blue.png"}, {SGLanguage.GetMessage("spawninfo_donate"), StarGate.HTTP.DONATE, "icon16/money_add.png"}} --{SGLanguage.GetMessage("spawninfo_multi"),multi_url,"icon16/user_go.png"},

    for k, v in pairs(cats) do
        local panel = node:AddNode(v[1], v[3])

        -- this code is buggy, can't understand why i can't enter data into textbox, so using steam browser instead.
        --[[panel.DoPopulate = function(self)
			if ( self.PropPanel ) then return end
			self.PropPanel = vgui.Create("EditablePanel",pnlContent);
			self.PropPanel:Dock(FILL);
			self.PropPanel.Label = vgui.Create("DLabel",self.PropPanel);
			self.PropPanel.Label:SetText(SGLanguage.GetMessage("spawninfo_load"));
			self.PropPanel.Label:SetColor(Color(0,0,0,255));
			self.PropPanel.Label:SizeToContents();
			self.PropPanel.Paint = function(self,w,h)
				draw.RoundedBox(0,0,0,w,h,Color(255,255,255,255));
				self.Label:SetPos(w/2-10,h/2-10);
			end
			self.HTML = vgui.Create("DHTML",self.PropPanel);
			self.HTML:Dock(FILL);
			self.HTML:SetKeyBoardInputEnabled(true);
			self.HTML:SetMouseInputEnabled(true);
		end]]
        panel.DoClick = function(self)
            --self:DoPopulate()
            --self.HTML:OpenURL(v[2]);
            --pnlContent:SwitchPanel( self.PropPanel );
            gui.OpenURL(v[2])
        end
    end

    -- Select the first node
    local FirstNode = tree:Root():GetChildNode(0)

    if (IsValid(FirstNode)) then
        FirstNode:InternalDoClick()
    end
end)