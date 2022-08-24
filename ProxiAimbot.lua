--[[
	https://github.com/leme6156/proxi-stuff

	Features:
		- Engine Prediction
		- Auto shoot
		- Anti Spread
		- Anti Recoil
		- Silent Aim
		- Bullettime
		- Movement fix
		- Backtrack (0.2 seconds by default, changing this might introduce jank)
		- No lerp
		- Buildmode checks
		- Godmode checks
		- HvHmode checks
		- Anti gesture
		- Basic corner multipoint for either head only or all hitboxes

	ConVars:
		pa_debug					-	Controls debug mode					(Default: 0)
		pa_animlerp					-	Conrtols animation lerp				(Default: 1)
		pa_enabled					-	Controls aimbot state				(Default: 1)
		pa_key						-	Sets aimbot key						(Default: MOUSE_5 (111))
		pa_fov						-	Sets aimbot FOV						(Default: 16)
		pa_silent					-	Controls silent aim					(Default: 1)
		pa_bullettime				-	Controls waiting for weapon fire	(Default: 1)
		pa_fix_movement				-	Controls movement fix				(Default: 1)
		pa_anti_spread				-	Controls anti spread				(Default: 1)
		pa_anti_recoil				-	Controls anti recoil				(Default: 1)
		pa_auto_shoot				-	Controls auto shoot					(Default: 1)
		pa_backtrack				-	Controls backtrack					(Default: 1)
		pa_backtrack_limit			-	Controls backtrack amount (seconds)	(Default: 0.2)
		pa_antigesture				-	Controls anti gesture				(Default: 0)
		pa_multipoint				-	Controls mutlipoint					(Default: 1)
		pa_multipoint_everything	-	Controls multipointing every hitbox	(Default: 0)

	ConCommands:
		pa_menu						-	Opens the menu

	Requires proxi (Duh)
	Requires https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/Includes/modules/md5.lua (Anti Spread)
	Requires https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/vgui/dsection.lua (For the menu)
]]

local IsIdiot = false
xpcall(function() require("proxi") end, function() IsIdiot = true end)
if IsIdiot or proxi == nil then MsgC(Color(255, 0, 0), ("YOU DON'T HAVE PROXI YOU DUMBASS IDIOT\n"):rep(420)) return else IsIdiot = nil end

jit.flush() -- Wat da

pcall(include, "includes/modules/md5.lua")
pcall(include, "vgui/dsection.lua")

--------------------------- Localization ---------------------------

local meta_cl = proxi._R.Color

local FRAME_NET_UPDATE_START = proxi.FRAME_NET_UPDATE_START
local FRAME_NET_UPDATE_END = proxi.FRAME_NET_UPDATE_END

local GESTURE_SLOT_VCD = GESTURE_SLOT_VCD
local HITGROUP_CHEST = HITGROUP_CHEST
local HITGROUP_HEAD = HITGROUP_HEAD
local HITGROUP_STOMACH = HITGROUP_STOMACH
local IN_ATTACK = IN_ATTACK
local IN_USE = IN_USE
local KEY_COUNT = KEY_COUNT
local MASK_SHOT = MASK_SHOT
local MOUSE_5 = MOUSE_5
local OBS_MODE_NONE = OBS_MODE_NONE
local TEAM_SPECTATOR = TEAM_SPECTATOR

local Angle = Angle
local Color = Color
local CreateClientConVar = CreateClientConVar
local CurTime = CurTime
local IsValid = IsValid
local LocalPlayer = LocalPlayer
local ScrH = ScrH
local ScrW = ScrW
local Vector = Vector
local ipairs = ipairs
local print = print
local setmetatable = setmetatable
local tobool = tobool

local player_GetAll = player.GetAll

local math_Clamp = math.Clamp
local math_Distance = math.Distance
local math_NormalizeAngle = math.NormalizeAngle
local math_abs = math.abs
local math_acos = math.acos
local math_atan = math.atan
local math_cos = math.cos
local math_deg = math.deg
local math_huge = math.huge
local math_pi = math.pi
local math_rad = math.rad
local math_sin = math.sin
local math_sqrt = math.sqrt
local math_tan = math.tan

local math_pi_180 = math_pi / 180

local input_IsButtonDown = input.IsButtonDown

local surface_DrawCircle = surface.DrawCircle
local surface_DrawPoly = surface.DrawPoly
local surface_SetDrawColor = surface.SetDrawColor

local draw_NoTexture = draw.NoTexture

local string_Split = string.Split
local string_ToColor = string.ToColor
local string_lower = string.lower

local cvars_AddChangeCallback = cvars.AddChangeCallback

local hook_Run = hook.Run
local hook_Add = hook.Add

local timer_Create = timer.Create

local table_GetKeys = table.GetKeys
local table_remove = table.remove

local util_TraceLine = util.TraceLine

local vgui_Create = vgui.Create

local NULL = NULL
local angle_zero = Angle(0, 0, 0)

--------------------------- le stuffs ---------------------------

local pGetConVar = proxi.GetConVar
local pStartPrediction = proxi.StartPrediction
local pEndPrediction = proxi.EndPrediction
local pDisableAnimInterp = proxi.DisableAnimInterp
local pSetInterpolationEnabled = proxi.SetInterpolationEnabled

