local Version = "0.16"
local Author = "QQQ"
if myHero.charName ~= "Rengar" then return end
local IsLoaded = "Predators Pride"
local AUTOUPDATE = true
---------------------------------------------------------------------
--- AutoUpdate for the script ---------------------------------------
---------------------------------------------------------------------
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_NAME = "Rengar - Predators Pride"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/bolqqq/BoLScripts/master/Rengar%20-%20Predators%20Pride.lua?chunk="..math.random(1, 1000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<font color=\"#FF794C\">["..IsLoaded.."]:</font> <font color=\"#FFDFBF\">"..msg..".</font>") end
if AUTOUPDATE then
    local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
    if ServerData then
        local ServerVersion = string.match(ServerData, "local Version = \"%d+.%d+\"")
        ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
        if ServerVersion then
            ServerVersion = tonumber(ServerVersion)
            if tonumber(Version) < ServerVersion then
                AutoupdaterMsg("A new version is available: ["..ServerVersion.."]")
                AutoupdaterMsg("The script is updating... please don't press [F9]!")
                DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function ()
				AutoupdaterMsg("Successfully updated! ("..Version.." -> "..ServerVersion.."), Please reload (double [F9]) for the updated version!") end) end, 3)
            else
                AutoupdaterMsg("Your script is already the latest version: ["..ServerVersion.."]")
            end
        end
    else
        AutoupdaterMsg("Error downloading version info!")
    end
end
---------------------------------------------------------------------
--- AutoDownload the required libraries -----------------------------
---------------------------------------------------------------------
local REQUIRED_LIBS = 
	{
		["VPrediction"] = "https://raw.github.com/honda7/BoL/master/Common/VPrediction.lua",
		["SOW"] = "https://raw.github.com/honda7/BoL/master/Common/SOW.lua"
	}
		
local DOWNLOADING_LIBS = false
local DOWNLOAD_COUNT = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<font color=\"#FF794C\">["..IsLoaded.."]:</font><font color=\"#FFDFBF\"> Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1

		print("<font color=\"#FF794C\">["..IsLoaded.."]:</font><font color=\"#FFDFBF\"> Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
	end
end

if DOWNLOADING_LIBS then return end
---------------------------------------------------------------------
--- Vars ------------------------------------------------------------
---------------------------------------------------------------------
-- Vars for Abilitys -- 
	local qRange = myHero.range + GetDistance(myHero.minBBox)
	local wRange = 400 -- for testing on 400 (normal 500)
	local eRange = 1000
	local eSpeed = 1500
	local eWidth = 70
	local eDelay = 0.250
	local wColor = ARGB(76, 255, 76,170)
	local eColor = ARGB(255, 255, 0,128)
	local TargetColor = ARGB(100,76,255,76)
	local Ferocity = 0
	local ignite = nil
	local qName = "Savagery"
	local wName = "Battle Roar"
	local eName = "Bola Strike"
	local rName = "Thrill of the Hunt"
	local allowSpells = true
-- Vars for TargetSelector --
	local ts
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 1000, true)
	ts.name = "Rengar"
-- Vars for JungleClear --
	JungleMobs = {}
	JungleFocusMobs = {}
-- Vars for LaneClear --
	enemyMinions = minionManager(MINION_ENEMY, 1000, myHero.visionPos, MINION_SORT_HEALTH_ASC)
-- Vars for Damage Calculations and Drawing --
	local iDmg = 0
	local qDmg = 0
	local qDmgE = 0
	local wDmg = 0
	local eDmg = 0
	local dfgDmg = 0
	local hxgDmg = 0
	local bwcDmg = 0
	local botrkDmg = 0
	local sheenDmg = 0
	local lichbaneDmg = 0
	local trinityDmg = 0
	local liandrysDmg = 0
	KillText = {}
	KillTextColor = ARGB(255, 255, 38,0)
	KillTextList = {		
						"Harass your enemy!", 		-- 01
						"Wait for your CD's!",		-- 02
						"Kill! - Ignite",			-- 03
						"Kill! - (Q)",				-- 04 
						"Kill! - (W)",				-- 05 
						"Kill! - (E)",				-- 06 
						"Kill! - (Q)+(Q2)",			-- 07 
						"Kill! - (Q)+(W)",			-- 08 
						"Kill! - (Q)+(E)",			-- 09 
						"Kill! - (W)+(E)",			-- 10
						"Kill! - (Q)+(W)+(E)",		-- 11 
						"Kill! - (Q)+(Q2)+(W)",		-- 12
						"Kill! - (Q)+(Q2)+(E)",		-- 13
						"Kill! - (Q)+(Q2)+(W)+(E)"	-- 14
					}
