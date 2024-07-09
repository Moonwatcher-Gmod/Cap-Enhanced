local PANEL = {
    Init = function(self)
        self:SetSize(1000, 720)
        self:Center()
        self:SetVisible(true)
        local x, y = self:GetSize()
        local closebutton = vgui.Create("DButton", self)
        closebutton:SetText("Close")
        closebutton:SetSize(75, 25)
        closebutton:SetPos(x - 81, 6)

        closebutton.Paint = function(self, w, h)
            surface.SetDrawColor(180, 180, 180, 50)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(70, 70, 70, 20)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        closebutton.DoClick = function()
            cs_mw_controlchair_targetmenu:SetVisible(false)
            gui.EnableScreenClicker(false)
        end

        local removebutton = vgui.Create("DButton", self)
        removebutton:SetText("Remove")
        removebutton:SetSize(75, 25)
        removebutton:SetPos(x - 162, 6)

        removebutton.Paint = function(self, w, h)
            surface.SetDrawColor(180, 180, 180, 50)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(70, 70, 70, 20)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        removebutton.DoClick = function()
            gui.EnableScreenClicker(false)
            cs_mw_controlchair_targetmenu:Remove()
            cs_mw_controlchair_targetmenu = vgui.Create("cs_mw_controlchair_targetmenu")
            cs_mw_controlchair_targetmenu:SetVisible(false)
        end
    end,
    Paint = function(self, w, h)
        surface.SetDrawColor(55, 55, 55, 235)
        surface.DrawRect(0, 0, w, h)
        surface.DrawOutlinedRect(2, 2, w - 4, h - 4)
        surface.SetDrawColor(0, 76, 153, 255)
        surface.DrawRect(0, 35, w, 60)
        surface.SetTextColor(255, 255, 255, 255)
        surface.SetFont("GModToolSubtitle")
        surface.SetTextPos(10, 7)
        surface.DrawText("Controlchair: Target Menu")
    end
}

vgui.Register("cs_mw_controlchair_targetmenu", PANEL)