local Cache = {
	TickInterval = engine.TickInterval(),

	ScrW = ScrW(),
	ScrH = ScrH(),

	LocalPlayer = LocalPlayer(),
	FacingAngle = LocalPlayer():EyeAngles(),

	Menu = nil,

	Colors = {
		White = Color(255, 255, 255, 255),
		Black = Color(0, 0, 0, 255),

		FOV = {
			Outline = Color(255, 255, 255, 255),
		}
	},

	CalcViewData = {
		origin = LocalPlayer():EyePos(),
		angles = LocalPlayer():EyeAngles(),
		fov = LocalPlayer():GetFOV(),
		znear = 3
	},

	ConVars = {
		m_pitch = pGetConVar("m_pitch"),
		m_yaw = pGetConVar("m_yaw"),

		cl_drawhud = pGetConVar("cl_drawhud"),
		cl_interp = pGetConVar("cl_interp"),
		cl_interpolate = pGetConVar("cl_interpolate"),

		fov_desired = pGetConVar("fov_desired"),

		Aimbot = {
			DEBUGMODE = CreateClientConVar("pa_debug", 0, false, false, "", 0, 1),
			
			AnimLerp = CreateClientConVar("pa_animlerp", 1, true, false, "", 0, 1),

			Enabled = CreateClientConVar("pa_enabled", 1, true, false, "", 0, 1),
			Key = CreateClientConVar("pa_key", MOUSE_5, true, false, "", 0, math.huge), -- Shitass KEY_COUNT isn't even close to the real number

			FOV = CreateClientConVar("pa_fov", 16, true, false, "", 0, 180),
			Silent = CreateClientConVar("pa_silent", 1, true, false, "", 0, 1),
			Bullettime = CreateClientConVar("pa_bullettime", 1, true, false, "", 0, 1),
			FixMovement = CreateClientConVar("pa_fix_movement", 1, true, false, "", 0, 1),
			AntiSpread = CreateClientConVar("pa_anti_spread", 1, true, false, "", 0, 1),
			AntiRecoil = CreateClientConVar("pa_anti_recoil", 1, true, false, "", 0, 1),
			AutoShoot = CreateClientConVar("pa_auto_shoot", 1, true, false, "", 0, 1),
			Backtrack = CreateClientConVar("pa_backtrack", 1, true, false, "", 0, 1),
			BacktrackAmount = CreateClientConVar("pa_backtrack_limit", 0.2, true, false, "", 0, 1), -- In SECONDS
			AntiGesture = CreateClientConVar("pa_antigesture", 0, true, false, "", 0, 1),
			MultiPoint = CreateClientConVar("pa_multipoint", 1, true, false, "", 0, 1),
			MultiPointAll = CreateClientConVar("pa_multipoint_everything", 0, true, false, "", 0, 1),

			FOVOutline = CreateClientConVar("pa_fov_color_outline", "255 255 255 255", true, false, "")
		}
	},

	NetVars = {
		BuildMode = {
			"BuildMode", -- Libby's
			"buildmode", -- Fun Server
			"_Kyle_Buildmode", -- Workshop addon
			"BuildMode"
		},

		GodMode = {
			"has_god" -- Fun Server + LBG
		},

		HvHMode = {
			"HVHER" -- Fun Server + LBG
		},

		Protected = {
			"LibbyProtectedSpawn", -- Libby's
			"SH_SZ.Safe" -- Safezone addon (Used by LBG)
		}
	},

	WeaponData = {
		BlacklistClasses = {
			"bomb",
			"c4",
			"climb",
			"fist",
			"gravity gun",
			"grenade",
			"hand",
			"ied",
			"knife",
			"physics gun",
			"slam",
			"sword",
			"tool gun"
		},

		WhitelistClasses = {
			"handgun"
		},

		ShootChecks = {
			bobs = function(Weapon) -- M9K
				if not IsValid(Weapon) then return false end
			
				if not Weapon.Owner:IsPlayer() then return false end
				if Weapon.Owner:KeyDown(IN_SPEED) or Weapon.Owner:KeyDown(IN_RELOAD) then return false end
				if Weapon:GetNWBool("Reloading", false) then return false end
				if Weapon:Clip1() < 1 then return false end
			
				return true
			end,
			
			cw = function(Weapon)
				if not IsValid(Weapon) then return false end
			
				if not Weapon:canFireWeapon(1) or not Weapon:canFireWeapon(2) or not Weapon:canFireWeapon(3) then return false end
				if Weapon.Owner:KeyDown(IN_USE) and CustomizableWeaponry.quickGrenade.canThrow(Weapon) then return false end
				if Weapon.dt.State == CW_AIMING and Weapon.dt.M203Active and Weapon.M203Chamber then return false end
				if Weapon.dt.Safe then return false end
				if Weapon:Clip1() == 0 then return false end
				if Weapon.BurstAmount and Weapon.BurstAmount > 0 then return false end
			
				return true
			end,
			
			fas2 = function(Weapon)
				if not IsValid(Weapon) then return false end
			
				if Weapon.FireMode == "safe" then return false end
				if Weapon.BurstAmount > 0 and Weapon.dt.Shots >= Weapon.BurstAmount then return false end
				if Weapon.ReloadState ~= 0 then return false end
				if Weapon.dt.Status == FAS_STAT_CUSTOMIZE then return false end
				if Weapon.Cooking or Weapon.FuseTime then return false end
				if Weapon.Owner:KeyDown(IN_USE) and Weapon:CanThrowGrenade() then return false end
				if Weapon.dt.Status == FAS_STAT_SPRINT or Weapon.dt.Status == FAS_STAT_QUICKGRENADE then return false end
				if Weapon:Clip1() <= 0 or Weapon.Owner:WaterLevel() >= 3 then return false end
				if Weapon.CockAfterShot and not Weapon.Cocked then return false end
			
				return true
			end,
			
			tfa = function(Weapon)
				if not IsValid(Weapon) then return false end
			
				local Weapon2 = Weapon:GetTable()
			
				local v = hook_Run("TFA_PreCanPrimaryAttack", Weapon)
				if v ~= nil then return v end
			
				local stat = Weapon:GetStatus()
				if stat == TFA.Enum.STATUS_RELOADING_WAIT or stat == TFA.Enum.STATUS_RELOADING then return false end
			
				if Weapon:IsSafety() then return false end
				if Weapon:GetSprintProgress() >= 0.1 and not Weapon:GetStatL("AllowSprintAttack", false) then return false end
				if Weapon:GetStatL("Primary.ClipSize") <= 0 and Weapon:Ammo1() < Weapon:GetStatL("Primary.AmmoConsumption") then return false end
				if Weapon:GetPrimaryClipSize(true) > 0 and Weapon:Clip1() < Weapon:GetStatL("Primary.AmmoConsumption") then return false end
				if Weapon2.GetStatL(Weapon, "Primary.FiresUnderwater") == false and Weapon:GetOwner():WaterLevel() >= 3 then return false end
			
				v = hook_Run("TFA_CanPrimaryAttack", self)
				if v ~= nil then return v end
			
				if Weapon:CheckJammed() then return false end
			
				return true
			end,
			
			arccw = function(Weapon)
				if not IsValid(Weapon) then return false end
			
				if IsValid(Weapon:GetHolster_Entity()) then return false end
				if Weapon:GetHolster_Time() > 0 then return false end
				if Weapon:GetReloading() then return false end
				if Weapon:GetWeaponOpDelay() > CurTime() then return false end
				if Weapon:GetHeatLocked() then return false end
				if Weapon:GetState() == ArcCW.STATE_CUSTOMIZE then return false end
				if Weapon:BarrelHitWall() > 0 then return false end
				if Weapon:GetNWState() == ArcCW.STATE_SPRINT and not (Weapon:GetBuff_Override("Override_ShootWhileSprint", Weapon.ShootWhileSprint)) then return false end
				if (Weapon:GetBurstCount() or 0) >= Weapon:GetBurstLength() then return false end
				if Weapon:GetNeedCycle() then return false end
				if Weapon:GetCurrentFiremode().Mode == 0 then return false end
				if Weapon:GetBuff_Override("Override_TriggerDelay", Weapon.TriggerDelay) and Weapon:GetTriggerDelta() < 1 then return false end
				if Weapon:GetBuff_Hook("Hook_ShouldNotFire") then return false end
				if Weapon:GetBuff_Hook("Hook_ShouldNotFireFirst") then return false end
			
				return true
			end
		},

		SpreadCones = {}
	},

	AimbotData = {
		Angle = LocalPlayer():EyeAngles(),
		Active = false,
		Target = NULL,
		FOVPoly = nil,

		ScanOrder = {
			HITGROUP_HEAD,
			HITGROUP_CHEST,
			HITGROUP_STOMACH
		},

		Backtrack = {}
	},

	HitgroupTranslation = {
		[HITGROUP_GENERIC] = "HITGROUP_GENERIC",
		[HITGROUP_HEAD] = "HITGROUP_HEAD",
		[HITGROUP_CHEST] = "HITGROUP_CHEST",
		[HITGROUP_STOMACH] = "HITGROUP_STOMACH",
		[HITGROUP_LEFTARM] = "HITGROUP_LEFTARM",
		[HITGROUP_RIGHTARM] = "HITGROUP_RIGHTARM",
		[HITGROUP_LEFTLEG] = "HITGROUP_LEFTLEG",
		[HITGROUP_RIGHTLEG] = "HITGROUP_RIGHTLEG"
	},

	Players = {}
}

