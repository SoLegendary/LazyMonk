
--[[

LazyMonk Addon

This addon is designed to help windwalker monks with their rotation by suggesting the
next best spell to cast every time a spell is cast in combat and periodically thereafter.

Just press the hotkey for th next ability shown!

]]

-- allow UI reloads with just /rl and frame stack with /fs
SLASH_RELOADUI1 = "/rl";
SlashCmdList.RELOADUI = ReloadUI;




local version = "0.1";

-- last spell casted so we don't repeat anything and lose combo strikes
local lastSpell = "";

-- last spell displayed so we don't spend resources redisplaying the same ability
local lastDisplayedSpell = "";

-- how often (in seconds) to check for the next spell
local updatePeriod = 0.25;


-- TODO:
-- frame appears late when entering combat (maybe force update with enter combat event)


-- IconFrame class - create empty object as parent 
-- and define constructor as a method called 'new'
IconFrame = {}

function IconFrame:new(name, iconPath)

	local obj = {}; -- create new object
	
	-- allow obj to inherit methods from parent
	setmetatable(obj,self);
	self.__index = self
	
	-- initialise obj members
	-- create frames using CreateFrame() with params:
	-- 1. type "FRAME"
	-- 2. name of frame
	-- 3. child of UIParent - the parent frame of all UI elements
	-- 4. XML template to inherit from (from BlizzardInterfaceCode\Interface\FrameXML)
	obj.frame    = CreateFrame("FRAME", "LazyMonkIconFrame", UIParent);
	obj.name     = name;
	obj.iconPath = iconPath;

	-- also add texture to frame automatically but don't show yet
   	local iconTexture = obj.frame:CreateTexture(nil,"BACKGROUND")
	iconTexture:SetTexture(obj.iconPath)
	
	iconTexture:SetAllPoints(obj.frame)
	obj.frame.texture = iconTexture
	
	-- set frame to a specific point:
	-- 1. point
	-- 2. relativeFrame
	-- 3. relativePoint
	-- 4. x offset
	-- 5. y offset
	obj.frame:SetPoint("CENTER", NamePlatePlayerResourceFrame, "CENTER", 0, -50)
	obj.frame:SetFrameStrata("BACKGROUND")
	obj.frame:SetWidth(54) -- Set these to whatever height/width is needed 
	obj.frame:SetHeight(54) -- for your Texture
	obj.frame:Hide()
   
	return obj;
end






-- creating table of frames to display icons
local iconFrames = {

	["No Spell Available"] = IconFrame:new("No Spell Available",
		"Interface\\ICONS\\spell_holy_borrowedtime.blp"),

	["Tiger Palm"] = IconFrame:new("Tiger Palm",
		"Interface\\ICONS\\Ability_Monk_TigerPalm.blp"),
		
	["Blackout Kick"] = IconFrame:new("Blackout Kick",
		"Interface\\ICONS\\ability_monk_roundhousekick.blp"),
		
	["Chi Wave"] = IconFrame:new("Chi Wave",
		"Interface\\ICONS\\Ability_Monk_ChiWave.blp"),
		
	["Fists of Fury"] = IconFrame:new("Fists of Fury",
		"Interface\\ICONS\\monk_ability_fistoffury.blp"),
		
	["Whirling Dragon Punch"] = IconFrame:new("Whirling Dragon Punch",
		"Interface\\ICONS\\ABILITY_MONK_HURRICANESTRIKE.blp"),
		
	["Strike of the Windlord"] = IconFrame:new("Strike of the Windlord",
		"Interface\\ICONS\\INV_Hand_1H_ArtifactSkywall_D_01.blp"),
	
	["Rising Sun Kick"] = IconFrame:new("Rising Sun Kick",
		"Interface\\ICONS\\Ability_Monk_RisingSunKick.blp"),
		
	["Touch of Karma"] = IconFrame:new("Touch of Karma",
		"Interface\\ICONS\\Ability_Monk_TouchofKarma.blp"),
		
	["Healing Elixir"] = IconFrame:new("Healing Elixir",
		"Interface\\ICONS\\Ability_Monk_JasmineForceTea.blp"),
		
	["Dampen Harm"] = IconFrame:new("Dampen Harm",
		"Interface\\ICONS\\Ability_Monk_DampenHarm.blp"),
		
	["Diffuse Magic"] = IconFrame:new("Diffuse Magic",
		"Interface\\ICONS\\spell_monk_diffusemagic.blp"),
		
	["Spear Hand Strike"] = IconFrame:new("Spear Hand Strike",
		"Interface\\ICONS\\Ability_Monk_SpearHand.blp"),
		
	["Energizing Elixir"] = IconFrame:new("Energizing Elixir",
		"Interface\\ICONS\\Ability_Monk_EnergizingWine.blp"),
		
	["Touch of Death"] = IconFrame:new("Touch of Death",
		"Interface\\ICONS\\Ability_Monk_TouchOfDeath.blp")
}



