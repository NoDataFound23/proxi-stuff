--[[
	https://github.com/leme6156/proxi-stuff

	ConCommands:
		pa_menu		-		Opens the menu

	Requirements:
		proxi
		https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/includes/modules/CUniformRandomStream.lua
]]

pcall(require, "proxi")
if not proxi then return end -- Noob

if not CUniformRandomStream and file.Exists("lua/includes/modules/CUniformRandomStream.lua", "GAME") then -- Why does this have to be like this Interstate why why this is why we can't have nice things
	pcall(RunString, file.Read("lua/includes/modules/CUniformRandomStream.lua", "GAME"))
end
if not CUniformRandomStream then return end -- Epic fail

local Data = {
	Environment = { -- Is this overkill for just a simple aimbot? Yes. Very much so :)
		-- Table stuff
		_G = _G or getfenv(1),
		_R = proxi._R or debug.getregistry(),

		proxi = proxi, -- This global gets destroyed
		CUniformRandomStream = CUniformRandomStream, -- This doesn't get destroyed because I'm too lazy to make a simple change so it stays

		Variables = {
			Enabled = true,

			Key = {
				Enabled = true,
				Code = MOUSE_5
			},

			FOV = {
				Amount = 16,

				Visible = {
					Outline = true,
					Fill = true
				},

				Colors = {}
			},

			Silent = true,
			FixMovement = true,
			BulletTime = true,
			AntiSpread = true,
			AntiRecoil = true,

			AutoShoot = {
				Enabled = true,

				Slow = {
					Enabled = false,
					Amount = 0.3
				}
			},

			AutoWall = true,
			AntiTaunt = false,

			Backtrack = {
				Enabled = true,
				Amount = 0.2
			},

			MultiPoint = {
				Enabled = true,

				Hitboxes = {
					[HITGROUP_HEAD] = true,
					[HITGROUP_CHEST] = false,
					[HITGROUP_STOMACH] = false
				}
			}
		},

		Cache = {
			HookName = tostring({}),
			Menu = nil,
			TickInternval = 0,
			LocalPlayer = NULL,
			FacingAngle = nil,

			AimbotData = {
				Active = false, -- Used for logging
				Hitgroup = 0,
				Penetrations = 0,
				BacktrackAmount = 0,
				Wait = false,
				Target = NULL,
				SlowShootTicks = 0,

				ScanOrder = {
					HITGROUP_HEAD,
					HITGROUP_CHEST,
					HITGROUP_STOMACH
				}
			},

			BacktrackData = {},

			TraceData = {},
			TraceOutput = {},

			ModelData = {},

			Colors = {},
			Textures = {},
			ViewData = {},
			Polygons = {},

			ConVars = {
				AntiSpread = {},
				AutoWall = {}
			},

			LastPlayerListUpdate = 0,
			PlayerList = {},

			HitgroupLookups = {
				[HITGROUP_GENERIC] = "Generic",
				[HITGROUP_HEAD] = "Head",
				[HITGROUP_CHEST] = "Chest",
				[HITGROUP_STOMACH] = "Stomach",
				[HITGROUP_LEFTARM] = "Left Arm",
				[HITGROUP_RIGHTARM] = "Right Arm",
				[HITGROUP_LEFTLEG] = "Left Leg",
				[HITGROUP_RIGHTLEG] = "Right Leg"
			},

			ScreenData = {
				Width = 0,
				Height = 0,

				Center = {
					X = 0,
					Y = 0
				}
			},

			NetMessages = {
				Buildmode = { "BuildMode", "buildmode", "_Kyle_Buildmode" },
				God = { "has_god", "god_mode", "ugod" },
				HVH = { "HVHER" },
				Protected = { "LibbyProtectedSpawn", "SH_SZ.Safe", "spawn_protect", "InSpawnZone" }
			},

			WeaponData = {
				AntiSpread = {
					Cones = {},
					Seeds = {},
					Storage = {},
					BaseFunctions = {}
				},

				AutoShoot = {
					BaseFunctions = {},

					Classes = {
						Blacklist = { "bomb", "c4", "climb", "fist", "gravity gun", "grenade", "hand", "ied", "knife", "physics gun", "slam", "sword", "tool gun", "vape" },
						Whitelist = { "handgun" }
					}
				},

				AutoWall = {
					Limits = {
						["357"] = {144, 4},
						ar2 = {256, 8},
						buckshot = {25, 1},
						pistol = {81, 2},
						smg1 = {196, 5},
						sniperpenetratedround = {400, 12},
						sniperround = {400, 12} -- SWB
					},

					Multipliers = {
						[MAT_SAND] = 0.5,
						[MAT_DIRT] = 0.8,
						[MAT_METAL] = 1.1,
						[MAT_TILE] = 0.9,
						[MAT_WOOD] = 1.2
					},

					Cancellers = {
						[MAT_SLOSH] = true
					},

					Functions = {}
				}
			}
		},

		-- proxi stuff
		FRAME_NET_UPDATE_END = proxi.FRAME_NET_UPDATE_END or 5,

		GetConVar = proxi.GetConVar,
		GetNetVar = proxi.__Ent_GetNetVar
	}
}

Data.Environment.Cache.TraceData.output = Data.Environment.Cache.TraceOutput
proxi = nil

--------------------------- Table Setup ---------------------------

