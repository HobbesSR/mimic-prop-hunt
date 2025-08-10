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