-- returns the remaining cooldown for a given spell including global CDs
local function getCDLeft(spellName)

	local start, duration, enabled = GetSpellCooldown(spellName, "BOOKTYPE_SPELL");
	if duration == 1 then
		return 0;
	else
		return (start + duration - GetTime());
	end
end





-- returns the name of the next best spell to cast excluding repeats
local function getNextBestSpell()

	-- update player stats
	local health = (UnitHealth("player") / UnitHealthMax("player")) * 100;
	local energy = UnitPower("player", SPELL_POWER_ENERGY);
	local chi    = UnitPower("player", SPELL_POWER_CHI);
	local maxchi = UnitPowerMax("player", SPELL_POWER_CHI);
	local freeBlackoutKick = UnitBuff("player", "Blackout Kick!");
	
	local _, _, _, _, _, _, _, _, interrupt = UnitCastingInfo("target");
	
	-- TODO: 
	-- limit icon frame update speed to avoid confusion (maybe make an animated queue?)
	-- AOE using spinning crane kick and rushing jade wind
	-- stop updating while spells are all disabled (esp. when rolling)
	
	-- checkbox options for:
		-- interrupts for bosses (on by default)
		-- interrupts for regular mobs (off by default)
		-- long cooldowns (off by default)
		-- healing and defensive spells (off by default)
		-- AOE (on by default)
	
	if IsUsableSpell("Spear Hand Strike") and getCDLeft("Spear Hand Strike") < 1 and interrupt == false then
		return "Spear Hand Strike";
	
	-- elseif IsUsableSpell("Touch of Karma") and getCDLeft("Touch of Karma") < 1 and health < 35 then
	-- 	return "Touch of Karma";
		
	-- elseif IsUsableSpell("Healing Elixir") and getCDLeft("Healing Elixir") < 1 and health <= 50 then
	-- 	return "Healing Elixir";
		
	elseif IsUsableSpell("Diffuse Magic") and getCDLeft("Diffuse Magic") < 1 and health <= 50 then
		return "Diffuse Magic";
		
	elseif IsUsableSpell("Dampen Harm") and getCDLeft("Dampen Harm") < 1 and health <= 50 then
		return "Dampen Harm";
	
	elseif IsUsableSpell("Strike of the Windlord") and lastSpell ~= "Strike of the Windlord" and chi >= 2 and getCDLeft("Strike of the Windlord") < 1 then
		return "Strike of the Windlord";
		
	elseif IsUsableSpell("Whirling Dragon Punch") and lastSpell ~= "Whirling Dragon Punch" and getCDLeft("Whirling Dragon Punch") < 1 then
		return "Whirling Dragon Punch";
	
	elseif IsUsableSpell("Blackout Kick") and lastSpell ~= "Blackout Kick" and freeBlackoutKick then
		return "Blackout Kick";
	
	elseif (IsUsableSpell("Tiger Palm") or energy >= 45) and lastSpell ~= "Tiger Palm" and (maxchi - chi) >= 2  then
		return "Tiger Palm";
	
	elseif IsUsableSpell("Fists of Fury") and lastSpell ~= "Fists of Fury" and chi >= 3 and energy <= 60 and getCDLeft("Fists of Fury") < 1 then
		return "Fists of Fury";
	
	elseif IsUsableSpell("Rising Sun Kick") and lastSpell ~= "Rising Sun Kick" and chi >= 2 and getCDLeft("Rising Sun Kick") < 1 then
		return "Rising Sun Kick";
		
	elseif IsUsableSpell("Fists of Fury") and lastSpell ~= "Fists of Fury" and chi >= 3 and getCDLeft("Fists of Fury") < 1 then
		return "Fists of Fury";
		
	elseif IsUsableSpell("Blackout Kick") and lastSpell ~= "Blackout Kick" and (chi >= 4 or (chi >= 3 and getCDLeft("Fists of Fury") > 1)) then
		return "Blackout Kick";
	
	elseif IsUsableSpell("Chi Wave") and lastSpell ~= "Chi Wave" and getCDLeft("Chi Wave") < 1 then
		return "Chi Wave"
		
	elseif IsUsableSpell("Blackout Kick") and lastSpell ~= "Blackout Kick" and chi >= 1 and getCDLeft("Fists of Fury") > 1 then
		return "Blackout Kick";
		
	elseif IsUsableSpell("Tiger Palm") and lastSpell ~= "Tiger Palm" and (maxchi - chi) <= 1 and energy >= 50 then
		return "Tiger Palm";
		
	elseif IsUsableSpell("Energizing Elixir") and getCDLeft("Energizing Elixir") < 1 and chi <= 2 and energy <= 35 then
		return "Energizing Elixir";
	
	else
		return "No Spell Available"
	end
