include('shared.lua')

-- This function is called every frame to draw the HUD
function GM:HUDPaint()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local round_state = GetGlobalInt("mh_round")
    local round_text = "WAITING"
    if round_state == ROUND_PLAY then
        local ends = GetGlobalFloat("mh_round_ends", 0)
        local time_left = math.max(0, math.ceil(ends - CurTime()))
        round_text = "PLAYING | Time Left: " .. time_left
    elseif round_state == ROUND_POST then
        round_text = "ROUND OVER"
    end

    -- Draw Round State
    draw.SimpleText(
        round_text,
        "DermaLarge",
        ScrW() / 2,
        30,
        Color(255, 255, 255, 200),
        TEXT_ALIGN_CENTER
    )

    -- Draw Team Info
    local team_name = team.GetName(ply:Team())
    local team_color = team.GetColor(ply:Team())
    draw.SimpleText(
        "Team: " .. team_name,
        "DermaLarge",
        30,
        ScrH() - 60,
        team_color,
        TEXT_ALIGN_LEFT
    )

    -- Hide the default HL2 HUD
    self.BaseClass.HUDPaint(self)
    -- You might want to hide specific elements like this:
    -- self:HUDShouldDraw("CHudHealth")
    -- self:HUDShouldDraw("CHudBattery")
    -- self:HUDShouldDraw("CHudAmmo")
    -- self:HUDShouldDraw("CHudSecondaryAmmo")
end

-- A simple hook to hide the default weapon selection
function GM:HUDShouldDraw(name)
    if name == "CHudWeaponSelection" then return false end
    return true
end