do
	local ENV = Data.Environment

	ENV.rawget = rawget(ENV._G, "rawget")
	ENV.getfenv = ENV.rawget(ENV._G, "getfenv")
	ENV.setfenv = ENV.rawget(ENV._G, "setfenv")
	ENV.type = ENV.rawget(ENV._G, "type")

	ENV.table = {
		Copy = ENV.rawget(ENV._G.table, "Copy")
	}

	-- Sets a function's environment to the environment
	function ENV.RegisterFunction(Function)
		return ENV.setfenv(Function, ENV)
	end

	-- Creates a function in the environment
	function ENV.CreateFunction(Name, Function)
		ENV[Name] = ENV.RegisterFunction(Function)
	end

	-- Localizes something from the global table to the local environment (Auto constructs table layout)
	ENV.CreateFunction("Localize", function(...)
		local Parameters = {...}
		local Found = false
		local Last = "_"
		local Cur = _G
		local LastTable = ENV
		local CurTable = ENV

		for i = 1, #Parameters do
			local v = Parameters[i]

			Last = Cur
			Cur = Cur[v]

			if type(Cur) == "table" then -- Setup environment
				CurTable[v] = rawget(CurTable, v) or {} -- Avoid __index

				LastTable = CurTable
				CurTable = CurTable[v]
				Last = v
			else
				CurTable[v] = Cur
				Found = true

				break
			end
		end

		if not Found then
			LastTable[Last] = table.Copy(Cur)
		end
	end)

	--------------------------- Normal Localization ---------------------------

	-- Enums
	ENV.Localize("GESTURE_SLOT_VCD")
	ENV.Localize("HITGROUP_CHEST")
	ENV.Localize("HITGROUP_HEAD")
	ENV.Localize("HITGROUP_STOMACH")
	ENV.Localize("IN_ATTACK")
	ENV.Localize("IN_ATTACK2")
	ENV.Localize("IN_RELOAD")
	ENV.Localize("IN_SPEED")
	ENV.Localize("IN_USE")
	ENV.Localize("MASK_SHOT")
	ENV.Localize("OBS_MODE_NONE")
	ENV.Localize("TEAM_SPECTATOR")

	-- Functions
	ENV.Localize("Angle")
	ENV.Localize("Color")
	ENV.Localize("CurTime")
	ENV.Localize("IsFirstTimePredicted")
	ENV.Localize("IsValid")
	ENV.Localize("LocalPlayer")
	ENV.Localize("MsgC")
	ENV.Localize("MsgN")
	ENV.Localize("Player")
	ENV.Localize("RealFrameTime")
	ENV.Localize("ScrH")
	ENV.Localize("ScrW")
	ENV.Localize("SysTime")
	ENV.Localize("Vector")
	ENV.Localize("collectgarbage")
	ENV.Localize("next")
	ENV.Localize("tobool")
	ENV.Localize("tostring")
	ENV.Localize("type")
	ENV.Localize("unpack")

	-- Libraries
	ENV.Localize("concommand", "Add")
	ENV.Localize("debug", "setmetatable")
	ENV.Localize("draw", "NoTexture")
	ENV.Localize("engine", "TickInterval")
	ENV.Localize("file", "Open")
	ENV.Localize("game", "GetAmmoName")
	ENV.Localize("game", "GetWorld")
	ENV.Localize("hook", "Add")
	ENV.Localize("hook", "Run")
	ENV.Localize("input", "IsButtonDown")
	ENV.Localize("math", "Clamp") -- So many calculations! Must be a math wiz!
	ENV.Localize("math", "Distance")
	ENV.Localize("math", "NormalizeAngle")
	ENV.Localize("math", "Round")
	ENV.Localize("math", "Truncate")
	ENV.Localize("math", "abs")
	ENV.Localize("math", "acos")
	ENV.Localize("math", "atan")
	ENV.Localize("math", "cos")
	ENV.Localize("math", "deg")
	ENV.Localize("math", "floor")
	ENV.Localize("math", "huge")
	ENV.Localize("math", "max")
	ENV.Localize("math", "min")
	ENV.Localize("math", "pi")
	ENV.Localize("math", "pow")
	ENV.Localize("math", "rad")
	ENV.Localize("math", "sin")
	ENV.Localize("math", "sqrt")
	ENV.Localize("math", "tan")
	ENV.Localize("player", "GetAll")
	ENV.Localize("string", "Split")
	ENV.Localize("string", "find")
	ENV.Localize("string", "lower")
	ENV.Localize("string", "sub")
	ENV.Localize("surface", "DrawCircle")
	ENV.Localize("surface", "DrawOutlinedRect")
	ENV.Localize("surface", "DrawPoly")
	ENV.Localize("surface", "DrawRect")
	ENV.Localize("surface", "GetTextSize")
	ENV.Localize("surface", "GetTextureID")
	ENV.Localize("surface", "SetDrawColor")
	ENV.Localize("surface", "SetTexture")
	ENV.Localize("table", "Empty")
	ENV.Localize("table", "IsEmpty")
	ENV.Localize("table", "insert")
	ENV.Localize("table", "remove")
	ENV.Localize("timer", "Simple")
	ENV.Localize("util", "TraceLine")
	ENV.Localize("vgui", "Create")

	-- Stupid shit
	ENV.NULL = ENV.rawget(_G, "NULL") -- BEEEEEEEEEEEEEEE

	ENV.CustomizableWeaponry = ENV.rawget(ENV._G, "CustomizableWeaponry")
	ENV.CW_AIMING = ENV.rawget(ENV._G, "CW_AIMING")
	ENV.FAS_STAT_CUSTOMIZE = ENV.rawget(ENV._G, "FAS_STAT_CUSTOMIZE")
	ENV.FAS_STAT_SPRINT = ENV.rawget(ENV._G, "FAS_STAT_SPRINT")
	ENV.FAS_STAT_QUICKGRENADE = ENV.rawget(ENV._G, "FAS_STAT_QUICKGRENADE")
	ENV.TFA = ENV.rawget(ENV._G, "TFA")
	ENV.ArcCW = ENV.rawget(ENV._G, "ArcCW")

	--------------------------- Some Helpers ---------------------------

	-- Logs something with some super duper fancy formatting (I probably overdid this, oh well)
	ENV.CreateFunction("Log", function(...)
		local Arguments = {
			Cache.Colors.Gray,
			"[",
			Cache.Colors.Lavender,
			"Proxi",
			Cache.Colors.Purple,
			"Aimbot",
			Cache.Colors.Gray,
			"] ",
			Cache.Colors.Teal
		}

		local Message = ""
		local Concat = {...}

		if #Concat > 1 then
			for i = 1, #Concat do
				Message = Message .. tostring(Concat[i])
			end
		else
			Message = ...
		end

		local EndPos = 1
		local StartPos = string.find(Message, "{")

		if StartPos == nil then
			Arguments[#Arguments + 1] = Message
		else
			local IsFirst = true -- The first run requires a bit of adjustment

			while StartPos ~= nil do
				local nStartPos, nEndPos = string.find(Message, "}", StartPos)
				local ColorKey = string.sub(Message, StartPos + 1, nStartPos - 1)

				Arguments[#Arguments + 1] = (ColorKey == "$Reset" and Cache.Colors.Teal) or Cache.Colors[ColorKey] or Cache.Colors.Red

				if StartPos - 1 > 0 then
					if not IsFirst then
						EndPos = nEndPos + 1
					end

					table.insert(Arguments, #Arguments, string.sub(Message, EndPos, StartPos - 1))
				end

				if IsFirst then
					EndPos = nEndPos + 1
					IsFirst = false
				end

				StartPos = string.find(Message, "{", nStartPos)

				Arguments[#Arguments + 1] = string.sub(Message, nEndPos + 1, StartPos and StartPos - 1 or #Message)
			end
		end

		MsgC(unpack(Arguments))
		MsgN()
	end)

	-- Hooks something
	ENV.CreateFunction("AddHook", function(Type, Function)
		Log("Hooking '{Green}", Type, "{$Reset}' {Gray}({Green}", Cache.HookName, "{Gray})")

		hook.Add(Type, Cache.HookName, ENV.RegisterFunction(Function))
	end)

	-- Makes a poly with x amount of vertices (Used to make filled circles)
	ENV.CreateFunction("CreatePolygon", function(X, Y, Radius, VertexCount)
		local Vertices = {}

    	local VertexX, VertexY = Radius, 0

    	local RotationX = math.cos(2 * math.pi / VertexCount)
    	local RotationY = math.sqrt(1 - RotationX * RotationX)

    	for i = 1, VertexCount do
    	    Vertices[i] = {
    	        x = X + VertexX,
    	        y = Y + VertexY
    	    }

    	    VertexX, VertexY = (VertexX * RotationX) - (VertexY * RotationY), (VertexY * RotationX) + (VertexX * RotationY)
    	end

		return Vertices
	end)

	-- Gets the time to adjust for interp
	ENV.CreateFunction("GetInterpolationTime", function()
		if not Cache.ConVars.cl_interpolate:GetBool() then
			return 0
		end

		local UpdateRate = math.Clamp(Cache.ConVars.cl_updaterate:GetInt(), Cache.ConVars.sv_minupdaterate:GetInt(), Cache.ConVars.sv_maxupdaterate:GetInt())
		if UpdateRate == 0 then UpdateRate = 1 end

		local Ratio = math.Clamp(Cache.ConVars.cl_interp_ratio:GetInt(), Cache.ConVars.sv_client_min_interp_ratio:GetInt(), Cache.ConVars.sv_client_max_interp_ratio:GetInt())
		if Ratio == 0 then Ratio = 1 end

		return math.max(Cache.ConVars.cl_interp:GetFloat(), Ratio / UpdateRate)
	end)

	-- Converts time units to tick
	ENV.CreateFunction("TimeToTick", function(Time)
		return math.floor(0.5 + (Time / Cache.TickInterval)) + math.min(GetInterpolationTime(), Cache.ConVars.sv_maxunlag:GetInt())
	end)

	-- Converts tick to time units
	ENV.CreateFunction("TickToTime", function(Tick)
		return Cache.TickInterval * Tick
	end)

	-- Gets the CurTime of the server
	ENV.CreateFunction("GetServerTime", function()
		return TickToTime(Cache.LocalPlayer:GetInternalVariable("m_nTickBase"))
	end)

	-- Gets the simulation time of an entity
	ENV.CreateFunction("GetEntitySimulationTime", function(Entity)
		return GetNetVar(Entity, "DT_BaseEntity->m_flSimulationTime", 1)
	end)

	-- Tests if the player should be registered as a valid target
	ENV.CreateFunction("IsPlayerTargetable", function(Player)
		do -- Buildmode
			for i = 1, #Cache.NetMessages.Buildmode do
				if tobool(Player:GetNWBool(Cache.NetMessages.Buildmode[i])) then
					return false
				end
			end
		end

		do -- Protected
			for i = 1, #Cache.NetMessages.Protected do
				if tobool(Player:GetNWBool(Cache.NetMessages.Protected[i])) then
					return false
				end
			end
		end

		do -- HVH
			local LocalHVH = false
			local PlayerHVH = false

			for i = 1, #Cache.NetMessages.HVH do
				if LocalHVH and PlayerHVH then break end

				LocalHVH = tobool(Cache.LocalPlayer:GetNWBool(Cache.NetMessages.HVH[i], false))
				PlayerHVH = tobool(Player:GetNWBool(Cache.NetMessages.HVH[i], false))
			end

			if LocalHVH ~= PlayerHVH then return false end
		end

		do -- Godmode
			if Player:HasGodMode() then return false end

			for i = 1, #Cache.NetMessages.God do
				if tobool(Player:GetNWBool(Cache.NetMessages.God[i])) then
					return false
				end
			end
		end

		return Player ~= Cache.LocalPlayer and Player:Alive() and Player:Team() ~= TEAM_SPECTATOR and Player:GetObserverMode() == OBS_MODE_NONE and not Player:IsDormant()
	end)

	-- Fixes an angle to engine view angle bounds
	ENV.CreateFunction("FixAngle", function(Angle)
		Angle.pitch = math.Clamp(math.NormalizeAngle(Angle.pitch), -89, 89)
		Angle.yaw = math.NormalizeAngle(Angle.yaw)
		Angle.roll = math.NormalizeAngle(Angle.roll)
	end)

	-- Gets what radius the FOV circle should be
	ENV.CreateFunction("GetFOVRadius", function(Radius)
		if not Cache.ViewData.Origin then
			return 0 -- CalcView hasn't initialized yet, ViewData is empty
		end

		Radius = Radius or Variables.FOV.Amount

		local Ratio = Cache.ScreenData.Width / Cache.ScreenData.Height
		local AimFOV = Radius * (math.pi / 180)
		local GameFOV = Cache.ViewData.FOV * (math.pi / 180)
		local ViewFOV = 2 * math.atan(Ratio * (Cache.ViewData.ZNear / 2) * math.tan(GameFOV / 2))

		return (math.tan(AimFOV) / math.tan(ViewFOV / 2)) * Cache.ScreenData.Width
	end)

	-- Gets the base of a weapon
	ENV.CreateFunction("GetWeaponBase", function(Weapon)
		if not Weapon.Base then return "" end
		return string.Split(string.lower(Weapon.Base), "_")[1]
	end)

	-- Tests if a weapon is able to fire
	ENV.CreateFunction("WeaponCanShoot", function(Weapon)
		if not Variables.BulletTime then return true end

		local WeaponName = string.lower(Weapon.PrintName or Weapon:GetPrintName())

		for i = 1, #Cache.WeaponData.AutoShoot.Classes.Blacklist do
			if string.find(WeaponName, Cache.WeaponData.AutoShoot.Classes.Blacklist[i]) then
				local BreakOuter = false

				for i = 1, #Cache.WeaponData.AutoShoot.Classes.Whitelist do
					if string.find(WeaponName, Cache.WeaponData.AutoShoot.Classes.Whitelist[i]) then
						BreakOuter = true
						break
					end
				end

				if BreakOuter then continue end

				return false
			end
		end

		local Base = GetWeaponBase(Weapon)
		local BaseCheck = Cache.WeaponData.AutoShoot.BaseFunctions[Base] and Cache.WeaponData.AutoShoot.BaseFunctions[Base](Weapon) or true

		return GetServerTime() >= Weapon:GetNextPrimaryFire() and BaseCheck
	end)

	-- Get the distance of a point to the crosshair in screenspace
	ENV.CreateFunction("DistanceFromCrosshair", function(Position)
		if not Position then
			return 360, false
		end

		local ScreenPosition = Position:ToScreen()
		local Radius = GetFOVRadius()

		if ScreenPosition.Visible and Radius >= 0 then
			return math.Distance(Cache.ScreenData.Center.X, Cache.ScreenData.Center.Y, ScreenPosition.x, ScreenPosition.y), true
		else
			local Forward = Cache.ViewData.Angles:Forward()
			local Direction = (Position - Cache.LocalPlayer:EyePos()):GetNormalized()
			local Degree = math.deg(math.acos(Forward:Dot(Direction)))

			return math.abs(Degree), false
		end
	end)

	-- Test if a point is within the FOV circle
	ENV.CreateFunction("InFOV", function(Position)
		local Distance, WasW2S = DistanceFromCrosshair(Position)

		if WasW2S then
			local Radius = GetFOVRadius()
			if Radius < 0 then return true end

			return Distance <= Radius, Distance
		else
			return Distance <= Variables.FOV.Amount, Distance
		end
	end)

	-- Test if a position is visible on an entity
	ENV.CreateFunction("IsVisible", function(Position, Entity)
		Cache.TraceData.start = Cache.LocalPlayer:EyePos()
		Cache.TraceData.endpos = Position
		Cache.TraceData.filter = Cache.LocalPlayer
		Cache.TraceData.mask = MASK_SHOT

		util.TraceLine(Cache.TraceData)

		if Cache.TraceOutput.Entity == Entity then
			return true, 0, Cache.TraceOutput.Fraction
		elseif Variables.AutoWall then
			local Weapon = Cache.LocalPlayer:GetActiveWeapon()
			if not IsValid(Weapon) then
				return false, 0, Cache.TraceOutput.Fraction
			end

			local Hit, Penetrations = WeaponCanPenetrate(Weapon, Cache.TraceOutput, Entity, Position)
			Hit = Hit or false
			Penetrations = Penetrations or 0

			return Hit, Penetrations, Cache.TraceOutput.Fraction
		else
			return false, 0, Cache.TraceOutput.Fraction
		end
	end)

	-- Generates the 8 corners of a hitbox
	ENV.CreateFunction("GenerateMultiPoint", function(Position, Angle, Mins, Maxs)
		-- Inset points by a unit to avoid misses
		local pMins = Vector(Mins.x + 1, Mins.y + 1, Mins.z + 1)
		local pMaxs = Vector(Maxs.x - 1, Maxs.y - 1, Maxs.z - 1)

		-- Auto-generation isn't needed here, it's just 8 the corners
		local Data = {
			pMins,
			pMaxs,
			Vector(pMins.x, pMins.y, pMaxs.z),
			Vector(pMaxs.x, pMins.y, pMaxs.z),
			Vector(pMaxs.x, pMaxs.y, pMins.z),
			Vector(pMaxs.x, pMins.y, pMins.z),
			Vector(pMins.x, pMaxs.y, pMins.z),
			Vector(pMins.x, pMaxs.y, pMaxs.z)
		}

		for i = 1, #Data do
			Data[i]:Rotate(Angle) -- Correct for hitbox rotation
			Data[i]:Add(Position) -- Move them into worldspace
		end

		return Data
	end)

	-- Parses a model to gather hitbox data
	ENV.CreateFunction("GenerateModelData", function(Model) -- 0572 :)
		Model = Model or "models/error.mdl"

		if Cache.ModelData[Model] then
			return Cache.ModelData[Model]
		end

		local FileStream = file.Open(Model, "rb", "GAME")
		if not FileStream then return Cache.ModelData[Model] end

		local ID = FileStream:Read(4)
		if ID ~= "IDST" then return Cache.ModelData[Model] end

		Log("Parsing model '{Green}", Model, "{$Reset}'")

		local Data = {}
		Data.Version = FileStream:ReadLong()
		Data.Checksum = FileStream:ReadLong()

		FileStream:Read(64) -- Name

		Data.DataLength = FileStream:ReadLong()

		FileStream:Read(12) -- eyeposition
		FileStream:Read(12) -- illumposition

		FileStream:Read(12) -- hull_min
		FileStream:Read(12) -- hull_max

		FileStream:Read(12) -- view_bbmin
		FileStream:Read(12) -- view_bbmax

		Data.Flags = FileStream:ReadLong()

		-- mstudiobone_t
		Data.BoneCount = FileStream:ReadLong()
		Data.BoneOffset = FileStream:ReadLong()

		-- mstudiobonecontroller_t
		Data.BoneControllerCount = FileStream:ReadLong()
		Data.BoneControllerOffset = FileStream:ReadLong()

		-- mstudiobonecontroller_t
		Data.HitboxCount = FileStream:ReadLong()
		Data.HitboxOffset = FileStream:ReadLong()

		FileStream:Seek(Data.HitboxOffset)

		Data.szNameIndex = FileStream:ReadLong()
		Data.HitboxOffsetCount = FileStream:ReadLong()
		Data.HitboxIndex = FileStream:ReadLong()

		FileStream:Seek(Data.HitboxOffset + Data.HitboxIndex)

		Data.Hitboxes = {}

		for i = 1, Data.HitboxOffsetCount do
			local Temp = {}

			Temp.Bone = FileStream:ReadLong()
			Temp.Hitgroup = FileStream:ReadLong()

			Temp.Mins = Vector(FileStream:ReadFloat(), FileStream:ReadFloat(), FileStream:ReadFloat())
			Temp.Maxs = Vector(FileStream:ReadFloat(), FileStream:ReadFloat(), FileStream:ReadFloat())
			Temp.Center = (Temp.Mins + Temp.Maxs) / 2

			Temp.szHitBoxNameIndex = FileStream:ReadLong()

			FileStream:Read(32) -- Unused

			Data.Hitboxes[#Data.Hitboxes + 1] = Temp
		end

		FileStream:Close()

		Cache.ModelData[Model] = Data
		return Data
	end)

	-- Adjusts cached hitbox information + generated multipoint data
	ENV.CreateFunction("GetEntityHitboxes", function(Entity)
		local ModelData = GenerateModelData(Entity:GetModel())
		if not ModelData then return {} end

		local ShouldMultiPoint = Variables.MultiPoint.Enabled

		local Data = {
			[HITGROUP_HEAD] = {},
			[HITGROUP_CHEST] = {},
			[HITGROUP_STOMACH] = {}
		}

		Entity:SetupBones()

		for i = 1, #ModelData.Hitboxes do
			local v = ModelData.Hitboxes[i]
			if not v or not Data[v.Hitgroup] then continue end

			local Matrix = Entity:GetBoneMatrix(v.Bone)
			if not Matrix then continue end

			local Position, Angle = Matrix:GetTranslation(), Matrix:GetAngles()

			local Center = Vector(v.Center)
			Center:Rotate(Angle)

			Data[v.Hitgroup][#Data[v.Hitgroup] + 1] = Position + Center

			if ShouldMultiPoint and Variables.MultiPoint.Hitboxes[v.Hitgroup] then
				local MultiPointData = GenerateMultiPoint(Position, Angle, v.Mins, v.Maxs)

				for mi = 1, #MultiPointData do
					Data[v.Hitgroup][#Data[v.Hitgroup] + 1] = MultiPointData[mi]
				end
			end
		end

		return Data
	end)

	-- Finds a valid player who's closest to the crosshair
	ENV.CreateFunction("GetAimbotTarget", function() -- Got a little janky during construction, needs some cleanup
		local BestDistance = math.huge
		local BestHitboxes = nil
		local BestPlayer = NULL
		local BestPenetrations = 0
		local BestIsBacktrack = false

		local ShouldBacktrack = Variables.Backtrack.Enabled

		for i = 1, #Cache.PlayerList do
			local Player = Cache.PlayerList[i]

			if not IsValid(Player) then continue end
			if not IsPlayerTargetable(Player) then continue end

			local WorldSpaceCenter = Player:WorldSpaceCenter()

			local CurrentDistance = math.huge
			local CurrentHasPointInFOV = false
			local CurrentHitboxes = GetEntityHitboxes(Player)
			local CurrentPenetrations = 0

			local PlayerIsVisible = false

			for GroupIndex = 1, #Cache.AimbotData.ScanOrder do
				local Hitgroup = Cache.AimbotData.ScanOrder[GroupIndex]
				if not CurrentHitboxes[Hitgroup] then continue end

				for i = 1, #CurrentHitboxes[Hitgroup] do
					local CurrentPosition = CurrentHitboxes[Hitgroup][i]

					local pInFOV, pDistance = InFOV(CurrentPosition)
					if not pInFOV then continue end

					local Valid, Penetrations = IsVisible(CurrentPosition, Player)

					if Valid then
						CurrentHasPointInFOV = pInFOV
						CurrentDistance = pDistance

						PlayerIsVisible = true
						CurrentPenetrations = Penetrations
						break
					end
				end

				if PlayerIsVisible then break end
			end

			if not PlayerIsVisible then continue end

			if CurrentHasPointInFOV and CurrentDistance < BestDistance then
				BestDistance = CurrentDistance
				BestPlayer = Player
				BestHitboxes = CurrentHitboxes
				BestPenetrations = CurrentPenetrations
			end

			if ShouldBacktrack and Cache.BacktrackData[Player] then
				local BacktrackData = Cache.BacktrackData[Player]

				for BacktrackIndex = 1, #BacktrackData do
					local Hitboxes = BacktrackData[BacktrackIndex].Hitboxes

					for GroupIndex = 1, #Cache.AimbotData.ScanOrder do
						local Hitgroup = Cache.AimbotData.ScanOrder[GroupIndex]
						if not Hitboxes[Hitgroup] then continue end

						for HitboxIndex = 1, #Hitboxes[Hitgroup] do
							local CurrentPosition = Hitboxes[Hitgroup][HitboxIndex]

							local pInFOV, pDistance = InFOV(CurrentPosition)
							if not pInFOV then continue end

							local Valid, Penetrations, Fraction = IsVisible(CurrentPosition, Player)
							if not Valid and Fraction < 0.99 then continue end

							if pDistance < BestDistance then
								return Player, Hitboxes, Penetrations, true, BacktrackData[BacktrackIndex].SimulationTick
							end
						end
					end
				end
			end

			CurrentDistance = math.huge
			CurrentHasPointInFOV = false
		end

		return BestPlayer, BestHitboxes, BestPenetrations, BestIsBacktrack
	end)

	-- Gets all available aimbot positions
	ENV.CreateFunction("GetAvailablePositions", function(Entity, Hitboxes)
		local FixedHitboxes = {}

		for GroupIndex = 1, #Cache.AimbotData.ScanOrder do
			local Hitgroup = Cache.AimbotData.ScanOrder[GroupIndex]
			if not Hitboxes[Hitgroup] then continue end

			for i = 1, #Hitboxes[Hitgroup] do
				local CurrentPosition = Hitboxes[Hitgroup][i]

				if InFOV(CurrentPosition) then
					FixedHitboxes[Hitgroup] = FixedHitboxes[Hitgroup] or {}
					FixedHitboxes[Hitgroup][#FixedHitboxes[Hitgroup] + 1] = CurrentPosition
				end
			end
		end

		return #FixedHitboxes == 0 and nil or FixedHitboxes
	end)

	-- Picks the best aimbot position
	ENV.CreateFunction("GetAimbotPosition", function(Entity, Hitboxes, IsBacktrack)
		local FixedHitboxes = GetAvailablePositions(Entity, Hitboxes)
		if not FixedHitboxes then return nil end

		for GroupIndex = 1, #Cache.AimbotData.ScanOrder do
			local Hitgroup = Cache.AimbotData.ScanOrder[GroupIndex]
			if not Hitboxes[Hitgroup] then continue end

			for i = 1, #Hitboxes[Hitgroup] do
				local CurrentPosition = Hitboxes[Hitgroup][i]
				if not InFOV(CurrentPosition) then continue end

				if IsBacktrack then
					local Valid, _, Fraction = IsVisible(CurrentPosition, Entity)

					if Valid or Fraction >= 0.99 then
						return CurrentPosition, Hitgroup
					end
				else
					if IsVisible(CurrentPosition, Entity) then
						return CurrentPosition, Hitgroup
					end
				end
			end
		end

		return nil
	end)

	-- Fixes rotation movement
	ENV.CreateFunction("FixMovement", function(Command)
		local CommandViewAngles = Command:GetViewAngles()

		local Yaw1, Yaw2

		if Cache.FacingAngle.yaw < 0 then
			Yaw1 = Cache.FacingAngle.yaw + 360
		else
			Yaw1 = Cache.FacingAngle.yaw
		end

		if CommandViewAngles.yaw < 0 then
			Yaw2 = CommandViewAngles.yaw + 360
		else
			Yaw2 = CommandViewAngles.yaw
		end

		local DeltaYaw

		if Yaw2 < Yaw1 then
			DeltaYaw = math.abs(Yaw2 - Yaw1)
		else
			DeltaYaw = 360 - math.abs(Yaw1 - Yaw2)
		end

		DeltaYaw = math.rad(360 - DeltaYaw)

		local ForwardSpeed = Command:GetForwardMove()
		local SideSpeed = Command:GetSideMove()

		Command:SetForwardMove(math.cos(DeltaYaw) * ForwardSpeed + math.cos(DeltaYaw + 90) * SideSpeed)
		Command:SetSideMove(math.sin(DeltaYaw) * ForwardSpeed + math.sin(DeltaYaw + 90) * SideSpeed)
	end)

	-- Gets the lowercase ammo name of the weapon
	ENV.CreateFunction("GetWeaponAmmoName", function(Weapon)
		if Weapon.Primary and Weapon.Primary.Ammo then
			return string.lower(Weapon.Primary.Ammo)
		else
			return string.lower(tostring(game.GetAmmoName(Weapon:GetPrimaryAmmoType())))
		end
	end)

	-- Shorthand for CW and similar
	ENV.CreateFunction("CWCanPenetrate", function(Weapon, TraceData)
		if Cache.WeaponData.AutoWall.Cancellers[TraceData.MatType] or (Weapon.CanPenetrate ~= nil and not Weapon.CanPenetrate) then
			return false
		end

		local Entity = TraceData.Entity
		if IsValid(Entity) and (Entity:IsPlayer() or Entity:IsNPC()) then
			return false
		end

		return -TraceData.Normal:Dot(TraceData.HitNormal) > 0.26
	end)

	-- Gets the maximum distance a weapon can penetrate (70-80% accurate)
	ENV.CreateFunction("GetWeaponPenetrationDistance", function(Weapon, TraceData)
		local Base = GetWeaponBase(Weapon)

		if Cache.WeaponData.AutoWall.Functions[Base] then
			return Cache.WeaponData.AutoWall.Functions[Base](Weapon, TraceData)
		end

		return nil
	end)

	-- Tests if a weapon can penetrate the current trace
	ENV.CreateFunction("WeaponCanPenetrate", function(Weapon, TraceData, Target, TargetPos)
		local MaxDistance, MaxTimes = GetWeaponPenetrationDistance(Weapon, TraceData)
		if not MaxDistance then return false end

		if not Weapon:IsScripted() then
			return TraceData.Entity == Target
		end

		local TraceOutput = {} -- Create our own here to avoid interference
		local Trace = {
			start = TargetPos,
			endpos = TraceData.HitPos,
			filter = {Target},
			mask = MASK_SHOT,
			output = TraceOutput
		}

		util.TraceLine(Trace)

		local CurTimes = 1
		local LastPos = TraceOutput.HitPos

		local World = game.GetWorld()
		local IsTFA = GetWeaponBase(Weapon) == "tfa"
		if IsTFA then MaxDistance = MaxDistance / 2 end

		while CurTimes <= MaxTimes do
			if TraceOutput.Entity == World then
				local OriginalEndPos = Trace.endpos

				for i = 1, 75 do
					Trace.start = TraceOutput.HitPos - (TraceData.Normal * 10)
					Trace.endpos = Trace.start

					util.TraceLine(Trace)

					if not TraceOutput.HitWorld then break end
				end

				Trace.endpos = OriginalEndPos
			else
				if TraceOutput.Entity == Target then break end

				local Entity = TraceOutput.Entity
				Trace.start = LastPos

				util.TraceLine(Trace)

				Trace.start = TraceOutput.HitPos - TraceData.Normal
				Trace.endpos = LastPos
				Trace.filter[2] = Entity

				util.TraceLine(Trace)
			end

			local CurDistance
			if IsTFA then
				CurDistance = TraceOutput.HitPos:Distance(LastPos) / 88.88
			else
				CurDistance = math.floor(TraceOutput.HitPos:DistToSqr(LastPos))
			end

			if CurDistance > MaxDistance then return false end

			if TraceOutput.Hit then
				LastPos = TraceOutput.HitPos
			else
				local OriginalEndPos = TraceData.HitPos

				Trace.endpos = TraceData.HitPos

				util.TraceLine(Trace)

				Trace.endpos = OriginalEndPos

				if TraceOutput.Hit then
					LastPos = TraceOutput.HitPos
				else
					if IsTFA then
						CurDistance = TraceOutput.HitPos:Distance(LastPos) / 88.88
					else
						CurDistance = math.floor(TraceOutput.HitPos:DistToSqr(LastPos))
					end

					if CurDistance <= MaxDistance then
						break
					end
				end
			end

			CurTimes = CurTimes + 1
		end

		return CurTimes <= MaxTimes, CurTimes
	end)

	-- Adjusts for aim punch
	ENV.CreateFunction("CalculateAntiRecoil", function(Weapon)
		return (Weapon:IsScripted() or Weapon:GetClass() == "weapon_pistol") and Angle(0, 0, 0) or Cache.LocalPlayer:GetViewPunchAngles()
	end)

	-- Adjusts for bullet spread
	ENV.CreateFunction("CalculateAntiSpread", function(Weapon, Command, ForwardAngle)
		if not Variables.AntiSpread then return end

		if Weapon:GetClass() == "weapon_pistol" then
			Command:SetRandomSeed(33)
			return
		end

		local WeaponCone = Cache.WeaponData.AntiSpread.Cones[Weapon:GetClass()]
		if not WeaponCone then return end

		if type(WeaponCone) == "function" then
			WeaponCone = WeaponCone(Weapon, Command)
		end

		if Cache.WeaponData.AntiSpread.BaseFunctions[GetWeaponBase(Weapon)] then
			Cache.WeaponData.AntiSpread.BaseFunctions[GetWeaponBase(Weapon)](Weapon, Command, WeaponCone)
		end

		local Seed = Command:GetRandomSeed()

		local X = Cache.WeaponData.AntiSpread.Seeds[Seed].X
		local Y = Cache.WeaponData.AntiSpread.Seeds[Seed].Y

		local Forward = ForwardAngle:Forward()
		local Right = ForwardAngle:Right()
		local Up = ForwardAngle:Up()

		local SpreadVector = Forward + (X * WeaponCone.x * Right * -1) + (Y * WeaponCone.y * Up * -1)
		ForwardAngle:Set(SpreadVector:Angle())
	end)

	-- Moves the position into place based off the entity's movement (Nothing advanced, just some simple velocity prediction)
	ENV.CreateFunction("PredictTargetPosition", function(Position, Entity)
		local Velocity = Entity:GetAbsVelocity()
		if Velocity:IsZero() then return end

		Velocity:Mul(RealFrameTime()) -- This isn't a pointer it's a newly created vector so it's fine to do this
		Position:Add(Velocity)
	end)

	-- Creates new backtrack points
	ENV.CreateFunction("BacktrackCreate", function()
		for i = 1, #Cache.PlayerList do
			local Player = Cache.PlayerList[i]
			if not IsValid(Player) or not IsPlayerTargetable(Player) then continue end

			if not Cache.BacktrackData[Player] then
				Cache.BacktrackData[Player] = {}
				Log("Created backtrack table for '{Gray}", Player:GetName(), "{$Reset}'")
			end

			local SimulationTime = GetEntitySimulationTime(Player)

			Cache.BacktrackData[Player][#Cache.BacktrackData[Player] + 1] = {
				Player = Player,
				Hitboxes = GetEntityHitboxes(Player),
				SimulationTime = SimulationTime,
				SimulationTick = TimeToTick(SimulationTime)
			}
		end
	end)

	-- Removes old/invalid backtrack points
	ENV.CreateFunction("BacktrackRemove", function()
		local CurTime = GetServerTime()

		for i = 1, #Cache.PlayerList do
			local Player = Cache.PlayerList[i]
			if not IsValid(Player) then continue end

			local BacktrackData = Cache.BacktrackData[Player]
			if not BacktrackData then continue end

			for BacktrackIndex = #BacktrackData, 1, -1 do
				local BacktrackCurTime = BacktrackData[BacktrackIndex].SimulationTime

				if CurTime - BacktrackCurTime > Variables.Backtrack.Amount or BacktrackCurTime > CurTime then
					table.remove(BacktrackData, BacktrackIndex)
					continue
				end
			end
		end

		collectgarbage("step") -- :)
	end)

	--------------------------- Setup Stuff ---------------------------

	local Cache = ENV.Cache

	-- Colors
	Cache.Colors.White = ENV.Color(255, 255, 255, 255)
	Cache.Colors.Black = ENV.Color(0, 0, 0, 255)
	Cache.Colors.Red = ENV.Color(255, 0, 0, 255)
	Cache.Colors.Green = ENV.Color(0, 255, 0, 255)
	Cache.Colors.Orange = ENV.Color(255, 150, 0, 255)
	Cache.Colors.Gray = ENV.Color(175, 175, 175)
	Cache.Colors.Lavender = ENV.Color(165, 125, 255, 255)
	Cache.Colors.Purple = ENV.Color(125, 0, 255, 255)
	Cache.Colors.Teal = ENV.Color(0, 180, 180)

	ENV.Variables.FOV.Colors.Outline = Cache.Colors.White
	ENV.Variables.FOV.Colors.Fill = ENV.Color(255, 255, 255, 5)

	ENV.Log("Setting up Cache") -- This needs the colors

	-- Screen
	Cache.ScreenData.Width = ENV.ScrW()
	Cache.ScreenData.Height = ENV.ScrH()

	Cache.ScreenData.Center.X = ENV.math.floor(Cache.ScreenData.Width / 2)
	Cache.ScreenData.Center.Y = ENV.math.floor(Cache.ScreenData.Height / 2)

	-- ConVars
	Cache.ConVars.cl_interp = ENV.GetConVar("cl_interp")
	Cache.ConVars.cl_interp_ratio = ENV.GetConVar("cl_interp_ratio")
	Cache.ConVars.cl_interpolate = ENV.GetConVar("cl_interpolate")
	Cache.ConVars.cl_updaterate = ENV.GetConVar("cl_updaterate")

	Cache.ConVars.sv_client_max_interp_ratio = ENV.GetConVar("sv_client_max_interp_ratio")
	Cache.ConVars.sv_client_min_interp_ratio = ENV.GetConVar("sv_client_min_interp_ratio")
	Cache.ConVars.sv_maxunlag = ENV.GetConVar("sv_maxunlag")
	Cache.ConVars.sv_maxupdaterate = ENV.GetConVar("sv_maxupdaterate")
	Cache.ConVars.sv_minupdaterate = ENV.GetConVar("sv_minupdaterate")

	Cache.ConVars.m_pitch = ENV.GetConVar("m_pitch")
	Cache.ConVars.m_yaw = ENV.GetConVar("m_yaw")
	Cache.ConVars.view_recoil_tracking = ENV.GetConVar("view_recoil_tracking")

	Cache.ConVars.AutoWall.ArcCW = ENV.GetConVar("arccw_enable_penetration")
	Cache.ConVars.AutoWall.M9K = ENV.GetConVar("M9KDisablePenetration")
	Cache.ConVars.AutoWall.TFA = ENV.GetConVar("sv_tfa_bullet_penetration")
	Cache.ConVars.AutoWall.TFA_HardLimit = ENV.GetConVar("sv_tfa_penetration_hardlimit")
	Cache.ConVars.AutoWall.TFA_Multiplier = ENV.GetConVar("sv_tfa_bullet_penetration_power_mul")

	Cache.ConVars.AntiSpread.ai_shot_bias_min = ENV.GetConVar("ai_shot_bias_min")
	Cache.ConVars.AntiSpread.ai_shot_bias_max = ENV.GetConVar("ai_shot_bias_max")

	-- Uh
	Cache.TickInterval = ENV.engine.TickInterval()
	Cache.LocalPlayer = ENV.LocalPlayer()
	Cache.FacingAngle = Cache.LocalPlayer:EyeAngles()

	Cache.ViewData.Angles = Cache.FacingAngle

	Cache.Textures.White = ENV.surface.GetTextureID("vgui/white")

	ENV.Log("'{Gray}sv_client_max_interp_ratio{$Reset}' is at {Gray}'", Cache.ConVars.sv_client_max_interp_ratio:GetFloat(), "{$Reset}'")
	ENV.Log("'{Gray}sv_client_min_interp_ratio{$Reset}' is at {Gray}'", Cache.ConVars.sv_client_min_interp_ratio:GetFloat(), "{$Reset}'")
	ENV.Log("'{Gray}sv_maxunlag{$Reset}' is at {Gray}'", Cache.ConVars.sv_maxunlag:GetFloat(), "{$Reset}'")
	ENV.Log("'{Gray}sv_maxupdaterate{$Reset}' is at {Gray}'", Cache.ConVars.sv_maxupdaterate:GetInt(), "{$Reset}'")
	ENV.Log("'{Gray}sv_minupdaterate{$Reset}' is at {Gray}'", Cache.ConVars.sv_minupdaterate:GetInt(), "{$Reset}'")

	-- Weapon things

	ENV.Log("Setting up AutoShoot base functions")

	Cache.WeaponData.AutoShoot.BaseFunctions.bobs = ENV.RegisterFunction(function(self)
		if self:Clip1() < 1 then return false end
		if self:GetNWBool("Reloading") then return false end

		local Owner = self:GetOwner()

		if not Owner:IsPlayer() then return false end
		if Owner:KeyDown(IN_SPEED) or Owner:KeyDown(IN_RELOAD) then return false end

		return true
	end)

	Cache.WeaponData.AutoShoot.BaseFunctions.cw = ENV.RegisterFunction(function(self)
		if self:Clip1() == 0 then return false end
		if not self:canFireWeapon(1) or not self:canFireWeapon(2) or not self:canFireWeapon(3) then return false end
		if self:GetOwner():KeyDown(IN_USE) and rawget(rawget(CustomizableWeaponry, "quickGrenade"), "canThrow")(self) then return false end
		if self.dt.State == CW_AIMING and self.dt.M203Active and self.M203Chamber then return false end
		if self.dt.Safe then return false end
		if self.BurstAmount and self.BurstAmount > 0 then return false end

		return true
	end)

	Cache.WeaponData.AutoShoot.BaseFunctions.fas2 = ENV.RegisterFunction(function(self)
		if self:Clip1() <= 0 then return false end

		local Owner = self:GetOwner()

		if Owner:KeyDown(IN_USE) and self:CanThrowGrenade() then return false end
		if Owner:WaterLevel() >= 3 then return false end

		if self.FireMode == "safe" then return false end
		if self.BurstAmount > 0 and self.dt.Shots >= self.BurstAmount then return false end
		if self.ReloadState ~= 0 then return false end
		if self.dt.Status == FAS_STAT_CUSTOMIZE then return false end
		if self.Cooking or self.FuseTime then return false end
		if self.dt.Status == FAS_STAT_SPRINT or self.dt.Status == FAS_STAT_QUICKGRENADE then return false end
		if self.CockAfterShot and not self.Cocked then return false end

		return true
	end)

	Cache.WeaponData.AutoShoot.BaseFunctions.tfa = ENV.RegisterFunction(function(self)
		local RunResult = hook.Run("TFA_PreCanPrimaryAttack", self)
		if RunResult ~= nil then return RunResult end

		local Status = self:GetStatus()
		local EnumTable = rawget(TFA, "Enum")
		if Status == rawget(EnumTable, "STATUS_RELOADING_WAIT") or Status == rawget(EnumTable, "STATUS_RELOADING") then return false end

		if self:IsSafety() then return false end
		if self:GetSprintProgress() >= 0.1 and not self:GetStatL("AllowSprintAttack", false) then return false end
		if self:GetStatL("Primary.ClipSize") <= 0 and self:Ammo1() < self:GetStatL("Primary.AmmoConsumption") then return false end
		if self:GetPrimaryClipSize(true) > 0 and self:Clip1() < self:GetStatL("Primary.AmmoConsumption") then return false end
		if self:GetStatL("Primary.FiresUnderwater") == false and self:GetOwner():WaterLevel() >= 3 then return false end

		RunResult = hook.Run("TFA_CanPrimaryAttack", self)
		if RunResult ~= nil then return RunResult end

		if self:CheckJammed() then return false end

		return true
	end)

	Cache.WeaponData.AutoShoot.BaseFunctions.arccw = ENV.RegisterFunction(function(self)
		if IsValid(self:GetHolster_Entity()) then return false end
		if self:GetHolster_Time() > 0 then return false end
		if self:GetReloading() then return false end
		if self:GetWeaponOpDelay() > CurTime() then return false end
		if self:GetHeatLocked() then return false end
		if self:GetState() == rawget(ArcCW, "STATE_CUSTOMIZE") then return false end
		if self:BarrelHitWall() > 0 then return false end
		if self:GetNWState() == rawget(ArcCW, "STATE_SPRINT") and not (self:GetBuff_Override("Override_ShootWhileSprint", self.ShootWhileSprint)) then return false end
		if (self:GetBurstCount() or 0) >= self:GetBurstLength() then return false end
		if self:GetNeedCycle() then return false end
		if self:GetCurrentFiremode().Mode == 0 then return false end
		if self:GetBuff_Override("Override_TriggerDelay", self.TriggerDelay) and self:GetTriggerDelta() < 1 then return false end
		if self:GetBuff_Hook("Hook_ShouldNotFire") then return false end
		if self:GetBuff_Hook("Hook_ShouldNotFireFirst") then return false end

		return true
	end)

	ENV.Log("Setting up AutoWall functions")

	-- https://github.com/awesomeusername69420/miscellaneous-gmod-stuff/blob/main/Cheaterino/AutoWallTest.lua

	Cache.WeaponData.AutoWall.Functions.bobs = ENV.RegisterFunction(function(self, TraceData)
		if Cache.ConVars.AutoWall.M9K:GetBool() then
			return nil
		end

		local DataTable = Cache.WeaponData.AutoWall.Limits[GetWeaponAmmoName(self)]
		if not DataTable then return nil end

		return DataTable[1], DataTable[2]
	end)

	Cache.WeaponData.AutoWall.Functions.tfa = ENV.RegisterFunction(function(self, TraceData)
		if not Cache.ConVars.AutoWall.TFA:GetBool() then
			return nil
		end

		local ForceMultiplier = self:GetAmmoForceMultiplier()
		local PenetrationMultiplier = self:GetPenetrationMultiplier(TraceData.MatType)
		local ConVarMultiplier = Cache.ConVars.AutoWall.TFA_Multiplier:GetFloat()

		local DataTable = Cache.WeaponData.AutoWall.Limits[GetWeaponAmmoName(self)]
		local MaxPen = math.Clamp(DataTable and DataTable[2] or 1, 0, Cache.ConVars.AutoWall.TFA_HardLimit:GetInt())

		return math.Truncate(((ForceMultiplier / PenetrationMultiplier) * ConVarMultiplier) * 0.9, 5), MaxPen
	end)

	Cache.WeaponData.AutoWall.Functions.arccw = ENV.RegisterFunction(function(self, TraceData)
		if not Cache.ConVars.AutoWall.ArcCW:GetBool() then
			return nil
		end

		local DataTable = Cache.WeaponData.AutoWall.Limits[GetWeaponAmmoName(self)]
		return math.pow(self.Penetration, 2), DataTable and DataTable[2] or 1
	end)

	Cache.WeaponData.AutoWall.Functions.cw = ENV.RegisterFunction(function(self, TraceData)
		if not CWCanPenetrate(self, TraceData) then return nil end

		local Strength = self.PenStr * self.PenMod
		local Multiplier = self.PenetrationMaterialInteraction and self.PenetrationMaterialInteraction[TraceData.MatType] or 1
		return math.pow(Strength, 2) + (Strength * Multiplier), 1
	end)

	Cache.WeaponData.AutoWall.Functions.fas2 = ENV.RegisterFunction(function(self, TraceData)
		if not CWCanPenetrate(self, TraceData) then return nil end

		local Strength = self.PenStr * self.PenMod
		local Multiplier = Cache.WeaponData.AutoWall.Multipliers[TraceData.MatType] or 1
		return math.pow(Strength, 2) + (Strength * Multiplier), 1
	end)

	Cache.WeaponData.AutoWall.Functions.swb = ENV.RegisterFunction(function(self, TraceData)
		if not CWCanPenetrate(self, TraceData) then return nil end

		local DataTable = Cache.WeaponData.AutoWall.Limits[GetWeaponAmmoName(self)]
		if not DataTable then return nil end

		local Multiplier = Cache.WeaponData.AutoWall.Multipliers[TraceData.MatType] or 1
		return DataTable[1] * Multiplier * self.PenMod, 1
	end)

	ENV.Log("Setting up AntiSpread seeds")

	-- Cleaned up version of Homonovus' generation
	do -- Do inside of a do oh my goodness what will he think of next
		local RandomStream = ENV.CUniformRandomStream.New()

		local ShotBiasMin = Cache.ConVars.AntiSpread.ai_shot_bias_min:GetFloat()
		local ShotBiasMax = Cache.ConVars.AntiSpread.ai_shot_bias_max:GetFloat()
		local ShotBiasDif = (ShotBiasMax - ShotBiasMin) + ShotBiasMin

		local Flatness = ENV.math.abs(ShotBiasDif) / 2
		local iFlatness = 1 - Flatness

		for Seed = 0, 255 do
			RandomStream:SetSeed(Seed)

			local FirstRan = false
			local X, Y, Z = 0, 0, 0

			while true do
				if Z <= 1 and FirstRan then break end

				X = (RandomStream:RandomFloat(-1, 1) * Flatness) + (RandomStream:RandomFloat(-1, 1) * iFlatness)
				Y = (RandomStream:RandomFloat(-1, 1) * Flatness) + (RandomStream:RandomFloat(-1, 1) * iFlatness)

				if ShotBiasDif < 0 then
					X = X >= 0 and 1 - X or -1 - X
					Y = Y >= 0 and 1 - Y or -1 - Y
				end

				Z = (X * X) + (Y * Y)
				FirstRan = true
			end

			Cache.WeaponData.AntiSpread.Seeds[Seed] = {
				X = X,
				Y = Y,
				Z = Z
			 }

			--ENV.Log("AntiSpread seed '{Gray}", Seed, "{$Reset}' is at {Gray}X{$Reset}: {Gray}", X, " Y{$Reset}: {Gray}", Y, " Z{$Reset}: {Gray}", Z)
		end
	end

	ENV.Log("Setting up AntiSpread functions")

	Cache.WeaponData.AntiSpread.BaseFunctions.bobs = ENV.RegisterFunction(function(Weapon, Command, WeaponCone) -- Bob is a simple man
		if Weapon:GetNWBool("M9K_Ironsights") or Command:KeyDown(IN_ATTACK2) then -- GetIronsights causes problems on some servers (Fuck you LBG) so do it manually
			WeaponCone.x = Weapon.Primary.IronAccuracy
			WeaponCone.y = Weapon.Primary.IronAccuracy
		else
			WeaponCone.x = Weapon.Primary.Spread
			WeaponCone.y = Weapon.Primary.Spread
		end
	end)

	Cache.WeaponData.AntiSpread.Storage.weapon_glock_hl1_attack = ENV.Vector(0.1, 0.1, 0.1)
	Cache.WeaponData.AntiSpread.Storage.weapon_glock_hl1_neutral = ENV.Vector(0.01, 0.01, 0.01)
	Cache.WeaponData.AntiSpread.Cones.weapon_glock_hl1 = ENV.RegisterFunction(function(Weapon, Command)
		if Command:KeyDown(IN_ATTACK) then
			return Cache.WeaponData.AntiSpread.Storage.weapon_glock_hl1_attack
		else
			return Cache.WeaponData.AntiSpread.Storage.weapon_glock_hl1_neutral
		end
	end)

	Cache.WeaponData.AntiSpread.Storage.weapon_shotgun_hl1_attack = ENV.Vector(0.17432, 0.04358)
	Cache.WeaponData.AntiSpread.Storage.weapon_shotgun_hl1_neutral = ENV.Vector(0.08716, 0.04358)
	Cache.WeaponData.AntiSpread.Cones.weapon_shotgun_hl1 = ENV.RegisterFunction(function(Weapon, Command)
		if Command:KeyDown(IN_ATTACK) then
			return Cache.WeaponData.AntiSpread.Storage.weapon_shotgun_hl1_attack
		else
			return Cache.WeaponData.AntiSpread.Storage.weapon_shotgun_hl1_neutral
		end
	end)

	ENV.Log("Setting up menu")

	local Main = vgui.Create("DFrame")
	Main:SetSize(400, 575)
	Main:Center()
	Main:SetTitle("proxi Aimbot")
	Main:SetVisible(false)
	Main:SetDeleteOnClose(false)
	Main:SetSkin("Default")

	Cache.Menu = Main

	ENV.concommand.Add("pa_menu", ENV.RegisterFunction(function()
		Cache.Menu:SetVisible(true)
		Cache.Menu:MakePopup()
	end))

	Main._MenuItems = {}

	Main._Container = vgui.Create("DPanel", Main)
	Main._Container:SetSize(Main:GetSize())

	function Main:AddCheckbox(Inline, Indent, Label, Table, Key)
		local Checkbox = vgui.Create("DCheckBoxLabel", self._Container)
		Checkbox:SetTextColor(Cache.Colors.Black)
		Checkbox:SetText(Label)
		Checkbox:SetSkin("Default")

		Checkbox._Table = Table
		Checkbox._Key = Key
		Checkbox._Indent = Indent
		Checkbox._Inline = Inline

		Checkbox:SetChecked(Table[Key])

		function Checkbox:OnChange(NewValue)
			self._Table[self._Key] = NewValue
		end

		self._MenuItems[#self._MenuItems + 1] = Checkbox

		return Checkbox
	end

	function Main:AddSlider(Inline, Indent, Label, Min, Max, Decimals, Table, Key)
		local Slider = vgui.Create("DNumSlider", self._Container)
		Slider:SetDark(true)
		Slider:SetMinMax(Min, Max)
		Slider:SetDecimals(Decimals)
		Slider:SetWide(self:GetWide() - (Indent * 25) - 15)
		Slider:SetSkin("Default")

		Slider._Table = Table
		Slider._Key = Key
		Slider._Indent = Indent
		Slider._Inline = Inline

		Slider.SetValue = Data.Environment.RegisterFunction(function(self, NewValue)
			NewValue = math.Clamp(math.Round(NewValue, self:GetDecimals()), self:GetMin(), self:GetMax())
			if self:GetValue() == NewValue then return end

			self.Scratch:SetValue(NewValue)
			self:ValueChanged(NewValue)
		end)

		Slider:SetValue(Table[Key])

		Slider.Label:SetVisible(false)

		local NewLabel = Data.Environment.vgui.Create("DLabel", Slider) -- Custom label to fix retarded spacing
		NewLabel:Dock(LEFT)
		NewLabel:SetText(Label)
		NewLabel:SetTextColor(Data.Environment.Cache.Colors.Black)
		NewLabel:SetSize(Data.Environment.surface.GetTextSize(Label))

		function Slider:OnValueChanged(NewValue)
			self._Table[self._Key] = NewValue
		end

		self._MenuItems[#self._MenuItems + 1] = Slider

		return Slider
	end

	function Main:AddBinder(Inline, Indent, Table, Key)
		local Binder = vgui.Create("DBinder", self._Container)
		Binder:SetValue(Table[Key])
		Binder:SetTall(15)
		Binder:SetSkin("Default")

		Binder._Table = Table
		Binder._Key = Key
		Binder._Indent = Indent
		Binder._Inline = Inline

		function Binder:OnChange(NewValue)
			self._Table[self._Key] = NewValue
		end

		self._MenuItems[#self._MenuItems + 1] = Binder

		return Binder
	end

	function Main:AddColorBox(Inline, Indent, Table, Key)
		local ColorBox = vgui.Create("DButton", self._Container)
		ColorBox:SetSize(15, 15)
		ColorBox:SetText("")

		ColorBox._Table = Table
		ColorBox._Key = Key
		ColorBox._Indent = Indent
		ColorBox._Inline = Inline

		function ColorBox:DoClick()
			local ScreenX, ScreenY = self:LocalToScreen(0, 0)

			local ColorPanel = Data.Environment.vgui.Create("DPanel")
			ColorPanel:SetSize(190, 130)
			ColorPanel:DockPadding(4, 4, 4, 4)
			ColorPanel:SetPos(ScreenX, ScreenY + self:GetTall() + 5)
			ColorPanel:MakePopup()

			local Mixer = Data.Environment.vgui.Create("DColorMixer", ColorPanel)
			Mixer:Dock(FILL)
			Mixer:SetPalette(false)
			Mixer:SetWangs(false)
			Mixer:SetColor(self._Table[self._Key])
			Mixer:SetSkin("Default")

			Mixer._Table = self._Table
			Mixer._Key = self._Key

			Mixer.ValueChanged = Data.Environment.RegisterFunction(function(self, NewColor)
				debug.setmetatable(NewColor, _R.Color)
				self._Table[self._Key] = NewColor
			end)

			ColorPanel._Mixer = Mixer

			function ColorPanel:PerformLayout(Width, Height)
				function self:Think()
					if not self:HasFocus() then
						self:Remove()
					end
				end

				self._Mixer:Dock(FILL)
			end

			ColorPanel:InvalidateLayout()

			ColorPanel.Paint = Data.Environment.RegisterFunction(function(self, Width, Height)
				surface.SetDrawColor(Cache.Colors.White)
				surface.DrawRect(1, 1, Width - 2, Height - 2)

				surface.SetDrawColor(Cache.Colors.Black)
				surface.DrawOutlinedRect(0, 0, Width, Height)
			end)
		end

		ColorBox.Paint = Data.Environment.RegisterFunction(function(self, Width, Height)
			surface.SetDrawColor(Cache.Colors.Black)
			surface.DrawRect(0, 0, Width, Height)
			surface.DrawOutlinedRect(0, 0, Width, Height)

			surface.SetDrawColor(self._Table[self._Key])
			surface.DrawRect(1, 1, Width - 2, Height - 2)
		end)

		self._MenuItems[#self._MenuItems + 1] = ColorBox

		return ColorBox
	end

	Main._OriginalPerformLayout = Main.PerformLayout
	function Main:PerformLayout(Width, Height)
		self:_OriginalPerformLayout(Width, Height)

		self._Container:Dock(FILL)
		self._Container:SetPos(0, 0)
		self._Container:SetSize(Width, Height)

		local X, Y = 15, 15

		for i = 1, #self._MenuItems do
			local v = self._MenuItems[i]

			if v._Inline then
				Y = Y - 25
			end

			local LastItem = self._MenuItems[i - 1]

			-- Messy 1 liner, couldn't be fucked
			v:SetPos(v._OverrideX and v._OverrideX:GetX() or X + (v._Inline and (LastItem and (LastItem:GetX() + LastItem:GetWide()) or 0) or 0) + (v._Indent * 25), Y - (v:GetName() == "DNumSlider" and 10 or 0)) -- Sliders are sped

			Y = Y + 25
		end
	end

	Main:AddCheckbox(false, 0, "Enabled", ENV.Variables, "Enabled")
	Main:AddCheckbox(false, 1, "On Key", ENV.Variables.Key, "Enabled")
	Main:AddBinder(true, 0, ENV.Variables.Key, "Code")
	Main:AddSlider(false, 1, "FOV", 0, 180, 0, ENV.Variables.FOV, "Amount")
	Main:AddCheckbox(false, 2, "Outline", ENV.Variables.FOV.Visible, "Outline")
	local FirstBox = Main:AddColorBox(true, 0, ENV.Variables.FOV.Colors, "Outline")
	Main:AddCheckbox(false, 2, "Fill", ENV.Variables.FOV.Visible, "Fill")
	Main:AddColorBox(true, 0, ENV.Variables.FOV.Colors, "Fill")._OverrideX = FirstBox
	Main:AddCheckbox(false, 1, "Silent", ENV.Variables, "Silent")
	Main:AddCheckbox(false, 1, "Fix Movement", ENV.Variables, "FixMovement")
	Main:AddCheckbox(false, 1, "Bullettime", ENV.Variables, "BulletTime")
	Main:AddCheckbox(false, 1, "Anti Spread", ENV.Variables, "AntiSpread")
	Main:AddCheckbox(false, 1, "Anti Recoil", ENV.Variables, "AntiRecoil")
	Main:AddCheckbox(false, 1, "Auto Shoot", ENV.Variables.AutoShoot, "Enabled")
	Main:AddCheckbox(false, 2, "Slow Fire", ENV.Variables.AutoShoot.Slow, "Enabled")
	Main:AddSlider(false, 2, "Wait Time", 0, 3, 2, ENV.Variables.AutoShoot.Slow, "Amount")
	Main:AddCheckbox(false, 1, "Auto Wall", ENV.Variables, "AutoWall")
	Main:AddCheckbox(false, 1, "Anti Taunt", ENV.Variables, "AntiTaunt")
	Main:AddCheckbox(false, 1, "Backtrack", ENV.Variables.Backtrack, "Enabled")
	Main:AddSlider(false, 2, "Amount", 0, 0.2, 2, ENV.Variables.Backtrack, "Amount")
	Main:AddCheckbox(false, 1, "Multi-point", ENV.Variables.MultiPoint, "Enabled")
	Main:AddCheckbox(false, 2, "Head", ENV.Variables.MultiPoint.Hitboxes, HITGROUP_HEAD)
	Main:AddCheckbox(false, 2, "Chest", ENV.Variables.MultiPoint.Hitboxes, HITGROUP_CHEST)
	Main:AddCheckbox(false, 2, "Stomach", ENV.Variables.MultiPoint.Hitboxes, HITGROUP_STOMACH)

	Main:InvalidateLayout()
end

--------------------------- Hook Setup ---------------------------

do
	local AddHook = Data.Environment.AddHook

	-- Grab + modify view data
	AddHook("CalcView", function(Player, Origin, Angles, FOV, ZNear, ZFar, ThisServerIsRetarded)
		if ThisServerRetarded then -- 208.103.169.66
			ZNear = ZFar
			ZFar = ThisServerIsRetarded
		end

		Angles:Set(Cache.FacingAngle)
		if not Variables.Enabled or not Variables.AntiRecoil then
			Angles:Add(Player:GetViewPunchAngles()) -- Modify it directly through reference rather than returning
		end

		-- Collect information
		if not Cache.ViewData.Origin then
			Cache.ViewData.Origin = Vector(Origin)
		else
			Cache.ViewData.Origin:Set(Origin)
		end

		if not Cache.ViewData.Angles then
			Cache.ViewData.Angles = Angle(Angles)
		else
			Cache.ViewData.Angles:Set(Angles)
		end

		Cache.ViewData.FOV = FOV
		Cache.ViewData.ZNear = ZNear
		Cache.ViewData.ZFar = ZFar
	end)

	-- Grab spread cones
	AddHook("EntityFireBullets", function(Entity, Data)
		if Entity ~= Cache.LocalPlayer then return end
		Cache.AimbotData.SlowShootTicks = 0 -- Prevent jank with things like the revolver
		if not IsFirstTimePredicted() then return end -- Retarded hook

		if Cache.AimbotData.Active and not Cache.AimbotData.Wait then
			-- Yeah it's a big line of text is there a problem?
			Log("Fired bullet towards '{Gray}", IsValid(Cache.AimbotData.Target) and Cache.AimbotData.Target:GetName() or "??UNKNOWN_PLAYER??", "{$Reset}' {Gray}({$Reset}Hitgroup: {Green}", Cache.AimbotData.Hitgroup, "{$Reset} {Gray}({Green}", Cache.HitgroupLookups[Cache.AimbotData.Hitgroup], "{Gray}) {$Reset}| Penetrations: {Green}", Cache.AimbotData.Penetrations, "{$Reset} | Backtrack Amount: ", Cache.AimbotData.BacktrackAmount == 0 and "{Red}" or (Cache.AimbotData.BacktrackAmount > Variables.Backtrack.Amount and "{Orange}" or "{Green}"), Cache.AimbotData.BacktrackAmount, " {$Reset}ms{Gray})")
			Cache.AimbotData.Wait = true -- Stop spam
		end

		local Weapon = Entity:GetActiveWeapon()
		if not Weapon:IsValid() then return end

		if not Cache.WeaponData.AntiSpread.Cones[Weapon:GetClass()] then
			Cache.WeaponData.AntiSpread.Cones[Weapon:GetClass()] = Vector(Data.Spread)
		end
	end)

	-- Readjusts everything
	AddHook("OnScreenSizeChanged", function()
		Cache.ScreenData.Width = ScrW()
		Cache.ScreenData.Height = ScrH()

		Cache.ScreenData.Center.X = math.floor(Cache.ScreenData.Width / 2)
		Cache.ScreenData.Center.Y = math.floor(Cache.ScreenData.Height / 2)

		table.Empty(Cache.Polygons) -- Will need regenerated for the new screensize
	end)

	-- Sets up facing angle
	AddHook("InputMouseApply", function(Command, MouseX, MouseY)
		if not Variables.Enabled or Cache.LocalPlayer:IsFrozen() then return end

		local Weapon = Cache.LocalPlayer:GetActiveWeapon()

		if IsValid(Weapon)  then
			if Weapon.FreezeMovement and Weapon:FreezeMovement() then return end -- GMod camera + whatever else may freeze rotation
			if Weapon:GetClass() == "weapon_physgun" and IsValid(Weapon:GetInternalVariable("m_hGrabbedEntity")) and (Command:KeyDown(IN_USE) or Cache.LocalPlayer:KeyDown(IN_USE)) then return end -- Physgun rotating (CUserCmd:KeyDown is jank in this hook)
		end

		Cache.FacingAngle.pitch = Cache.FacingAngle.pitch + (MouseY * Cache.ConVars.m_pitch:GetFloat())
		Cache.FacingAngle.yaw = Cache.FacingAngle.yaw - (MouseX * Cache.ConVars.m_yaw:GetFloat())

		FixAngle(Cache.FacingAngle)
	end)

	-- Used to fix view then CommandNumber is 0
	AddHook("CreateMove", function(Command)
		if not Variables.Enabled then
			Cache.FacingAngle = Command:GetViewAngles()
		end

		Command:SetViewAngles(Cache.FacingAngle)
	end)

	-- Run the aimbot
	AddHook("CreateMoveEx", function(Command)
		if not Variables.Enabled then Cache.AimbotData.Wait = false return end

		local Weapon = Cache.LocalPlayer:GetActiveWeapon()
		if not Weapon:IsValid() then Cache.AimbotData.Wait = false return end

		local KeyDown = Variables.Key.Enabled and input.IsButtonDown(Variables.Key.Code) or not Variables.Key.Enabled

		if (KeyDown or Command:KeyDown(IN_ATTACK)) and WeaponCanShoot(Weapon) then
			if not KeyDown then -- Standalone
				local NewForward = Angle(Cache.FacingAngle)

				proxi.StartPrediction(Command)
					if Variables.AntiSpread then CalculateAntiSpread(Weapon, Command, NewForward) end
					if Variables.AntiRecoil then NewForward:Sub(LocalPlayer():GetViewPunchAngles()) end
					FixAngle(NewForward)

					Command:SetViewAngles(NewForward)
				proxi.EndPrediction()

				return
			end

			if Variables.Backtrack.Enabled then
				BacktrackRemove()
			end

			local Target, Hitboxes, Penetrations, IsBacktrack, SimulationTick = GetAimbotTarget()
			if not IsValid(Target) then return end

			local Position, Hitgroup = GetAimbotPosition(Target, Hitboxes, IsBacktrack)
			if not Position then return end

			Cache.AimbotData.Active = true
			Cache.AimbotData.Target = Target
			Cache.AimbotData.Hitgroup = Hitgroup
			Cache.AimbotData.Penetrations = Penetrations
			Cache.AimbotData.BacktrackAmount = IsBacktrack and (GetServerTime() - TickToTime(SimulationTick)) or 0

			proxi.StartPrediction(Command)
				if IsBacktrack then
					Command:SetTickCount(SimulationTick)
				else
					PredictTargetPosition(Position, Target, IsBacktrack)
				end

				local Direction = (Position - Cache.LocalPlayer:EyePos()):Angle()

				if Variables.AutoShoot.Enabled then
					if Variables.AutoShoot.Slow.Enabled then
						if Cache.AimbotData.SlowShootTicks >= TimeToTick(Variables.AutoShoot.Slow.Amount) then
							Command:AddKey(IN_ATTACK)
						else
							Cache.AimbotData.SlowShootTicks = Cache.AimbotData.SlowShootTicks + 1
						end
					else
						Command:AddKey(IN_ATTACK)
					end
				end

				if not Variables.Silent then Cache.FacingAngle = Angle(Direction) end
				if Variables.AntiSpread then CalculateAntiSpread(Weapon, Command, Direction) end
				if Variables.AntiRecoil then Direction:Sub(CalculateAntiRecoil(Weapon)) end
				FixAngle(Direction)

				Command:SetViewAngles(Direction)
			proxi.EndPrediction()

			if Variables.FixMovement then FixMovement(Command) end

			return
		else
			Cache.AimbotData.Active = false
			Cache.AimbotData.Target = NULL
			Cache.AimbotData.Wait = false

			if not KeyDown then -- Let the next trigger happen immediately
				Cache.AimbotData.SlowShootTicks = math.huge
			end
		end
	end)

	-- Setup backtrack points
	AddHook("PostFrameStageNotify", function(Stage)
		if not Variables.Enabled or not Variables.Backtrack.Enabled then
			if not table.IsEmpty(Cache.BacktrackData) then
				table.Empty(Cache.BacktrackData)
			end

			return
		end

		if Stage ~= FRAME_NET_UPDATE_END then return end

		BacktrackCreate()
		BacktrackRemove()
	end)

	-- Draw the FOV circle
	AddHook("HUDPaint", function()
		if not Variables.Enabled then return end

		local Radius = math.floor(GetFOVRadius()) -- Floor to avoid decimal jank (Screenspace is integer only so it doesn't matter)
		if Radius <= 0 or Radius > Cache.ScreenData.Height then return end -- FOV is too big to render

		if Variables.FOV.Visible.Fill then
			if not Cache.Polygons[Radius] then -- Generate a new poly for this radius
				Cache.Polygons[Radius] = CreatePolygon(Cache.ScreenData.Center.X, Cache.ScreenData.Center.Y, Radius, 64)
			end

			surface.SetTexture(Cache.Textures.White)
			surface.SetDrawColor(Variables.FOV.Colors.Fill)
			surface.DrawPoly(Cache.Polygons[Radius])
		end

		if Variables.FOV.Visible.Outline then
			surface.SetDrawColor(Variables.FOV.Colors.Outline)
			surface.DrawCircle(Cache.ScreenData.Center.X, Cache.ScreenData.Center.Y, Radius, Variables.FOV.Colors.Outline)
		end
	end)

	-- Update LocalPlayer + Setup player list
	AddHook("Tick", function()
		Cache.LocalPlayer = LocalPlayer()

		local CurTime = SysTime()

		if CurTime - Cache.LastPlayerListUpdate >= 0.3 then
			table.Empty(Cache.PlayerList)

			local Players = player.GetAll()

			for i = 1, #Players do
				if Players[i] == Cache.LocalPlayer then continue end
				Cache.PlayerList[#Cache.PlayerList + 1] = Players[i]
			end

			Cache.LastPlayerListUpdate = CurTime
		end

		if Variables.AntiTaunt then
			for i = 1, #Cache.PlayerList do
				if not IsValid(Cache.PlayerList[i]) then continue end -- Don't make a variable to improve performance

				if Cache.PlayerList[i]:IsPlayingTaunt() then
					Cache.PlayerList[i]:AnimResetGestureSlot(GESTURE_SLOT_VCD)
				end
			end

			Cache.LastAntiTauntUpdate = CurTime
		end
	end)

	-- Damage logs
	AddHook("PlayerTraceAttack", function(Victim, DamageInfo) -- player_hurt is fucked and this doesn't work for things that don't fire bullets
		if not Variables.Enabled or not IsFirstTimePredicted() then return end
		if Victim == Cache.LocalPlayer or DamageInfo:GetAttacker() ~= Cache.LocalPlayer then return end

		local PreHealth = Victim:Health()

		timer.Simple(0.01, RegisterFunction(function() -- Stupid ass game
			if not IsValid(Victim) then return end

			local PostHealth = math.max(Victim:Health(), 0) -- Health can go negative
			if PreHealth == PostHealth then return end -- Faulted prediciton or player isn't hurtable

			local Max = math.max(PreHealth, PostHealth) -- Just in case some jank takes place
			local Min = math.min(PreHealth, PostHealth)

			Log("Damaged '{Gray}", Victim:GetName(), "{$Reset}' for {Red}", Max - Min, " {Gray}({Green}", Max, " {Gray}-> {Green}", Min, "{Gray})")
		end))
	end)

	-- Restore everything (Quite redundant but why not)
	AddHook("ShutDown", function()
		_G.proxi = proxi
	end)
end