--------------------------- Functions ---------------------------

local function GetViewOrigin()
	return Cache.CalcViewData.origin
end

local function GetViewAngles()
	return Cache.CalcViewData.angles
end

local function GetViewFOV()
	return Cache.CalcViewData.fov
end

local function GetViewZNear()
	return Cache.CalcViewData.znear
end

local function GetFOVRadius()
    local Max = Cache.ConVars.Aimbot.FOV:GetInt()
    
    local Ratio = Cache.ScrW / Cache.ScrH

    local AimFOV = Max * math_pi_180
    local GameFOV = GetViewFOV() * math_pi_180
    local ViewFOV = 2 * math_atan(Ratio * (GetViewZNear() / 2) * math_tan(GameFOV / 2))

    return (math_tan(AimFOV) / math_tan(ViewFOV * 0.5)) * Cache.ScrW
end

local function AngleOutOfRange(Angle)
	return Angle.pitch > 89 or Angle.pitch < -89 or Angle.yaw > 180 or Angle.yaw < -180 or Angle.roll > 180 or Angle.roll < -180
end

local function FixAngle(Angle) -- Fixes an angle to only be what a player's eye angles can be normally
	if not AngleOutOfRange(Angle) then return end

	Angle.pitch = math_Clamp(math_NormalizeAngle(Angle.pitch), -89, 89)
	Angle.yaw = math_NormalizeAngle(Angle.yaw)
	Angle.roll = math_NormalizeAngle(Angle.roll)
end

local function GetEntitySimTime(Entity)
	return proxi.__Ent_GetNetVar(Entity, "DT_BaseEntity->m_flSimulationTime", 1)
end

local function ValidEntity(Entity)
	if not IsValid(Entity) then
		return false
	end

	return Entity ~= Cache.LocalPlayer and Entity:Alive() and Entity:Team() ~= TEAM_SPECTATOR and Entity:GetObserverMode() == OBS_MODE_NONE and not Entity:IsDormant()
end

local function TimeToTick(Time)
	return math.floor(0.5 + (Time / Cache.TickInterval))
