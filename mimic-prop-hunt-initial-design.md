Perfect—Garry’s Mod is great for this. Here’s the fastest path to a working “reverse prop hunt (mimics hunt humans)” prototype you can iterate on with an AI agent.

# Evening-1 Plan (from zero to playable loop)

## 0) Setup (10–15 min)

* Install **Garry’s Mod** + **Garry’s Mod Dedicated Server** (for fast reloads).
* Editor: **VS Code** + **Lua Language Server**.
* Enable dev goodies: launch with `-condebug -console -insecure -allowlocalhttp` (helps debugging; safe for local).

## 1) Create a gamemode skeleton (5 min)

File tree (put under `garrysmod/addons/mimic_hunt/`):

```
mimic_hunt/
  addon.json
  gamemodes/mimic_hunt/
    gamemode/
      init.lua        -- server logic
      cl_init.lua     -- client HUD/FX
      shared.lua      -- teams, config
    content/          -- sounds, materials
    entities/
      entities/ent_mimic/
        init.lua
        shared.lua
        cl_init.lua
```

`addon.json` minimal:

```json
{"title":"Mimic Hunt","type":"gamemode","tags":["gameplay","asymmetric"],"ignore":[".git/"]}
```

## 2) Define teams & round state (15 min)

`shared.lua` (minimal sketch):

```lua
GM.Name    = "Mimic Hunt"
GM.Author  = "You"
TEAM_HUNTERS = 1
TEAM_MIMICS  = 2

function GM:CreateTeams()
  team.SetUp(TEAM_HUNTERS, "Hunters", Color(80,160,255))
  team.SetUp(TEAM_MIMICS,  "Mimics",  Color(180,120,255))
end

ROUND_WAIT, ROUND_PLAY, ROUND_POST = 0,1,2
SetGlobalInt("mh_round", ROUND_WAIT)

MH_Config = {
  round_time = 300,
  setup_time = 20,
  mimic_move_cone_deg = 2,   -- allowed movement if "unseen"
}
```

## 3) Core loop (setup → play → post) (25–40 min)

`init.lua` (server):

```lua
AddCSLuaFile("cl_init.lua"); AddCSLuaFile("shared.lua")
include("shared.lua")

local function AlivePlayers(teamid)
  local t = {}
  for _,p in ipairs(team.GetPlayers(teamid)) do
    if IsValid(p) and p:Alive() then t[#t+1]=p end
  end
  return t
end

function GM:Initialize()
  self.BaseClass.Initialize(self)
  self:StartRound()
end

function GM:StartRound()
  SetGlobalInt("mh_round", ROUND_WAIT)
  timer.Simple( MH_Config.setup_time, function()
    if not self then return end
    SetGlobalInt("mh_round", ROUND_PLAY)
    SetGlobalFloat("mh_round_ends", CurTime()+MH_Config.round_time)
  end)
end

hook.Add("Think","mh_round_watch",function()
  if GetGlobalInt("mh_round") ~= ROUND_PLAY then return end
  -- win checks
  local hunters = AlivePlayers(TEAM_HUNTERS)
  local mimics  = AlivePlayers(TEAM_MIMICS)
  if #hunters == 0 then GAMEMODE:EndRound("Mimics") end
  if CurTime() >= GetGlobalFloat("mh_round_ends") then GAMEMODE:EndRound("Hunters") end
end)

function GM:EndRound(winner)
  SetGlobalInt("mh_round", ROUND_POST)
  PrintMessage(HUD_PRINTTALK, winner.." win!")
  timer.Simple(8,function() if GAMEMODE then GAMEMODE:StartRound() end end)
end
```

## 4) Mimic entity (the disguise + movement-in-sight rule) (45–60 min)

* **Spawn as Mimic**: players on TEAM\_MIMICS become `ent_mimic`.
* **Disguise**: on use, copy a prop’s model/skin/bodygroups.
* **Movement constraint**: if any hunter has line of sight to you (trace from hunter eyes to mimic), your speed drops to 0 (or you “freeze”).

`entities/entities/ent_mimic/shared.lua`

```lua
ENT.Type = "anim"; ENT.Base = "base_anim"
ENT.PrintName = "Mimic"; ENT.RenderGroup = RENDERGROUP_OPAQUE
```

`entities/entities/ent_mimic/init.lua`

