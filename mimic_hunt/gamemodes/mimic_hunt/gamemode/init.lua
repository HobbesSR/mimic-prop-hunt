AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- Helper function to get all living players on a team
local function AlivePlayers(teamid)
  local t = {}
  for _,p in ipairs(team.GetPlayers(teamid)) do
    if IsValid(p) and p:Alive() then t[#t+1]=p end
  end
  return t
end

-- Called when the gamemode is initialized
function GM:Initialize()
  self.BaseClass.Initialize(self)
  self:StartRound()
end

-- Starts a new round
function GM:StartRound()
  SetGlobalInt("mh_round", ROUND_WAIT)
  PrintMessage(HUD_PRINTTALK, "Round starting in "..MH_Config.setup_time.." seconds...")

  -- Start the playing phase after a setup timer
  timer.Simple(MH_Config.setup_time, function()
    if not self or not GAMEMODE then return end
    SetGlobalInt("mh_round", ROUND_PLAY)
    SetGlobalFloat("mh_round_ends", CurTime() + MH_Config.round_time)
    PrintMessage(HUD_PRINTTALK, "Round started! Mimics are hiding.")
  end)
end

-- This hook is called every frame
hook.Add("Think", "mh_round_watch", function()
  if GetGlobalInt("mh_round") ~= ROUND_PLAY then return end

  -- Check for win conditions
  local hunters = AlivePlayers(TEAM_HUNTERS)
  local mimics  = AlivePlayers(TEAM_MIMICS)

  if #mimics == 0 then
    GAMEMODE:EndRound("Hunters")
  elseif #hunters == 0 then
    GAMEMODE:EndRound("Mimics")
  elseif CurTime() >= GetGlobalFloat("mh_round_ends") then
    GAMEMODE:EndRound("Mimics") -- Mimics win if time runs out
  end
end)

-- Ends the current round
function GM:EndRound(winner)
  SetGlobalInt("mh_round", ROUND_POST)
  PrintMessage(HUD_PRINTTALK, winner.." win!")

  -- Restart the round after a short delay
  timer.Simple(8, function()
    if GAMEMODE then GAMEMODE:StartRound() end
  end)
end

-- Called when a player spawns
function GM:PlayerSpawn(ply)
  -- Assign player to a team if they don't have one
  if ply:Team() == TEAM_UNASSIGNED then
    if (team.NumPlayers(TEAM_MIMICS) * 3) < team.NumPlayers(TEAM_HUNTERS) then
      ply:SetTeam(TEAM_MIMICS)
    else
      ply:SetTeam(TEAM_HUNTERS)
    end
  end

  -- Give players their respective loadouts and properties
  if ply:Team() == TEAM_HUNTERS then
    ply:StripWeapons()
    ply:Give("weapon_smg1")
    ply:GiveAmmo(60, "SMG1", true)
    ply:SetRunSpeed(320)
    ply:SetWalkSpeed(160)
    ply:SetModel("models/player/group03/male_07.mdl") -- Reset model
  elseif ply:Team() == TEAM_MIMICS then
    ply:StripWeapons()

    -- Spawn an ent_mimic for the player to control
    local mimic = ents.Create("ent_mimic")
    if not IsValid(mimic) then return end

    mimic:SetPos(ply:GetPos() + Vector(0, 0, 5))
    mimic:SetAngles(ply:GetAngles())
    mimic:SetOwner(ply)
    mimic:Spawn()

    -- Make the player control the mimic
    ply:Spectate(OBS_MODE_IN_EYE)
    ply:SpectateEntity(mimic)
    ply:SetRunSpeed(240) -- Speed for when controlling the mimic
    ply:SetWalkSpeed(120)
  end
end