end

local function TickToTime(Tick)
	return Cache.TickInterval * Tick
end

local function GetServerTime()
	return TickToTime(Cache.LocalPlayer:GetInternalVariable("m_nTickBase"))
end

local function UpdateCalcViewData(View)
	Cache.CalcViewData.origin = View.origin * 1
	Cache.CalcViewData.angles = View.angles * 1
	Cache.CalcViewData.fov = View.fov
	Cache.CalcViewData.znear = View.znear
end

local function PlayerInBuildMode(Player)
	for _, v in ipairs(Cache.NetVars.BuildMode) do
		if Player:GetNWBool(v, false) then
			return true
		end
	end

	return false
end

local function PlayerInGodMode(Player)
	if Player:HasGodMode() then return true end

	for _, v in ipairs(Cache.NetVars.GodMode) do
		if Player:GetNWBool(v, false) then
			return true
		end
	end

	return false
end

local function PlayerInOpposingHVHMode(Player)
	local LocalHvH = false
	local PlayerHvH = false

	for _, v in ipairs(Cache.NetVars.HvHMode) do
		if LocalHvH and PlayerHvH then break end

		LocalHvH = Cache.LocalPlayer:GetNWBool(v, false)
		PlayerHvH = Player:GetNWBool(v, false)
	end

	return LocalHvH ~= PlayerHvH
end

local function PlayerIsProtected(Player)
	for _, v in ipairs(Cache.NetVars.Protected) do
		if tobool(Player:GetNWInt(v)) then -- This check has to be done a little differently because of how safezones work
			return true
		end
	end

	return false
end

local function CalculateViewPunch(Weapon)
	return Weapon:IsScripted() and angle_zero or Cache.LocalPlayer:GetViewPunchAngles()
end

local function CalculateNoSpread(Weapon, cmd, pAngle)
	if not Cache.ConVars.Aimbot.AntiSpread:GetBool() then return pAngle end

	if Weapon:IsScripted() then
		cmd:SetRandomSeed(33)
		return pAngle
	end

	local WeaponCone = Cache.WeaponData.SpreadCones[Weapon:GetClass()]

	if not md5 or not WeaponCone then
		return pAngle
	end

	local Seed = cmd:GetRandomSeed()

	local X = md5.EngineSpread[Seed][1]
	local Y = md5.EngineSpread[Seed][2]

	local Forward = pAngle:Forward()
	local Right = pAngle:Right()
	local Up = pAngle:Up()

	local SpreadVector = Forward + (X * WeaponCone.x * Right * -1) + (Y * WeaponCone.y * Up * -1)
	local SpreadAngle = SpreadVector:Angle()
	SpreadAngle:Normalize()

	return SpreadAngle
end

local function GetWeaponBase(Weapon)
	if not Weapon.Base then return "" end

	return string_Split(string_lower(Weapon.Base), "_")[1]
end

local function WeaponCanShoot(Weapon)
	if not Cache.ConVars.Aimbot.Bullettime:GetBool() then return true end

	local WeaponName = string_lower(Weapon:GetPrintName())

	for _, v in ipairs(Cache.WeaponData.BlacklistClasses) do
		if WeaponName == v then return false end

		if WeaponName:find(v) then
			local breakouter = false

			for _, t in ipairs(Cache.WeaponData.WhitelistClasses) do
				if WeaponName:find(t) then
					breakouter = true
					break
				end
			end

			if breakouter then continue end

			return false
		end
	end

	local Base = GetWeaponBase(Weapon)
	local ExtraCheck = Cache.WeaponData.ShootChecks[Base] and Cache.WeaponData.ShootChecks[Base](Weapon) or true

	return GetServerTime() >= Weapon:GetNextPrimaryFire() and ExtraCheck
end

local function DistanceFromCrosshair(Pos)
	if not Pos then return 360 end

	local sPos = Pos:ToScreen()
	local pRad = GetFOVRadius()

	if sPos.visible and pRad >= 0 then -- W2S is slightly more precise in some cases
		return math_Distance(Cache.ScrW / 2, Cache.ScrH / 2, sPos.x, sPos.y), true
	else
		local Forward = Cache.FacingAngle:Forward()
		local Distance = (Pos - Cache.LocalPlayer:EyePos()):GetNormalized()

		local Degree = math_deg(math_acos(Forward:Dot(Distance)))
		return math_abs(Degree), false
	end
end

local function PosInFOV(Pos)
	local Dist, WasW2S = DistanceFromCrosshair(Pos)

	if WasW2S then
		local pRad = GetFOVRadius()
		return Dist <= (pRad < 0 and Dist or pRad)
	else
		return Dist <= Cache.ConVars.Aimbot.FOV:GetInt()
	end
end

local function IsVisible(Pos, Entity)
	local tr = util_TraceLine({
		start = Cache.LocalPlayer:EyePos(),
		endpos = Pos,
		filter = Cache.LocalPlayer,
		mask = MASK_SHOT
	})

	if IsValid(Entity) then
		return tr.Entity == Entity, tr.Fraction
	end
end