```lua
AddCSLuaFile("cl_init.lua"); AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
  self:SetModel("models/props_c17/oildrum001.mdl")
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_STEP)
  self:SetSolid(SOLID_BBOX)
  self:SetHealth(100)
end

local function HasLoSToAnyHunter(ent)
  for _, ply in ipairs(team.GetPlayers(TEAM_HUNTERS)) do
    if IsValid(ply) and ply:Alive() then
      local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ent:WorldSpaceCenter(),
        filter = {ply, ent},
        mask = MASK_VISIBLE_AND_NPCS
      })
      if not tr.Hit then return true end
    end
  end
  return false
end

function ENT:Think()
  -- freeze if seen
  self.Seen = HasLoSToAnyHunter(self)
  self:SetNWBool("mh_seen", self.Seen)
  self:NextThink(CurTime()+0.05)
  return true
end

util.AddNetworkString("mh_disguise")
net.Receive("mh_disguise", function(len, ply)
  local ent = net.ReadEntity()
  if not IsValid(ply) or not IsValid(ent) then return end
  if ply:Team() ~= TEAM_MIMICS then return end
  local tr = ply:GetEyeTrace()
  if IsValid(tr.Entity) and tr.Entity:GetClass()=="prop_physics" and tr.HitPos:DistToSqr(ply:GetShootPos()) < 200*200 then
    ent:SetModel(tr.Entity:GetModel())
    ent:SetSkin(tr.Entity:GetSkin() or 0)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
  end
end)
```

`entities/entities/ent_mimic/cl_init.lua`

```lua
include("shared.lua")
function ENT:Draw()
  self:DrawModel()
  if self:GetNWBool("mh_seen") then
    cam.Start3D2D(self:WorldSpaceCenter()+Vector(0,0,30), Angle(0,LocalPlayer():EyeAngles().y,90), 0.1)
      draw.SimpleText("!", "DermaLarge", 0,0, Color(255,80,80), TEXT_ALIGN_CENTER)
    cam.End3D2D()
  end
end
```

## 5) Player spawning & roles (10–15 min)

* On round start: split players \~30% mimics, 70% hunters.
* Hunters get a weak SMG + **“Ping grenade”** (emits a radius twitch on mimics).
* Mimics spawn as an `ent_mimic` they control (parent the entity or replace player model with nextbot-like control—start simple: keep them as players but lock animations and visually set to prop with `SetModel`).

Quick sketch in `init.lua`:

```lua
function GM:PlayerSpawn(ply)
  if ply:Team()==TEAM_UNASSIGNED then
    if (team.NumPlayers(TEAM_MIMICS) * 3) < team.NumPlayers(TEAM_HUNTERS) then
      ply:SetTeam(TEAM_MIMICS) else ply:SetTeam(TEAM_HUNTERS)
    end
  end
  if ply:Team()==TEAM_HUNTERS then
    ply:Give("weapon_smg1"); ply:GiveAmmo(60,"SMG1",true)
  else
    -- disguise as a random nearby prop at spawn time, or give a “Disguise” bind
    ply:SetModel("models/props_c17/oildrum001.mdl")
    ply:SetRunSpeed(240); ply:SetWalkSpeed(120)
  end
end
```

## 6) Two hallmark mechanics for your twist (1–2 hrs)

* **Freeze-on-sight** (done above).
* **Paranoia meter (client)**: staring at a prop increases a bar; high paranoia adds aim sway and occasional false “twitch” cues.
* **Ping grenade (hunter tool)**: on detonate, send `net` message to clients in radius to play a 1–2 frame model jiggle on mimics.

## 7) Fast iteration loop for an AI agent

* **Headless testing**: run `srcds` with your gamemode and `+bot_mimics 8` (write a simple Lua hook to spawn dumb mimic bots that wander when unseen).
* **Hot reload**: GMod reloads Lua on `lua_openscript*` and map changes; keep cycles tight: `map gm_construct` → test → `lua_openscript` changed file.
* **Test scripts**: add a `mh_dev.lua` that seeds 2 hunters + 4 mimics, equips gear, and prints round state so an AI can validate expected events (“mimic frozen when seen,” “ping grenade causes twitch,” etc.).

## 8) Packaging & quick playtests

* Keep it as a local addon until the loop feels good.
* When ready, use `gmad` → upload to Workshop (optional).
* Invite 2–3 friends: your loop reveals balance flaws immediately (mimics too mobile? hunters too ammo-starved?).

# What to build next (small, high-impact)

1. **Objective loop**: Hunters must fetch 3 fuses and start an extractor for win; forces risky prop interaction.
2. **Feign-Death**: Mimic can toggle “ruined prop” look; when looted by hunter → spring attack.
3. **Cluster camouflage bonus**: If mimic model matches ≥2 nearby identical props → reduce ping twitch or extend move window by 0.5s.

# Want me to scaffold this?

I can spin up the **folder skeleton + stub files** and wire the freeze-on-sight + basic round flow so you can drop it into `addons/` and hit play. If that’s useful, say the word and I’ll generate the starter pack.