-- Vars for Autolevel --
	levelSequence = {
					startQ = { 1,2,3,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
					startW = { 2,1,3,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 },
					startE = { 3,1,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2 }
					}
-- Misc Vars --
	enemyHeroes = GetEnemyHeroes()
	Recalling = false
	VP = nil
	local RengarMenu
	local needHealharass = false
	local needHealjungle = false
	local needHealfarm = false
-- EmpMode --
	local EmpMode = nil
---------------------------------------------------------------------
--- Menu ------------------------------------------------------------
---------------------------------------------------------------------
function OnLoad()
		 JungleNames()
		 IgniteCheck()
		 VP = VPrediction()
		 rSOW = SOW(VP)
		 AddMenu()
		 --LFC--
	_G.oldDrawCircle = rawget(_G, 'DrawCircle')
	_G.DrawCircle = DrawCircle2
	PrintChat("<font color=\"#EFBFFF\"><b>"..IsLoaded.."</b> by <font color=\"#FFDC73\"><b>QQQ</b></font> sucessfully loaded! Version: <u><b>"..Version.."</b></u></font>")
	end
function AddMenu()
	-- Script Menu --
	RengarMenu = scriptConfig("Rengar - Predators Pride", "Rengar")
	
	-- Target Selector --
	RengarMenu:addTS(ts)
	
	-- Create SubMenu --
	RengarMenu:addSubMenu(""..myHero.charName..": Key Bindings", "KeyBind")
	RengarMenu:addSubMenu(""..myHero.charName..": Extra", "Extra")
	RengarMenu:addSubMenu(""..myHero.charName..": Orbwalk", "Orbwalk")
	RengarMenu:addSubMenu(""..myHero.charName..": SBTW-Combo", "SBTW")
	RengarMenu:addSubMenu(""..myHero.charName..": Harass", "rHarass")
	RengarMenu:addSubMenu(""..myHero.charName..": KillSteal", "KS")
	RengarMenu:addSubMenu(""..myHero.charName..": LaneClear", "Farm")
	RengarMenu:addSubMenu(""..myHero.charName..": JungleClear", "Jungle")
	RengarMenu:addSubMenu(""..myHero.charName..": Drawings", "Draw")
	
	-- KeyBind --
	RengarMenu.KeyBind:addParam("aimEkey","Throw predicted (E): ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
	RengarMenu.KeyBind:addParam("SBTWKey", "SBTW-Combo Key: ", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	RengarMenu.KeyBind:addParam("HarassKey","Harass Key: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
	RengarMenu.KeyBind:addParam("ClearKey", "Jungle- and LaneClear Key: ", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
	
	-- Extra --
	RengarMenu.Extra:addParam("AutoLevelSkills", "Auto Level Skills (Reload Script!)", SCRIPT_PARAM_LIST, 1, { "No Autolevel", "QWEQ - R>Q>E>W", "WQEQ - R>Q>E>W", "EQWQ - R>Q>E>W"})
	RengarMenu.Extra:addParam("extraInfo", "--- Packet Settings ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.Extra:addParam("packetUsage", "Use packets to cast spells: ", SCRIPT_PARAM_ONOFF, true)
	
	-- SOW-Orbwalking --
	rSOW:LoadToMenu(RengarMenu.Orbwalk)
	
	-- SBTW Combo --
	RengarMenu.SBTW:addParam("empPrioritySBTW", "Empowered Priority in SBTW", SCRIPT_PARAM_LIST, 3, {"Q-Priority", "W-Priority", "E-Priority"})
	RengarMenu.SBTW:addParam("sbtwHeal", "Emp(W) over Prio if hp below %: ",  SCRIPT_PARAM_SLICE, 25, 0, 100, -1)
	RengarMenu.SBTW:addParam("sbtwItems", "Use Items in Combo", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.SBTW:addParam("sbtwInfo", "", SCRIPT_PARAM_INFO, "")
	RengarMenu.SBTW:addParam("sbtwInfo", "--- Choose your abilitys for SBTW ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.SBTW:addParam("sbtwQ", "Use "..qName.." (Q) in Combo", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.SBTW:addParam("sbtwW", "Use "..wName.." (W) in Combo", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.SBTW:addParam("sbtwE", "Use "..eName.." (E) in Combo", SCRIPT_PARAM_ONOFF, true)
	
	-- Harass --
	RengarMenu.rHarass:addParam("empPriorityHarass", "Empowered Priority in Harass", SCRIPT_PARAM_LIST, 2, {"W-Priority", "E-Priority"})
	RengarMenu.rHarass:addParam("harassHeal", "Emp(W) over Prio if hp below %: ",  SCRIPT_PARAM_SLICE, 30, 0, 100, -1)
	RengarMenu.rHarass:addParam("harassInfo", "", SCRIPT_PARAM_INFO, "")
	RengarMenu.rHarass:addParam("harassInfo", "--- Choose your abilitys for Harass ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.rHarass:addParam("harassW","Use "..wName.." (W) in Harass", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.rHarass:addParam("harassE","Use "..eName.." (E) in Harass", SCRIPT_PARAM_ONOFF, true)
	
	-- KillSteal --
	RengarMenu.KS:addParam("AutoIgnite", "Use Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.KS:addParam("useSmartKS", "Use Smart KillSteal", SCRIPT_PARAM_ONOFF, true)
	
	-- Lane Clear --	
	RengarMenu.Farm:addParam("empPriorityFarm", "Empowered Priority in Farm", SCRIPT_PARAM_LIST, 2, {"Q-Priority", "W-Priority"})
	RengarMenu.Farm:addParam("farmHeal", "Emp(W) over Prio if HP below %: ",  SCRIPT_PARAM_SLICE, 20, 0, 100, -1)
	RengarMenu.Farm:addParam("farmInfo", "", SCRIPT_PARAM_INFO, "")
	RengarMenu.Farm:addParam("farmInfo", "--- Choose your abilitys for LaneClear ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.Farm:addParam("farmQ", "Farm with "..qName.." (Q): ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Farm:addParam("farmW", "Farm with "..wName.." (W): ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Farm:addParam("farmE", "Farm with "..eName.." (E): ", SCRIPT_PARAM_ONOFF, true)
	
	-- Jungle Clear --
	RengarMenu.Jungle:addParam("empPriorityJungle", "Empowered Priority in Jungle", SCRIPT_PARAM_LIST, 2, {"Q-Priority", "W-Priority"})
	RengarMenu.Jungle:addParam("jungleHeal", "Emp(W) over Prio if hp below %: ",  SCRIPT_PARAM_SLICE, 20, 0, 100, -1)
	RengarMenu.Jungle:addParam("jungleInfo", "", SCRIPT_PARAM_INFO, "")
	RengarMenu.Jungle:addParam("jungleInfo", "--- Choose your abilitys for JungleClear ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.Jungle:addParam("jungleQ", "Clear with "..qName.." (Q): ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Jungle:addParam("jungleW", "Clear with "..wName.." (W): ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Jungle:addParam("jungleE", "Clear with "..eName.." (E): ", SCRIPT_PARAM_ONOFF, true)
	
	-- Drawings --
	RengarMenu.Draw:addParam("drawW", "Draw W Range: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw:addParam("drawE", "Draw E Range: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw:addParam("drawKillText", "Draw KillText: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw:addParam("drawTarget", "Draw current target: ", SCRIPT_PARAM_ONOFF, false)
	-- LFC --
	RengarMenu.Draw:addSubMenu("LagFreeCircles: ", "LFC")
	RengarMenu.Draw.LFC:addParam("LagFree", "Activate Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
	RengarMenu.Draw.LFC:addParam("CL", "Length before Snapping", SCRIPT_PARAM_SLICE, 350, 75, 2000, 0)
	RengarMenu.Draw.LFC:addParam("CLinfo", "Higher length = Lower FPS Drops", SCRIPT_PARAM_INFO, "")
	-- Permashow --
	RengarMenu.Draw:addSubMenu("PermaShow: ", "PermaShow")
	RengarMenu.Draw.PermaShow:addParam("info", "--- Reload (Double F9) if you change the settings ---", SCRIPT_PARAM_INFO, "")
	RengarMenu.Draw.PermaShow:addParam("empPrioritySBTW", "Show empPrioritySBTW: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw.PermaShow:addParam("empPriorityHarass", "Show empPriorityHarass: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw.PermaShow:addParam("empPriorityFarm", "Show empPriorityFarm: ", SCRIPT_PARAM_ONOFF, true)
	RengarMenu.Draw.PermaShow:addParam("empPriorityJungle", "Show empPriorityJungle: ", SCRIPT_PARAM_ONOFF, true)

	-- Other --
	RengarMenu:addParam("Version", "Version", SCRIPT_PARAM_INFO, Version)
	RengarMenu:addParam("Author", "Author", SCRIPT_PARAM_INFO, Author)

	-- PermaShow --
	if RengarMenu.Draw.PermaShow.empPrioritySBTW
		then RengarMenu.SBTW:permaShow("empPrioritySBTW")
	end
	if RengarMenu.Draw.PermaShow.empPriorityHarass
		then RengarMenu.rHarass:permaShow("empPriorityHarass")
	end
	if RengarMenu.Draw.PermaShow.empPriorityFarm
		then RengarMenu.Farm:permaShow("empPriorityFarm")
	end
	if RengarMenu.Draw.PermaShow.empPriorityJungle
		then RengarMenu.Jungle:permaShow("empPriorityJungle")
	end
end
function OnTick()
	if myHero.dead then return end
	ts:update()
	Target = ts.target 
	Check()
	DamageCalculation()
	LFCfunc()
	AutoLevelMySkills()
	KeyBindings()
	
	-- Aim VPredicted E Function --
		if Target
			then
				if AimEKey then AimTheE(Target) end
				if RengarMenu.KS.AutoIgnite then AutoIgnite(Target) end	
		end
	if SBTWKey then SBTW() end
	if HarassKey then Harass() end
	if ClearKey then LaneClear() JungleClear() end
	if RengarMenu.KS.useSmartKS then smartKS() end
end
---------------------------------------------------------------------
--- Function KeyBindings for easier KeyManagement -------------------
---------------------------------------------------------------------
function KeyBindings()
	AimEKey = RengarMenu.KeyBind.aimEkey
	SBTWKey = RengarMenu.KeyBind.SBTWKey
	HarassKey = RengarMenu.KeyBind.HarassKey
	ClearKey = RengarMenu.KeyBind.ClearKey
end
---------------------------------------------------------------------
--- Draw Function --- 
---------------------------------------------------------------------	
function OnDraw()
	if myHero.dead then return end
-- Draw SpellRanges --
	-- Draw W + E --
	if RengarMenu.Draw.drawW and not myHero.dead then
		if WREADY and RengarMenu.Draw.drawW then DrawCircle(myHero.x, myHero.y, myHero.z, wRange, wColor) end
	end
	if RengarMenu.Draw.drawE and not myHero.dead then
		if EREADY and RengarMenu.Draw.drawE then DrawCircle(myHero.x, myHero.y, myHero.z, eRange, eColor) end
	end
-- Draw Target --
	if Target ~= nil and RengarMenu.Draw.drawTarget
		then DrawCircle(Target.x, Target.y, Target.z, (GetDistance(Target.minBBox, Target.maxBBox)/2), TargetColor)
	end
-- Draw KillText --
	if RengarMenu.Draw.drawKillText then
			for i = 1, heroManager.iCount do
				local enemy = heroManager:GetHero(i)
				if ValidTarget(enemy) and enemy ~= nil then
					local barPos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
					local PosX = barPos.x - 35
					local PosY = barPos.y - 10
					DrawText(KillTextList[KillText[i]], 14, PosX, PosY, KillTextColor)			
					
				end
			end
	end
end
---------------------------------------------------------------------
--- Function Check --- 
---------------------------------------------------------------------
function Check()
	-- Cooldownchecks for Abilitys -- 
	QREADY = (myHero:CanUseSpell(_Q) == READY)
	WREADY = (myHero:CanUseSpell(_W) == READY)
	EREADY = (myHero:CanUseSpell(_E) == READY)
	RREADY = (myHero:CanUseSpell(_R) == READY)
	IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
	
	-- Check for Ferocity --
	Ferocity = myHero.mana
	
	-- Heal Check for Harass/Combo/Jungle/Farm --
	HealCheck()
	
	-- Check if items are ready -- 
		dfgReady		= (dfgSlot		~= nil and myHero:CanUseSpell(dfgSlot)		== READY) -- Deathfire Grasp
		hxgReady		= (hxgSlot		~= nil and myHero:CanUseSpell(hxgSlot)		== READY) -- Hextech Gunblade
		bwcReady		= (bwcSlot		~= nil and myHero:CanUseSpell(bwcSlot)		== READY) -- Bilgewater Cutlass
		botrkReady		= (botrkSlot	~= nil and myHero:CanUseSpell(botrkSlot)	== READY) -- Blade of the Ruined King
		sheenReady		= (sheenSlot 	~= nil and myHero:CanUseSpell(sheenSlot) 	== READY) -- Sheen
		lichbaneReady	= (lichbaneSlot ~= nil and myHero:CanUseSpell(lichbaneSlot) == READY) -- Lichbane
		trinityReady	= (trinitySlot 	~= nil and myHero:CanUseSpell(trinitySlot) 	== READY) -- Trinity Force
		lyandrisReady	= (liandrysSlot	~= nil and myHero:CanUseSpell(liandrysSlot) == READY) -- Liandrys 
		tmtReady		= (tmtSlot 		~= nil and myHero:CanUseSpell(tmtSlot)		== READY) -- Tiamat
		hdrReady		= (hdrSlot		~= nil and myHero:CanUseSpell(hdrSlot) 		== READY) -- Hydra
		youReady		= (youSlot		~= nil and myHero:CanUseSpell(youSlot)		== READY) -- Youmuus Ghostblade
		
	-- Set the slots for item --
		dfgSlot 		= GetInventorySlotItem(3128)
		hxgSlot 		= GetInventorySlotItem(3146)
		bwcSlot 		= GetInventorySlotItem(3144)
		botrkSlot		= GetInventorySlotItem(3153)							
		sheenSlot		= GetInventorySlotItem(3057)
		lichbaneSlot	= GetInventorySlotItem(3100)
		trinitySlot		= GetInventorySlotItem(3078)
		liandrysSlot	= GetInventorySlotItem(3151)
		tmtSlot			= GetInventorySlotItem(3077)
		hdrSlot			= GetInventorySlotItem(3074)
		youSlot			= GetInventorySlotItem(3142)		
end
---------------------------------------------------------------------
--- ItemUsage -------------------------------------------------------
---------------------------------------------------------------------
function UseItems()
	if not enemy then enemy = Target end
	if ValidTarget(enemy) then
		if dfgReady		and GetDistance(enemy) <= 750 then CastSpell(dfgSlot, enemy) end
		if hxgReady		and GetDistance(enemy) <= 700 then CastSpell(hxgSlot, enemy) end
		if bwcReady		and GetDistance(enemy) <= 450 then CastSpell(bwcSlot, enemy) end
		if botrkReady	and GetDistance(enemy) <= 450 then CastSpell(botrkSlot, enemy) end
		if tmtReady		and GetDistance(enemy) <= 185 then CastSpell(tmtSlot) end
		if hdrReady 	and GetDistance(enemy) <= 185 then CastSpell(hdrSlot) end
		if youReady		and GetDistance(enemy) <= 185 then CastSpell(youSlot) end
	end
end
---------------------------------------------------------------------
--- HealCheck -------------------------------------------------------
---------------------------------------------------------------------
function HealCheck()
-- JungleHealthCalculation --
	if Ferocity == 5 and EmpModeJungle == 1
		then
			if myHero.health < (myHero.maxHealth *(RengarMenu.Jungle.jungleHeal/100)) then needHealjungle = true
			else needHealjungle = false
			end
	else needHealjungle = false
	end
-- FarmHealthCalculation -- 
	if Ferocity == 5 and EmpModeFarm == 1
		then
			if myHero.health < (myHero.maxHealth *(RengarMenu.Farm.farmHeal/100)) then needHealfarm = true
			else needHealfarm = false
			end
	else needHealfarm = false
	end
-- HarassHealthCalculation --
if Ferocity == 5 and EmpModeHarass == 2
		then
			if myHero.health < (myHero.maxHealth *(RengarMenu.rHarass.harassHeal/100)) then needHealharass = true
			else needHealharass = false
			end
	else needHealharass = false
	end
-- SBTWHealthCalculation -- 
if Ferocity == 5 and not EmpModeSBTW == 2 
		then
			if myHero.health < (myHero.maxHealth *(RengarMenu.SBTW.sbtwHeal/100)) then needHealharass = true
			else needHealharass = false
			end
	else needHealharass = false
	end
end
---------------------------------------------------------------------
--- Functions for VPredicted Spells and Spells ----------------------
---------------------------------------------------------------------
function CastTheQ(enemy)
		if (not QREADY or (GetDistance(enemy) > qRange))
			then return false
		end
		if ValidTarget(enemy) and not RengarMenu.Extra.packetUsage
			then CastSpell(_Q, enemy)
				 myHero:Attack(enemy)
				 return true
		elseif ValidTarget(enemy) and RengarMenu.Extra.packetUsage
			then Packet("S_CAST", {spellId = _Q}):send()
				 myHero:Attack(enemy)
				 return true
		end
		return false
end
function CastTheW(enemy)
	if (not WREADY or (GetDistance(enemy) > wRange))
			then return false
		end
		if ValidTarget(enemy) and not RengarMenu.Extra.packetUsage
			then CastSpell(_W)
			return true
		elseif ValidTarget(enemy) and RengarMenu.Extra.packetUsage
			then Packet("S_CAST", {spellId = _W}):send()
			return true
		end
		return false
end
function AimTheE(enemy)
	local CastPosition, HitChance, Position = VP:GetLineCastPosition(enemy, eDelay, eWidth, eRange, eSpeed, myHero, true)
	if HitChance >= 2 and GetDistance(enemy) <= 1000 and EREADY
		then CastSpell(_E, CastPosition.x, CastPosition.z)
	end
end
---------------------------------------------------------------------
--- Functions for SBTW ---
---------------------------------------------------------------------
function SBTW()
	setEmpMode()
	if ValidTarget(Target) and allowSpells
	then
		if Ferocity <= 4 and not rSOW:CanAttack()
			then
				if RengarMenu.SBTW.sbtwQ and QREADY and GetDistance(Target) < qRange
					then CastTheQ(Target)
				end
				if RengarMenu.SBTW.sbtwW and WREADY and GetDistance(Target) < wRange 
					then CastTheW(Target)
				end
				if RengarMenu.SBTW.sbtwE and EREADY and GetDistance(Target) < eRange
					then AimTheE(Target)
				end
		end
		if Ferocity == 5
			then
				if needHealharass == false
					then
					if EmpModeSBTW == 1
						then	
							if GetDistance(Target) < qRange
								then CastTheQ(Target)
							end
					elseif EmpModeSBTW == 2
						then
							if GetDistance(Target) < wRange
								then CastTheW(Target)
							end
					elseif EmpModeSBTW == 3
						then
							if GetDistance(Target) < eRange
								then AimTheE(Target)
							end
					end
				else CastTheW(Target)
				end 
		end
		if RengarMenu.SBTW.sbtwItems then UseItems() end
 	end
end
---------------------------------------------------------------------
--- Functions for KS ---
---------------------------------------------------------------------
function smartKS()
	for _, enemy in pairs(enemyHeroes) do
		if enemy ~= nil and ValidTarget(enemy) then
		local distance = GetDistance(enemy)
		local hp = enemy.health
			if hp <= qDmg and QREADY and (distance <= qRange)
				then CastTheQ(enemy)
			elseif hp <= wDmg and WREADY and (distance <= wRange) 
				then CastTheW(enemy)
			elseif hp <= eDmg and EREADY and (distance <= eRange) 
				then AimTheE(Target)
			elseif hp <= (qDmg + wDmg) and QREADY and WREADY and (distance <= qRange)
				then CastTheW(enemy)
			elseif hp <= (qDmg + eDmg) and QREADY and EREADY and (distance <= qRange)
				then AimTheE(Target)
			elseif hp <= (wDmg + eDmg) and WREADY and EREADY and (distance <= wRange)
				then AimTheE(Target)
			elseif hp <= (qDmg + wDmg + eDmg) and QREADY and WREADY and EREADY and (distance <= qRange)
				then AimTheE(Target)
			end
		end
	end
end
-- AutoIgnite --
function AutoIgnite(enemy)
		if enemy.health <= iDmg and GetDistance(enemy) <= 600 and ignite ~= nil
			then
				if IREADY then CastSpell(ignite, enemy) end
		end
end
---------------------------------------------------------------------
--- Functions for Harass ---
---------------------------------------------------------------------
function Harass()
	setEmpMode()
	if Target ~= nil then
		if Ferocity <= 4 and not rSOW:CanAttack()
			then
				if RengarMenu.rHarass.harassW then CastTheW(Target) end
				if RengarMenu.rHarass.harassE then AimTheE(Target) end 
		end
		if Ferocity == 5 then
					if needHealharass == false
					then
						if not rSOW:CanAttack() then
							if EmpModeHarass == 1 then CastTheW(Target) end
							if EmpModeHarass == 2 then AimTheE(Target) end
						end
					else CastTheW(Target)
					end
		end
	end	
end
---------------------------------------------------------------------
--- Function for EmpMode --------------------------------------------
---------------------------------------------------------------------
function setEmpMode()
	EmpModeSBTW = RengarMenu.SBTW.empPrioritySBTW
	EmpModeHarass = RengarMenu.rHarass.empPriorityHarass
	EmpModeJungle = RengarMenu.Jungle.empPriorityJungle
	EmpModeFarm = RengarMenu.Farm.empPriorityFarm
end
---------------------------------------------------------------------
--- Jungle Mob Names ---
---------------------------------------------------------------------
function JungleNames()
-- JungleMobNames are the names of the smaller Junglemobs --
	JungleMobNames =
{
	-- Blue Side --
		-- Blue Buff --
		["YoungLizard1.1.2"] = true, ["YoungLizard1.1.3"] = true,
		-- Red Buff --
		["YoungLizard4.1.2"] = true, ["YoungLizard4.1.3"] = true,
		-- Wolf Camp --
		["wolf2.1.2"] = true, ["wolf2.1.3"] = true,
		-- Wraith Camp --
		["LesserWraith3.1.2"] = true, ["LesserWraith3.1.3"] = true, ["LesserWraith3.1.4"] = true,
		-- Golem Camp --
		["SmallGolem5.1.1"] = true,
	-- Purple Side --
		-- Blue Buff --
		["YoungLizard7.1.2"] = true, ["YoungLizard7.1.3"] = true,
		-- Red Buff --
		["YoungLizard10.1.2"] = true, ["YoungLizard10.1.3"] = true,
		-- Wolf Camp --
		["wolf8.1.2"] = true, ["wolf8.1.3"] = true,
		-- Wraith Camp --
		["LesserWraith9.1.2"] = true, ["LesserWraith9.1.3"] = true, ["LesserWraith9.1.4"] = true,
		-- Golem Camp --
		["SmallGolem11.1.1"] = true,
}
-- FocusJungleNames are the names of the important/big Junglemobs --
	FocusJungleNames =
{
	-- Blue Side --
		-- Blue Buff --
		["AncientGolem1.1.1"] = true,
		-- Red Buff --
		["LizardElder4.1.1"] = true,
		-- Wolf Camp --
		["GiantWolf2.1.1"] = true,
		-- Wraith Camp --
		["Wraith3.1.1"] = true,		
		-- Golem Camp --
		["Golem5.1.2"] = true,		
		-- Big Wraith --
		["GreatWraith13.1.1"] = true, 
	-- Purple Side --
		-- Blue Buff --
		["AncientGolem7.1.1"] = true,
		-- Red Buff --
		["LizardElder10.1.1"] = true,
		-- Wolf Camp --
		["GiantWolf8.1.1"] = true,
		-- Wraith Camp --
		["Wraith9.1.1"] = true,
		-- Golem Camp --
		["Golem11.1.2"] = true,
		-- Big Wraith --
		["GreatWraith14.1.1"] = true,
	-- Dragon --
		["Dragon6.1.1"] = true,
	-- Baron --
		["Worm12.1.1"] = true,
}
	for i = 0, objManager.maxObjects do
		local object = objManager:getObject(i)
		if object ~= nil then
			if FocusJungleNames[object.name] then
				table.insert(JungleFocusMobs, object)
			elseif JungleMobNames[object.name] then
				table.insert(JungleMobs, object)
			end
		end
	end
end
---------------------------------------------------------------------
--- Jungle Clear ---
---------------------------------------------------------------------
function JungleClear()
	setEmpMode()
	local JungleMob = GetJungleMob()
		if JungleMob ~= nil then
			if tmtReady and GetDistance(JungleMob) <= 185 then CastSpell(tmtSlot) end
			if hdrReady and GetDistance(JungleMob) <= 185 then CastSpell(hdrSlot) end
			
			if not rSOW:CanAttack() then
				if Ferocity <= 4 then
					if RengarMenu.Jungle.jungleQ and QREADY and GetDistance(JungleMob) <= qRange then CastTheQ(JungleMob) end
					if RengarMenu.Jungle.jungleW and WREADY and GetDistance(JungleMob) <= wRange then CastTheW(JungleMob) end
					if RengarMenu.Jungle.jungleE and EREADY and GetDistance(JungleMob) <= eRange then CastSpell(_E, JungleMob.x, JungleMob.z) end
				end
				if Ferocity == 5 then
					if needHealjungle == false then
						if not rSOW:CanAttack() then
							if EmpModeJungle == 1 then CastTheQ(JungleMob) end
							if EmpModeJungle == 2 then CastTheW(JungleMob) end
						end
					else CastTheW(JungleMob)
					end
				end
			end
		end
end
-- Get Jungle Mob --
function GetJungleMob()
        for _, Mob in pairs(JungleFocusMobs) do
                if ValidTarget(Mob, wRange) then return Mob end
        end
        for _, Mob in pairs(JungleMobs) do
                if ValidTarget(Mob, wRange) then return Mob end
        end
end
---------------------------------------------------------------------
--- Object Handling Functions ---
---------------------------------------------------------------------
function OnCreateObj(obj)
	if obj ~= nil then
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = true
			end
		end 
		if FocusJungleNames[obj.name] then
			table.insert(JungleFocusMobs, obj)
		elseif JungleMobNames[obj.name] then
            table.insert(JungleMobs, obj)
		end
	end
end
function OnDeleteObj(obj)
	if obj ~= nil then
		if obj.name:find("TeleportHome.troy") then
			if GetDistance(obj) <= 70 then
				Recalling = false
			end
		end 
		for i, Mob in pairs(JungleMobs) do
			if obj.name == Mob.name then
				table.remove(JungleMobs, i)
			end
		end
		for i, Mob in pairs(JungleFocusMobs) do
			if obj.name == Mob.name then
				table.remove(JungleFocusMobs, i)
			end
		end
	end
end
---------------------------------------------------------------------
-- Buff Functions ---
---------------------------------------------------------------------
function OnGainBuff(unit, buff)
	if unit.isMe and buff.name == "RengarR" then
		 allowSpells = false
	end
end
function OnLoseBuff(unit, buff)
	if unit.isMe and buff.name == "RengarR" then
		allowSpells = true
	end
end
---------------------------------------------------------------------
-- Recalling Functions ---
---------------------------------------------------------------------
function OnRecall(hero, channelTimeInMs)
	if hero.networkID == player.networkID then
		Recalling = true
	end
end
function OnAbortRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end
function OnFinishRecall(hero)
	if hero.networkID == player.networkID then
		Recalling = false
	end
end
---------------------------------------------------------------------
--- Lane Clear ---
---------------------------------------------------------------------
function LaneClear()
enemyMinions:update()
setEmpMode()
		for _, minion in pairs(enemyMinions.objects) do
				if ValidTarget(minion) and not rSOW:CanAttack()
				then
					if tmtReady and GetDistance(minion) <= 185 then CastSpell(tmtSlot) end
					if hdrReady and GetDistance(minion) <= 185 then CastSpell(hdrSlot) end
					if Ferocity <= 4 
						then
							if RengarMenu.Farm.farmQ and GetDistance(minion) <= qRange then CastTheQ(minion) end
							if RengarMenu.Farm.farmW and GetDistance(minion) <= wRange then CastTheW(minion) end
							if RengarMenu.Farm.farmE and GetDistance(minion) <= eRange then CastSpell(_E, minion.x, minion.z) end
					end
					if Ferocity == 5 then
							if needHealfarm == false
								then 
									if EmpModeFarm == 1 then CastTheQ(minion) end
									if EmpModeFarm == 2 then CastTheW(minion) end
							else CastTheW(minion)
							end
					end
				end
			end	
end 
---------------------------------------------------------------------
--- Lag Free Circles ---
---------------------------------------------------------------------
function LFCfunc()
	if not RengarMenu.Draw.LFC.LagFree then _G.DrawCircle = _G.oldDrawCircle end
	if RengarMenu.Draw.LFC.LagFree then _G.DrawCircle = DrawCircle2 end
end
function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
    radius = radius or 300
  quality = math.max(8,round(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
    local points = {}
    for theta = 0, 2 * math.pi + quality, quality do
        local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
        points[#points + 1] = D3DXVECTOR2(c.x, c.y)
    end
    DrawLines2(points, width or 1, color or 4294967295)
end
function round(num) 
 if num >= 0 then return math.floor(num+.5) else return math.ceil(num-.5) end
end
function DrawCircle2(x, y, z, radius, color)
    local vPos1 = Vector(x, y, z)
    local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
    local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
    local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))
    if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y }) then
        DrawCircleNextLvl(x, y, z, radius, 1, color, RengarMenu.Draw.LFC.CL) 
    end
end
---------------------------------------------------------------------
--- Function Damage Calculations for Skills/Items/Enemys --- 
---------------------------------------------------------------------
function DamageCalculation()
	for i=1, heroManager.iCount do
		local enemy = heroManager:GetHero(i)
			if ValidTarget(enemy) and enemy ~= nil
				then
				aaDmg 		= ((getDmg("AD", enemy, myHero)))
				qDmg 		= ((getDmg("Q", enemy, myHero)) or 0)
				qDmgE 		= ((getDmg("Q", enemy, myHero, 2)) or 0) -- qEmp
				wDmg 		= ((getDmg("W", enemy, myHero)) or 0)
				eDmg 		= ((getDmg("E", enemy, myHero)) or 0)
				iDmg 		= ((IREADY and getDmg("IGNITE", enemy, myHero)) or 0) -- Ignite
				dfgDmg 		= ((dfgReady and getDmg("DFG", enemy, myHero)) or 0) -- Deathfire Grasp
				hxgDmg 		= ((hxgReady and getDmg("HXG", enemy, myHero)) or 0) -- Hextech Gunblade
				bwcDmg 		= ((bwcReady and getDmg("BWC", enemy, myHero)) or 0) -- Bilgewater Cutlass
				botrkDmg 	= ((botrkReady and getDmg("RUINEDKING", enemy, myHero)) or 0) -- Blade of the Ruined King
				sheenDmg	= ((sheenReady and getDmg("SHEEN", enemy, myHero)) or 0) -- Sheen
				lichbaneDmg = ((lichbaneReady and getDmg("LICHBANE", enemy, myHero)) or 0) -- Lichbane
				trinityDmg 	= ((trinityReady and getDmg("TRINITY", enemy, myHero)) or 0) -- Trinity Force
				liandrysDmg = ((liandrysReady and getDmg("LIANDRYS", enemy, myHero)) or 0) -- Liandrys 
				local extraDmg 	= iDmg + dfgDmg + hxgDmg + bwcDmg + botrkDmg + sheenDmg + lichbaneDmg + trinityDmg + liandrysDmg
				local abilityDmg = qDmg + qDmgE + wDmg + eDmg
				local totalDmg = abilityDmg + extraDmg
			-- Set Kill Text --	
				-- Harass your enemy! -- 
				if enemy.health > totalDmg then KillText[i] = 2
					-- "Kill! - Ignite" --
					elseif enemy.health <= iDmg and IREADY then KillText[i] = 3
					-- "Kill! - (Q)" --
					elseif enemy.health <= qDmg and QREADY then KillText[i] = 4
					-- "Kill! - (W)" -- 		
					elseif enemy.health <= wDmg and WREADY then KillText[i] = 5
					-- "Kill! - (E)" --
					elseif enemy.health <= eDmg and EREADY then KillText[i] = 6
					-- "Kill! - (Q)+(Q2)" --
					elseif enemy.health <= (qDmg + qDmgE) and QREADY and Ferocity == 4 then KillText[i] = 7
					-- "Kill! - (Q)+(W)" --
					elseif enemy.health <= (qDmg + wDmg) and QREADY and WREADY then KillText[i] = 8
					-- "Kill! - (Q)+(E)" --
					elseif enemy.health <= (qDmg + eDmg) and QREADY and EREADY then KillText[i] = 9
					-- "Kill! - (W)+(E)" --
					elseif enemy.health <= (wDmg + eDmg) and WREADY and EREADY then KillText[i] = 10
					-- "Kill! - (Q)+(W)+(E)" --
					elseif enemy.health <= (qDmg + wDmg + eDmg) and QREADY and WREADY and EREADY then KillText[i] = 11
					-- "Kill! - (Q)+(Q2)+(W)" --
					elseif enemy.health <= (qDmg + qDmgE + wDmg) and QREADY and WREADY and Ferocity == 4 then KillText[i] = 12
					-- "Kill! - (Q)+(Q2)+(E)" --
					elseif enemy.health <= (qDmg + qDmgE + eDmg) and QREADY and EREADY and Ferocity == 4 then KillText[i] = 13
					-- "Kill! - (Q)+(Q2)+(W)+(E)" --
					elseif enemy.health <= (qDmg + qDmgE + wDmg + eDmg) and QREADY and WREADY and EREADY and Ferocity == 4 then KillText[i] = 14
				else KillText[i] = 1
				end	
		end
	end
end
-- Checks which SummonerSpell is ignite (implemented to OnLoad) -- 
function IgniteCheck()
	if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
			ignite = SUMMONER_1
	elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
			ignite = SUMMONER_2
	end
end
---------------------------------------------------------------------
--- Autolevel Skills ------------------------------------------------
---------------------------------------------------------------------
function AutoLevelMySkills()
		if RengarMenu.Extra.AutoLevelSkills == 2 then
			autoLevelSetSequence(levelSequence.startQ)
		elseif RengarMenu.Extra.AutoLevelSkills == 3 then
			autoLevelSetSequence(levelSequence.startW)
		elseif RengarMenu.Extra.AutoLevelSkills == 4 then
			autoLevelSetSequence(levelSequence.startE)
		end
end