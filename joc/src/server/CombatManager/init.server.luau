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

local ROOMS = {
	{ name = "Goblin Scout",   maxHp = 30,  atk = 8,  def = 2, modelName = "GoblinModel" },
	{ name = "Orc Warrior",    maxHp = 45,  atk = 12, def = 3, modelName = "OrcModel" },
	{ name = "Stone Troll",    maxHp = 60,  atk = 15, def = 4, modelName = "TrollModel" },
}
local BOSS = { name = "Kobold King", maxHp = 120, atk = 18, def = 6, modelName = "BossModel" }

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
	})
end

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

	playerObj.isDefending = false
	pushStats()

	if playerObj:isDead() then
		combatState = "GAME_OVER"
		sendUI("gameOver", {})
		return
	end

	combatState = "PLAYER_TURN"
	log("El teu torn.", "info")
end

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

	-- Posicionament segur
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
		currentEnemyData = Enemy.new(data.name, data.maxHp, data.atk, data.def, currentRoom)
	end

	-- Notifica al client perquè creï la billboard
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
		message = "Ataces " .. currentEnemyData.name .. " per " .. dealt .. " de dany!"
		if isCrit then message = "⚡ CRÍTIC! " .. message end
		msgType = isCrit and "crit" or "normal"

	elseif action == "skill" then
		local dealt, isCrit = playerObj:useSkill(currentEnemyData)
		if dealt == 0 then
			log("Mana insuficient! (necessites 10)", "danger")
			return
		end
		message = "HABILITAT ESPECIAL! Fas " .. dealt .. " de dany!"
		if isCrit then message = "⚡ CRÍTIC! " .. message end
		msgType = "skill"

	elseif action == "potion" then
		if not playerObj:usePotion() then
			log("No tens pocions!", "danger")
			return
		end
		message = "Utilitzes una poció! Recuperes 30 HP. Restants: " .. playerObj.potions
		msgType = "heal"

	elseif action == "defend" then
		playerObj.isDefending = true
		message = "Et defenses! El proper atac farà la meitat de dany."
		msgType = "defend"
	end

	log(message, msgType)
	pushStats()

	-- Comprovar fase 2 del boss
	if currentEnemyData.checkPhase and currentEnemyData:checkPhase() then
		log("⚠️ " .. currentEnemyData.name .. " entra en FASE 2! ATK augmentat!", "boss")
		sendUI("bossPhase2", {})
		pushStats()
	end

	if currentEnemyData:isDead() then
		combatState = "ROOM_CLEAR"
		log("Has derrotat " .. currentEnemyData.name .. "!", "victory")
		playerObj:heal(20)
		playerObj:regenerateMana(10)
		pushStats()
		clearEnemy()

		if currentRoom >= 4 then
			combatState = "VICTORY"
			sendUI("victory", {})
		else
			sendUI("roomClear", {})
		end
		return
	end

	combatState = "ENEMY_TURN"
	enemyTurn()
end

combatRemote.OnServerEvent:Connect(function(player, action)
	if action == "startGame" then
		currentRoom = 1
		currentPlayer = player
		playerObj = PlayerStats.new(player.Name)
		startRoom()

	elseif action == "nextRoom" then
		currentRoom = currentRoom + 1
		startRoom()

	elseif action == "attack" or action == "skill" or action == "potion" or action == "defend" then
		processAction(player, action)
	end
end)

print("CombatManager carregat")