local function GetAimTarget()
	local AMax = Cache.ConVars.Aimbot.FOV:GetInt()
	local WMax = GetFOVRadius()

	local Best = math_huge
	local Entity = NULL

	for _, v in ipairs(Cache.Players) do
		if not ValidEntity(v) then continue end
		if PlayerInBuildMode(v) or PlayerInGodMode(v) or PlayerInOpposingHVHMode(v) or PlayerIsProtected(v) then continue end -- Don't bother scanning these players

		local Cur, WasW2S = DistanceFromCrosshair(v:WorldSpaceCenter())

		if Cur <= (WasW2S and WMax or AMax) and Cur < Best then -- Adjust check for W2S
			Best = Cur
			Entity = v
		end

		if Cache.ConVars.Aimbot.Backtrack:GetBool() and Cache.AimbotData.Backtrack[v] then -- Best table organization you've ever seen
			for _, h in ipairs(Cache.AimbotData.Backtrack[v]) do
				for _, Set in ipairs(Cache.AimbotData.ScanOrder) do
					if not h.hData[Set] then continue end

					for _, hPos in ipairs(h.hData[Set]) do
						Cur, WasW2S = DistanceFromCrosshair(hPos)

						if Cur > (WasW2S and WMax or AMax) then continue end

						local Visible, Fr = IsVisible(hPos, v)
						if not Visible then continue end

						if Cur < Best then -- Breaks priority a little bit but it's better than randomly aiming at body
							return v, hPos, h.Tick, Set, Fr
						end
					end
				end
			end
		end
	end

	return Entity
end

local function GenerateMultiPoints(Pos, Ang, Mins, Maxs)
	-- Inset points a little for accuracy

	local pMins = Vector(Mins.x + 1, Mins.y + 1, Mins.z + 1)
	local pMaxs = Vector(Maxs.x - 1, Maxs.y - 1, Maxs.z - 1)

	local MP = {}

	-- Who needs auto generation when you have swag

	MP[1] = pMins * 1
	MP[2] = pMaxs * 1
	MP[3] = Vector(pMins.x, pMins.y, pMaxs.z)
	MP[4] = Vector(pMaxs.x, pMins.y, pMaxs.z)
	MP[5] = Vector(pMaxs.x, pMaxs.y, pMins.z)
	MP[6] = Vector(pMaxs.x, pMins.y, pMins.z)
	MP[7] = Vector(pMins.x, pMaxs.y, pMins.z)
	MP[8] = Vector(pMins.x, pMaxs.y, pMaxs.z)

	for i = 1, #MP do
		MP[i]:Rotate(Ang) -- Make the multipoints follow the hitbox's rotation
		MP[i] = MP[i] + Pos -- Move them into position from world origin
	end

	return MP
end

