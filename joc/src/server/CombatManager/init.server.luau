-- CombatManager (Script al servidor)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local combatRemote = ReplicatedStorage:WaitForChild("CombatAction")
local uiRemote = ReplicatedStorage:WaitForChild("UIUpdate")

local CharacterStats = require(script.CharacterStats)
local PlayerStats = require(script.PlayerStats)
local Enemy = require(script.Enemy)
local Boss = require(script.Boss)

local currentPlayer = nil
local currentEnemyData = nil
local currentEnemyModel = nil
local combatState = "IDLE"
local currentRoom = 1
local playerObj = nil

-- Estadístiques de partida (s'acumulen tota la run)
local combatStats = { damageDealt = 0, critsLanded = 0, turnsUsed = 0, potionsUsed = 0 }

-- Noms dels efectes d'estat per als missatges de log
local STATUS_NAMES = { poison = "Verí ☠", burn = "Cremada 🔥" }

local ROOMS = {
	{ name = "Goblin Scout", maxHp = 30,  atk = 8,  def = 2, modelName = "GoblinModel" },
	{ name = "Orc Warrior",  maxHp = 45,  atk = 12, def = 3, modelName = "OrcModel" },
	-- Stone Troll: l'atac especial aplica verí (4 dany/torn durant 3 torns)
	{ name = "Stone Troll",  maxHp = 60,  atk = 15, def = 4, modelName = "TrollModel",
	  specialEffect = { type = "poison", damage = 4, turns = 3 } },
}
local BOSS = { name = "Kobold King", maxHp = 120, atk = 18, def = 6, modelName = "BossModel" }

-- ============================================================
-- Utilitats
-- ============================================================

local function sendUI(action, data)
	if currentPlayer then
		uiRemote:FireClient(currentPlayer, action, data or {})
	end
end

local function log(msg, msgType)
	sendUI("log", { message = msg, msgType = msgType or "normal" })
end

local function pushStats()
	if not playerObj or not currentEnemyData then return end
	sendUI("stats", {
		hp = playerObj.hp, maxHp = playerObj.maxHp,
		mana = playerObj.mana, maxMana = playerObj.maxMana,
		potions = playerObj.potions,
		enemyHp = currentEnemyData.hp, enemyMaxHp = currentEnemyData.maxHp,
		enemyName = currentEnemyData.name,
		enemyPhase = currentEnemyData.phase,
		room = currentRoom,
		statusEffect = playerObj.statusEffect,  -- nil o { type, damage, turnsLeft }
	})
end

-- ============================================================
-- Torn de l'enemic
-- ============================================================

local function enemyTurn()
	if combatState ~= "ENEMY_TURN" then return end
	task.wait(1.2)

	local action = currentEnemyData:chooseAction()
	local damage, isSpecial

	if action == "special" then
		damage = currentEnemyData:specialAttack(playerObj)
		isSpecial = true
	else
		damage = currentEnemyData:attack(playerObj)
		isSpecial = false
	end

	local attackDesc = isSpecial and "usa una habilitat especial" or "t'ataca"
	log(currentEnemyData.name .. " " .. attackDesc .. "! Et fa " .. damage .. " de dany!", "damage")

	-- Notificar si l'atac especial ha aplicat un efecte d'estat
	if isSpecial and playerObj.statusEffect then
		local se = playerObj.statusEffect
		log("Has quedat afectat per " .. (STATUS_NAMES[se.type] or se.type) ..
			"! (" .. se.damage .. " dany/torn, " .. se.turnsLeft .. " torns)", "danger")
	end

	playerObj.isDefending = false

	-- Comprovar mort per atac directe
	if playerObj:isDead() then
		combatState = "GAME_OVER"
		pushStats()
		sendUI("gameOver", {})
		return
	end

	-- Tick d'efecte d'estat (verí/cremada)
	local statusDmg, statusType = playerObj:tickStatusEffect()
	if statusDmg > 0 then
		log((STATUS_NAMES[statusType] or "Efecte d'estat") ..
			" et fa " .. statusDmg .. " de dany!", "damage")
		-- Notificar si l'efecte ha desaparegut
		if not playerObj.statusEffect then
			log("L'efecte d'estat ha desaparegut.", "info")
		end
		-- Comprovar mort per efecte d'estat
		if playerObj:isDead() then
			combatState = "GAME_OVER"
			pushStats()
			sendUI("gameOver", {})
			return
		end
	end

	-- Regeneració passiva de mana (5 per torn)
	if playerObj.mana < playerObj.maxMana then
		playerObj:regenerateMana(5)
		log("+5 Mana regenerat.", "heal")
	end

	pushStats()
	combatState = "PLAYER_TURN"
	log("El teu torn.", "info")
end

-- ============================================================
-- Gestió d'enemics i sales
-- ============================================================

local function clearEnemy()
	if currentEnemyModel then
		currentEnemyModel:Destroy()
		currentEnemyModel = nil
	end
end

local function spawnEnemy(data, isBoss)
	clearEnemy()
	local templates = ServerStorage:FindFirstChild("EnemyTemplates")
	if not templates then warn("No EnemyTemplates folder!") return false end

	local template = templates:FindFirstChild(data.modelName)
	if not template then warn("Model no trobat: " .. data.modelName) return false end

	local model = template:Clone()
	model.Name = "CurrentEnemy"
	model.Parent = workspace

	-- Posicionament segur (fallback si no hi ha BasePart)
	local part = model:FindFirstChildWhichIsA("BasePart")
	if not part then
		local dummy = Instance.new("Part")
		dummy.Size = Vector3.new(2, 2, 2)
		dummy.Transparency = 1
		dummy.Anchored = true
		dummy.CanCollide = false
		dummy.Parent = model
		model.PrimaryPart = dummy
	else
		model.PrimaryPart = part
	end
	model:SetPrimaryPartCFrame(CFrame.new(10, 2, 0))
	currentEnemyModel = model

	if isBoss then
		currentEnemyData = Boss.new(data.name, data.maxHp, data.atk, data.def)
	else
		-- Passa specialEffect a Enemy.new per habilitar efectes d'estat
		currentEnemyData = Enemy.new(data.name, data.maxHp, data.atk, data.def,
			currentRoom, data.specialEffect)
	end

	sendUI("spawnEnemy", {
		enemyName = currentEnemyData.name,
		maxHp = currentEnemyData.maxHp,
		isBoss = isBoss,
	})
	return true
end

local function startRoom()
	local isBoss = currentRoom == 4
	local data = isBoss and BOSS or ROOMS[currentRoom]
	if not data then return end

	local ok = spawnEnemy(data, isBoss)
	if not ok then log("Error carregant l'enemic!", "danger") return end

	combatState = "PLAYER_TURN"
	pushStats()
	log("Apareix " .. currentEnemyData.name .. "!", isBoss and "boss" or "info")
	log("El teu torn. Tria una acció.", "info")
end

-- ============================================================
-- Processament d'accions del jugador
-- ============================================================

local function processAction(player, action)
	if player ~= currentPlayer then return end
	if combatState ~= "PLAYER_TURN" then
		log("No és el teu torn!", "danger")
		return
	end

	local message, msgType = "", "normal"

	if action == "attack" then
		local isCrit = playerObj:rollCrit()
		local rawDmg = isCrit and math.floor(playerObj.atk * 1.5) or playerObj.atk
		local dealt = currentEnemyData:takeDamage(rawDmg)
		combatStats.turnsUsed += 1
		combatStats.damageDealt += dealt
		if isCrit then combatStats.critsLanded += 1 end
		message = "Ataces " .. currentEnemyData.name .. " per " .. dealt .. " de dany!"
		if isCrit then message = "⚡ CRÍTIC! " .. message end
		msgType = isCrit and "crit" or "normal"

	elseif action == "skill" then
		local dealt, isCrit = playerObj:useSkill(currentEnemyData)
		if dealt == 0 then
			log("Mana insuficient! (necessites 10)", "danger")
			return
		end
		combatStats.turnsUsed += 1
		combatStats.damageDealt += dealt
		if isCrit then combatStats.critsLanded += 1 end
		message = "HABILITAT ESPECIAL! Fas " .. dealt .. " de dany!"
		if isCrit then message = "⚡ CRÍTIC! " .. message end
		msgType = "skill"

	elseif action == "potion" then
		if not playerObj:usePotion() then
			log("No tens pocions!", "danger")
			return
		end
		combatStats.turnsUsed += 1
		combatStats.potionsUsed += 1
		message = "Utilitzes una poció! Recuperes 30 HP. Restants: " .. playerObj.potions
		msgType = "heal"

	elseif action == "defend" then
		combatStats.turnsUsed += 1
		playerObj.isDefending = true
		message = "Et defenses! El proper atac farà la meitat de dany."
		msgType = "defend"
	end

	log(message, msgType)
	pushStats()

	-- Comprovar transició a Fase 2 del boss
	if currentEnemyData.checkPhase and currentEnemyData:checkPhase() then
		log("⚠️ " .. currentEnemyData.name .. " entra en FASE 2! ATK augmentat i cremada activada!", "boss")
		sendUI("bossPhase2", {})
		pushStats()
	end

	-- Comprovar si l'enemic ha mort
	if currentEnemyData:isDead() then
		combatState = "ROOM_CLEAR"
		log("Has derrotat " .. currentEnemyData.name .. "!", "victory")
		playerObj:heal(20)
		playerObj:regenerateMana(10)
		-- Eliminar efecte d'estat en canviar de sala
		playerObj.statusEffect = nil
		pushStats()
		clearEnemy()

		if currentRoom >= 4 then
			combatState = "VICTORY"
			-- Envia estadístiques finals amb la victòria
			sendUI("victory", { score = combatStats })
		else
			sendUI("roomClear", {})
		end
		return
	end

	combatState = "ENEMY_TURN"
	enemyTurn()
end

-- ============================================================
-- Connexió d'events del client
-- ============================================================

combatRemote.OnServerEvent:Connect(function(player, action)
	if action == "startGame" then
		currentRoom = 1
		currentPlayer = player
		playerObj = PlayerStats.new(player.Name)
		-- Reiniciar estadístiques de partida
		combatStats = { damageDealt = 0, critsLanded = 0, turnsUsed = 0, potionsUsed = 0 }
		startRoom()

	elseif action == "nextRoom" then
		currentRoom = currentRoom + 1
		startRoom()

	elseif action == "attack" or action == "skill" or action == "potion" or action == "defend" then
		processAction(player, action)
	end
end)

print("CombatManager carregat ✓")