end





-- displays the next best spell to cast and hides the last one displayed
local function showNextBestSpell(spellName)

	if spellName ~= lastDisplayedSpell then
		
		if lastDisplayedSpell ~= "" then
			iconFrames[lastDisplayedSpell].frame:Hide();
		end
			
		lastDisplayedSpell = spellName;
		iconFrames[spellName].frame:Show();
	end
end

-- hides all spell icon frames
local function hideAllSpells()
		
	for index, value in pairs(iconFrames) do
		value.frame:Hide()
	end
end




local localizedClass, englishClass, classIndex = UnitClass("player");

if englishClass == "MONK" then

	print("Loaded LazyMonk v" .. version);

	-- update next best spell periodically and whenever a spell is cast
	C_Timer.NewTicker(updatePeriod, function()
		if UnitAffectingCombat("player") then
			showNextBestSpell(getNextBestSpell());
		else
			hideAllSpells();
		end
		
	end)
	
	-- create a frame to handle events
	local eventFrame = CreateFrame("FRAME", "LazyMonkEventFrame", UIParent);

	-- tie that frame to a specific event (eg. player entering world)
	-- note that for the event UNIT_SPELLCAST_SENT, the event handler code runs before spell 
	-- effects such as chi generation and energy usage take place, even for instant spells
	-- this can be solved by wrapping the handler inside a C_Timer.After() function call
	eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT");

	-- create function that runs whenever that event occurs
	local function eventHandler(self, event, ...)
		
		local casterName, spellName, spellRank, spellTarget = ...;
		
		-- get and display the next best spell unless you only rolled
		if spellName ~= "Roll" and UnitAffectingCombat("player") then
			lastSpell = spellName;
			C_Timer.After(0.01, function()
				showNextBestSpell(getNextBestSpell());
			end)
		end
	end

	-- tie event handler to the frame
	eventFrame:SetScript("OnEvent", eventHandler);
	
else
	print("Failed to load LazyMonk, this character isn't a monk!");
end



























