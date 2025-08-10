include('shared.lua')

function ENT:Initialize()
    -- No client-side initialization needed for this entity yet
end

function ENT:Draw()
    self:DrawModel() -- Draw the mimic's model

    -- If the mimic is seen, draw an indicator icon above it.
    if self:GetSeen() then
        -- Only show the indicator to the player controlling this mimic
        if self:GetOwner() == LocalPlayer() then
            local pos = self:WorldSpaceCenter() + Vector(0, 0, self:OBBMaxs().z + 10) -- Position above the prop
            local ang = Angle(0, LocalPlayer():EyeAngles().y, 90)

            cam.Start3D2D(pos, ang, 0.1)
                -- Draw a red '!' symbol
                draw.SimpleText("!", "DermaLarge", 0, 0, Color(255, 80, 80, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            cam.End3D2D()
        end
    end
end

-- We need to network the "Seen" variable from the server to the client
function ENT:OnDataChanged(key, value)
    if key == "Seen" then
        self.bSeen = value
    end
end

function ENT:GetSeen()
    return self.bSeen or false
end

-- When a player presses the USE key (E), send a network message to the server to request a disguise.
hook.Add("PlayerBindPress", "mh_disguise_key", function(ply, bind, pressed)
    if not pressed then return end
    -- Detect the USE key; PlayerBindPress passes strings like "+use"
    if not string.find(bind, "+use", 1, true) then return end
    if ply:Team() ~= TEAM_MIMICS then return end

    -- Check if the player is controlling a mimic
    local controlled_ent = ply:GetObserverTarget()
    if IsValid(controlled_ent) and controlled_ent:GetClass() == "ent_mimic" then
        net.Start("mh_disguise")
        net.SendToServer()
    end
end)
