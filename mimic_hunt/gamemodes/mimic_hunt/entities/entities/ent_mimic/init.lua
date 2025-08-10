AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Dev/testing convar: force mimics to be considered "seen"
local mh_cvar_force_seen = CreateConVar("mh_force_seen", "0", FCVAR_ARCHIVE, "Force mimics to be seen (freeze) for testing")

function ENT:Initialize()
  self:SetModel("models/props_c17/oildrum001.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_STEP)
  self:SetSolid(SOLID_BBOX)
  self:SetHealth(100)
  self:SetUseType(SIMPLE_USE) -- Allows player to use it
end

function ENT:SetupDataTables()
    self:NetworkVar("Entity", 0, "Owner")
    self:NetworkVar("Bool", 0, "Seen")
end

-- This function checks if any hunter has a direct line of sight to the mimic.
local function HasLoSToAnyHunter(ent)
  for _, ply in ipairs(team.GetPlayers(TEAM_HUNTERS)) do
    if IsValid(ply) and ply:Alive() then
      local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ent:WorldSpaceCenter(),
        filter = {ply, ent},
        mask = MASK_VISIBLE_AND_NPCS
      })
      if not tr.Hit then return true end -- No hit means clear line of sight
    end
  end
  return false
end

function ENT:Think()
  local owner = self:GetOwner()
  if IsValid(owner) and owner:IsPlayer() then
    -- Make the mimic entity follow its player/owner
    self:SetPos(owner:GetPos())
    self:SetAngles(owner:GetAngles())
    self:SetMoveType(MOVETYPE_STEP)
  else
    self:SetMoveType(MOVETYPE_VPHYSICS)
  end


  -- Freeze if seen by any hunter (or forced via cvar for single-PC tests)
  local isSeen = (mh_cvar_force_seen and mh_cvar_force_seen:GetBool()) or HasLoSToAnyHunter(self)
  self:SetSeen(isSeen)

  -- If the entity is being controlled by a player, freeze them too.
  if isSeen and IsValid(owner) and owner:IsPlayer() then
      owner:SetMaxSpeed(0.1)
  elseif IsValid(owner) and owner:IsPlayer() then
      owner:SetMaxSpeed(owner:GetRunSpeed())
  end

  self:NextThink(CurTime() + 0.1) -- Check every 100ms
  return true
end


util.AddNetworkString("mh_disguise")
net.Receive("mh_disguise", function(len, ply)
  -- The player (ply) who sent this is a mimic and wants to disguise.
  if not IsValid(ply) or ply:Team() ~= TEAM_MIMICS then return end

  -- The entity they control is their character.
  local mimic_ent = ply:GetObserverTarget()
  if not IsValid(mimic_ent) or mimic_ent:GetClass() ~= "ent_mimic" then
    -- Fallback for the player model approach
    mimic_ent = ply
  end

  -- Perform a trace to see what the player is looking at
  local tr = ply:GetEyeTrace()
  if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_physics" and tr.HitPos:DistToSqr(ply:GetShootPos()) < 200*200 then
    mimic_ent:SetModel(tr.Entity:GetModel())
    mimic_ent:SetSkin(tr.Entity:GetSkin() or 0)
    -- Align the mimic to the player's direction, but flat on the ground.
    mimic_ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
  end
end)