local function GetEntityHitboxes(Entity)
	local DoMP = Cache.ConVars.Aimbot.MultiPoint:GetBool()
	local DoMPAll = Cache.ConVars.Aimbot.MultiPointAll:GetBool()

	local hData = {}

	Entity:SetupBones() -- Blah

	for HitSet = 0, Entity:GetHitboxSetCount() - 1 do
		for HitBox = 0, Entity:GetHitBoxCount(HitSet) - 1 do
			local HitGroup = Entity:GetHitBoxHitGroup(HitBox, HitSet)
			if not HitGroup then continue end

			hData[HitGroup] = hData[HitGroup] or {}

			local Bone = Entity:GetHitBoxBone(HitBox, HitSet)
			local Mins, Maxs = Entity:GetHitBoxBounds(HitBox, HitSet)
			if not Bone or not Mins or not Maxs then continue end

			local bMatrix = Entity:GetBoneMatrix(Bone)
			if not bMatrix then continue end

			local Pos, Ang = bMatrix:GetTranslation(), bMatrix:GetAngles()
			if not Pos or not Ang then continue end

			if DoMP and (DoMPAll and true or HitGroup == HITGROUP_HEAD) then
				local MPs = GenerateMultiPoints(Pos, Ang, Mins, Maxs)

				for i = 1, #MPs do
					hData[HitGroup][#hData[HitGroup] + 1] = MPs[i]
				end
			end

			Mins:Rotate(Ang)
			Maxs:Rotate(Ang)

			hData[HitGroup][#hData[HitGroup] + 1] = Pos + ((Mins + Maxs) / 2)
		end
	end

	return hData
end

local function GetAvailablePositions(Entity)
	local EMPTY = true

	local phData = GetEntityHitboxes(Entity)
	local hData = {}

	for _, v in ipairs(table_GetKeys(Cache.AimbotData.ScanOrder)) do
		hData[v] = {}
	end

	for k, _ in pairs(hData) do
		if not phData[k] or not hData[k] then continue end

		for _, x in ipairs(phData[k]) do
			if PosInFOV(x) then
				hData[k][#hData[k] + 1] = x

				EMPTY = false
			end
		end
	end

	return EMPTY and nil or hData
end

local function GetAimPosition(Entity)
	local Data = GetAvailablePositions(Entity)
	if not Data then return nil end

	for _, Set in ipairs(Cache.AimbotData.ScanOrder) do
		if not Data[Set] then continue end

		for _, v in ipairs(Data[Set]) do
			local Visible, Fr = IsVisible(v, Entity)

			if Visible then
				return v, Set, Fr
			end
		end
	end

	return nil
end

local function FixMovement(cmd)
	local MovementVector = Vector(cmd:GetForwardMove(), cmd:GetSideMove(), cmd:GetUpMove())

	local CMDAngle = cmd:GetViewAngles()
	local Yaw = CMDAngle.yaw - Cache.FacingAngle.yaw + MovementVector:Angle().yaw

	if (CMDAngle.pitch + 90) % 360 > 180 then -- Wtf
		Yaw = 180 - Yaw
	end

	Yaw = ((Yaw + 180) % 360) - 180

	local Speed = math_sqrt((MovementVector.x * MovementVector.x) + (MovementVector.y * MovementVector.y))
	Yaw = math_rad(Yaw)

	cmd:SetForwardMove(math_cos(Yaw) * Speed)
	cmd:SetSideMove(math_sin(Yaw) * Speed)
end

--------------------------- Timers ---------------------------

timer_Create("pa_Update", 0.3, 0, function()
	Cache.Players = player_GetAll()
end)

--------------------------- Hooks ---------------------------

hook_Add("EntityFireBullets", "pa_EntityFireBullets", function(Entity, Data)
	if Entity ~= Cache.LocalPlayer then return end

	local Weapon = Entity:GetActiveWeapon()
	if not IsValid(Weapon) then return end

	Cache.WeaponData.SpreadCones[Weapon:GetClass()] = Data.Spread
end)

hook_Add("HUDPaint", "pa_HUDPaint", function()
	if not Cache.ConVars.cl_drawhud:GetBool() or Cache.ConVars.Aimbot.FOV:GetInt() > 60 then return end

	surface_DrawCircle(Cache.ScrW / 2, Cache.ScrH / 2,  GetFOVRadius(), Cache.Colors.FOV.Outline)
end)

hook_Add("PreFrameStageNotify", "pa_PreFrameStageNotify", function(stage)
	if not IsValid(Cache.AimbotData.Target) then return end

	if stage == FRAME_NET_UPDATE_START then -- Disable lerp for target during aiming
		pSetInterpolationEnabled(Cache.AimbotData.Target, false)
	end

	if stage == FRAME_NET_UPDATE_END then -- Reenable lerp afterwards
		pSetInterpolationEnabled(Cache.AimbotData.Target, true)
		Cache.AimbotData.Target = NULL
	end
end)

hook_Add("CreateMove", "pa_CreateMoveEx", function(cmd)
	Cache.LocalPlayer = Cache.LocalPlayer or LocalPlayer()

	-- Setup facing angle

	Cache.FacingAngle = Cache.FacingAngle or cmd:GetViewAngles()

	Cache.FacingAngle.pitch = Cache.FacingAngle.pitch + (cmd:GetMouseY() * Cache.ConVars.m_pitch:GetFloat())
	Cache.FacingAngle.yaw = Cache.FacingAngle.yaw - (cmd:GetMouseX() * Cache.ConVars.m_yaw:GetFloat())

	FixAngle(Cache.FacingAngle)

	-- Do silent aim

	local Silent = Cache.ConVars.Aimbot.Silent:GetBool()

	if cmd:KeyDown(IN_USE) or not Silent then
		Cache.FacingAngle = cmd:GetViewAngles()
	end

	if cmd:CommandNumber() == 0 then
		cmd:SetViewAngles(Cache.FacingAngle)
		return
	end

	-- Setup backtrack points

	local ServerTime = GetServerTime()
	local BacktrackLimit = Cache.ConVars.Aimbot.BacktrackAmount:GetFloat()

	if Cache.ConVars.Aimbot.Backtrack:GetBool() and Cache.ConVars.Aimbot.Enabled:GetBool() then
		for _, v in ipairs(Cache.Players) do
			if not ValidEntity(v) or PlayerInBuildMode(v) or PlayerInGodMode(v) or PlayerInOpposingHVHMode(v) then -- No point in backtracking something you can't shoot at
				Cache.AimbotData.Backtrack[v] = nil
				continue
			end

			local pData = Cache.AimbotData.Backtrack[v] or {}

			pData[#pData + 1] = {
				hData = GetEntityHitboxes(v),
				Tick = TimeToTick(GetEntitySimTime(v))
			}

			Cache.AimbotData.Backtrack[v] = pData
		end
	end

	for _, d in pairs(Cache.AimbotData.Backtrack) do
		for i = #d, 1, -1 do
			local dTime = TickToTime(d[i].Tick)

			if ServerTime - dTime > BacktrackLimit then
				table_remove(d, i)
			end
		end
	end

	hook.Run("CreateMoveEx", cmd) -- Fix this retarded hook not running as often as it should

	if Cache.AimbotData.Active then
		cmd:SetViewAngles(Cache.AimbotData.Angle)
	end
end)

hook.Add("CreateMoveEx", "pa_CreateMoveEx", function(cmd)
	Cache.AimbotData.Active = false

	local Weapon = Cache.LocalPlayer:GetActiveWeapon()

	if Cache.ConVars.Aimbot.Enabled:GetBool() and input_IsButtonDown(Cache.ConVars.Aimbot.Key:GetInt()) and IsValid(Weapon) and WeaponCanShoot(Weapon) then
		local Target, bPos, bTick, bHitGroup, bFraction = GetAimTarget()
		if not IsValid(Target) then return end

		Cache.AimbotData.Target = Target

		local Pos
		local HitGroup
		local Fraction

		if bPos then
			Pos = bPos
			HitGroup = bHitGroup
			Fraction = bFraction
		else
			Pos, HitGroup, Fraction = GetAimPosition(Target)
		end

		if not Pos then return end

		local TargetSimTime = bTick and TickToTime(bTick) or GetEntitySimTime(Target)
		local TargetSimTick = bTick or TimeToTick(TargetSimTime)

		if GetServerTime() - TargetSimTime <= Cache.ConVars.Aimbot.BacktrackAmount:GetFloat() then -- Don't set tick count for people who are lagging
			cmd:SetTickCount(TargetSimTick)
		end

		if Cache.ConVars.Aimbot.DEBUGMODE:GetBool() then
			print("~~~~~~~~~~~~~ Processed Data For " .. tostring(Target) .. " ~~~~~~~~~~~~~")
			print("Position: " .. tostring(Pos))
			print("HitGroup: " .. tostring(Cache.HitgroupTranslation[HitGroup]))
			print("Backtrack? : " .. tostring(tobool(bPos)))
			print("Target Sim Tick: " .. TargetSimTick)
			print("Target Sim Time: " .. TargetSimTime)
			print("Server Time: " .. GetServerTime())
			print("Target Sim Dif: " .. (GetServerTime() - TargetSimTime))
			print("Fraction: " .. tostring(Fraction))
			print("~~~~~~~~~~~~~ ~~~~~~~~~~~~~ ~~~~~~~~~~~~~ ~~~~~~~~~~~~~")
		end

		pStartPrediction(cmd)
			local pAngle = (Pos - Cache.LocalPlayer:EyePos()):Angle()
			local sAngle = CalculateNoSpread(Weapon, cmd, pAngle)

			Cache.AimbotData.Angle = sAngle - CalculateViewPunch(Weapon)
			Cache.AimbotData.Active = true

			if Cache.ConVars.Aimbot.AutoShoot:GetBool() then
				cmd:AddKey(IN_ATTACK)
			end
		pEndPrediction()

		if Cache.ConVars.Aimbot.FixMovement:GetBool() then
			FixMovement(cmd)
		end
	end

	if not Cache.AimbotData.Active and cmd:KeyDown(IN_ATTACK) and IsValid(Weapon) and WeaponCanShoot(Weapon) then
		local sAngle = CalculateNoSpread(Weapon, cmd, Cache.FacingAngle)

		Cache.AimbotData.Angle = sAngle - CalculateViewPunch(Weapon)
		Cache.AimbotData.Active = true

		if Cache.ConVars.Aimbot.FixMovement:GetBool() then
			FixMovement(cmd)
		end
	end
end)

hook_Add("CalcView", "", function(Player, EyePos, EyeAngles, FOV, ZNear, ZFar)
	if not IsValid(Player) then return end

	EyeAngles = Cache.FacingAngle * 1

	if not Cache.ConVars.Aimbot.AntiRecoil:GetBool() then
		EyeAngles = EyeAngles + Player:GetViewPunchAngles()
	end

	local View = {
		origin = EyePos,
		angles = EyeAngles,
		fov = FOV,
		znear = ZNear,
		zfar = ZFar
	}

	local Vehicle = Player:GetVehicle()

	if IsValid(Vehicle) then
		UpdateCalcViewData(View)

		return hook.Run("CalcVehicleView", Vehicle, Player, View)
	end

	local Weapon = Player:GetActiveWeapon()

	if IsValid(Weapon) then
		local wCalcView = Weapon.CalcView

		if wCalcView then
			local WeaponAngle = angle_zero * 1

			View.origin, WeaponAngle, View.fov = wCalcView(Weapon, Player, View.origin * 1, View.angles, View.fov)

			if not Cache.ConVars.Aimbot.AntiRecoil:GetBool() then
				View.angles = WeaponAngle
			end
		end
	end

	UpdateCalcViewData(View)

	return View
end)

hook_Add("PrePlayerDraw", "pa_PrePlayerDraw", function(Player)
	if not Cache.ConVars.Aimbot.AntiGesture:GetBool() then return end
	if Player == Cache.LocalPlayer then return end -- I wanna dance!

	Player:AnimResetGestureSlot(GESTURE_SLOT_VCD)
end)

hook_Add("PreDrawEffects", "pa_PreDrawEffects", function() -- Debug
	if Cache.ConVars.Aimbot.DEBUGMODE:GetBool() and Cache.ConVars.Aimbot.Backtrack:GetBool() then
		local Mins = Vector(-1, -1, -1) -- No cache because it's just debug who cares
		local Maxs = Vector(1, 1, 1)

		for _, d in pairs(Cache.AimbotData.Backtrack) do
			for i = 1, #d do
				local h = d[i]

				for i = #Cache.AimbotData.ScanOrder, 1, -1 do
					local Set = Cache.AimbotData.ScanOrder[i]
					if not h.hData[Set] then continue end

					for _, hPos in ipairs(h.hData[Set]) do
						render.DrawWireframeBox(hPos, angle_zero, Mins, Maxs, Cache.Colors.White, false)
					end
				end
			end
		end
	end
end)

hook_Add("OnScreenSizeChanged", "pa_OnScreenSizeChanged", function()
	Cache.ScrW = ScrW()
	Cache.ScrH = ScrH()
end)

--------------------------- CVar Stuff ---------------------------

cvars_AddChangeCallback("pa_fov_color_outline", function(_, _, NewValue)
	Cache.Colors.FOV.Outline = string_ToColor(NewValue)
end)

cvars_AddChangeCallback("pa_animlerp", function(_, _, NewValue)
	pDisableAnimInterp(not tobool(NewValue))
end)

Cache.ConVars.cl_interpolate:ForceBool(false) -- This should maybe be somewhere else but ehhhh
Cache.ConVars.cl_interp:ForceFloat(0)
Cache.ConVars.cl_interp:SendValue(0)

--------------------------- Menu Setup ---------------------------

do -- Garbage collection friendly
	local function CreateCheckBox(Parent, X, Y, Label, ConVar)
		local CheckBox = vgui_Create("DCheckBoxLabel", Parent)
		CheckBox:SetTextColor(Cache.Colors.Black)
		CheckBox:SetText(Label)
		CheckBox:SetPos(X, Y)
		CheckBox:SetChecked(ConVar:GetBool())

		CheckBox._ConVar = ConVar

		CheckBox.OnChange = function(self, NewValue)
			self._ConVar:SetBool(NewValue)
		end

		CheckBox.Think = function(self)
			self:SetChecked(self._ConVar:GetBool())
		end
	end

	local function CreateSlider(Parent, X, Y, Width, Min, Max, Decimals, Label, ConVar)
		local NSlider = vgui_Create("DNumSlider", Parent) -- "Slider" is a global and the color highlighting was annoying
		NSlider:SetWide(Width)
		NSlider:SetPos(X, Y)
		NSlider:SetMinMax(Min, Max)
		NSlider:SetDark(true)
		NSlider:SetDecimals(Decimals)
		NSlider:SetConVar(ConVar:GetName())
		NSlider:SetValue(ConVar:GetFloat()) -- Shouldn't be required but the knob fucks up without this

		-- Custom label to close the giant gap DNumSliders have between their label and the actual slider

		NSlider.Label:SetVisible(false)
		local NLabel = vgui_Create("DLabel", NSlider)

		surface.SetFont(NLabel:GetFont())
		local tw, _ = surface.GetTextSize(Label)

		NLabel:Dock(LEFT)
		NLabel:SetWide(tw)
		NLabel:SetText(Label)
		NLabel:SetTextColor(Cache.Colors.Black)
	end

	local Main = vgui_Create("DFrame")
	Main:SetSize(400, 590)
	Main:Center()
	Main:SetTitle("Proxi Aimbot")
	Main:SetSizable(false)
	Main:SetVisible(false)
	Main:SetDeleteOnClose(false)

	local MainFrame = vgui_Create("DPanel", Main) -- Yeah it's a panel but "MainPanel" doesn't sound as cool; This is really just here for the background color
	MainFrame:Dock(FILL)
	Main:InvalidateLayout(true) -- Derma fucking sucks

	--------------------------- Top Part ---------------------------

	local TopSection = vgui_Create("DSection", MainFrame)
	TopSection:SetSize(MainFrame:GetWide() - 10, 328)
	TopSection:SetPos(5, 5)
	TopSection:SetText("Options")
	TopSection:SetTextColor(Cache.Colors.Black)

	CreateCheckBox(TopSection, 25, 25, "Enable Aimbot", Cache.ConVars.Aimbot.Enabled)
	CreateCheckBox(TopSection, 50, 50, "Silent Aim", Cache.ConVars.Aimbot.Silent)
	CreateCheckBox(TopSection, 50, 75, "Bullettime", Cache.ConVars.Aimbot.Bullettime)
	CreateCheckBox(TopSection, 50, 100, "Movement Fix", Cache.ConVars.Aimbot.FixMovement)
	CreateCheckBox(TopSection, 50, 125, "Anti Spread", Cache.ConVars.Aimbot.AntiSpread)
	CreateCheckBox(TopSection, 50, 150, "Anti Recoil", Cache.ConVars.Aimbot.AntiRecoil)
	CreateCheckBox(TopSection, 50, 175, "Auto Shoot", Cache.ConVars.Aimbot.AutoShoot)
	CreateCheckBox(TopSection, 50, 200, "Backtrack", Cache.ConVars.Aimbot.Backtrack)
	CreateCheckBox(TopSection, 50, 225, "Anti Gesture", Cache.ConVars.Aimbot.AntiGesture)
	CreateCheckBox(TopSection, 50, 250, "Multipoint", Cache.ConVars.Aimbot.MultiPoint)
	CreateCheckBox(TopSection, 75, 275, "Multipoint Every Hitbox", Cache.ConVars.Aimbot.MultiPointAll)
	CreateCheckBox(TopSection, 50, 300, "Disable Animation Lerp", Cache.ConVars.Aimbot.AnimLerp)

	local KeyBinder = vgui_Create("DBinder", TopSection)
	KeyBinder:SetSize(100, 25)
	KeyBinder:SetPos(250, 25)
	KeyBinder:SetConVar(Cache.ConVars.Aimbot.Key:GetName())

	--------------------------- Bottom Part ---------------------------

	local BottomSection = vgui_Create("DSection", MainFrame)
	BottomSection:SetSize(MainFrame:GetWide() - 10, MainFrame:GetTall() - TopSection:GetTall() - 10)
	BottomSection:SetPos(5, 5 + TopSection:GetTall())
	BottomSection:SetText("The second part")
	BottomSection:SetTextColor(Cache.Colors.Black)

	CreateSlider(BottomSection, 25, 25, BottomSection:GetWide() - 50, 0, 180, 0, "FOV", Cache.ConVars.Aimbot.FOV)
	CreateSlider(BottomSection, 25, 50, BottomSection:GetWide() - 50, 0, 1, 2, "Backtrack Amount", Cache.ConVars.Aimbot.BacktrackAmount)

	local FOVLabel = vgui_Create("DLabel", BottomSection)
	FOVLabel:SetPos(25, 80)
	FOVLabel:SetWide(125)
	FOVLabel:SetText("FOV Circle Color")
	FOVLabel:SetTextColor(Cache.Colors.Black)

	local FOVColor = vgui_Create("DColorMixer", BottomSection)
	FOVColor:SetPalette(false)
	FOVColor:SetSize(215, 100)
	FOVColor:SetPos(25, 100)

	FOVColor.ValueChanged = function(_, NewColor)
		NewColor = setmetatable(NewColor, meta_cl) -- Fix bug

		Cache.ConVars.Aimbot.FOVOutline:SetString(tostring(NewColor))
	end
	
	FOVColor._oThink = FOVColor.Think

	FOVColor.Think = function(self)
		self._oThink(self)

		self:SetColor(Cache.Colors.FOV.Outline)
	end

	Cache.Menu = Main
end

concommand.Add("pa_menu", function()
	if IsValid(Cache.Menu) then
		Cache.Menu:SetVisible(true)
		Cache.Menu:MakePopup()
	end
end)

--------------------------- Take out the trash ---------------------------

collectgarbage("collect")
