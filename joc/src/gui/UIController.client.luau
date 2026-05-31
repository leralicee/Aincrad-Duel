-- UIController (LocalScript dins BattleGUI)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local combatRemote = ReplicatedStorage:WaitForChild("CombatAction")
local uiRemote = ReplicatedStorage:WaitForChild("UIUpdate")
local screen = script.Parent
screen.ResetOnSpawn = false
screen.Enabled = true

-- Netejar elements previs
for _, c in ipairs(screen:GetChildren()) do c:Destroy() end

-- ============================================================
-- CONSTRUCCIÓ DE LA GUI 
-- ============================================================

-- Contenidor principal
local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundTransparency = 1
root.Parent = screen

-- Panel d'estadístiques del jugador (esquerra inferior)
local statsPanel = Instance.new("Frame")
statsPanel.Size = UDim2.new(0, 220, 0, 135)
statsPanel.Position = UDim2.new(0, 16, 1, -155)
statsPanel.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
statsPanel.BackgroundTransparency = 0.25
statsPanel.BorderSizePixel = 0
statsPanel.Parent = root
Instance.new("UICorner", statsPanel).CornerRadius = UDim.new(0, 10)

local playerNameLabel = Instance.new("TextLabel")
playerNameLabel.Text = player.Name
playerNameLabel.Size = UDim2.new(1, -12, 0, 22)
playerNameLabel.Position = UDim2.new(0, 8, 0, 6)
playerNameLabel.BackgroundTransparency = 1
playerNameLabel.TextColor3 = Color3.new(1, 1, 1)
playerNameLabel.Font = Enum.Font.GothamBold
playerNameLabel.TextSize = 14
playerNameLabel.TextXAlignment = Enum.TextXAlignment.Left
playerNameLabel.Parent = statsPanel

-- Barra HP
local function makeBar(parent, yPos, color, label)
	local lbl = Instance.new("TextLabel")
	lbl.Text = label
	lbl.Size = UDim2.new(0, 40, 0, 16)
	lbl.Position = UDim2.new(0, 8, 0, yPos)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, -60, 0, 14)
	bg.Position = UDim2.new(0, 50, 0, yPos + 1)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	bg.BorderSizePixel = 0
	bg.Parent = parent
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local valLabel = Instance.new("TextLabel")
	valLabel.Size = UDim2.new(0, 55, 0, 14)
	valLabel.Position = UDim2.new(1, 2, 0, yPos + 1)
	valLabel.BackgroundTransparency = 1
	valLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	valLabel.Font = Enum.Font.Gotham
	valLabel.TextSize = 11
	valLabel.TextXAlignment = Enum.TextXAlignment.Left
	valLabel.Parent = parent

	return fill, valLabel
end

local hpFill, hpVal = makeBar(statsPanel, 30, Color3.fromRGB(220, 60, 60), "HP")
local manaFill, manaVal = makeBar(statsPanel, 54, Color3.fromRGB(60, 100, 220), "Mana")

local potionLabel = Instance.new("TextLabel")
potionLabel.Text = "🧪 Pocions: 3"
potionLabel.Size = UDim2.new(1, -12, 0, 18)
potionLabel.Position = UDim2.new(0, 8, 0, 82)
potionLabel.BackgroundTransparency = 1
potionLabel.TextColor3 = Color3.fromRGB(180, 230, 180)
potionLabel.Font = Enum.Font.Gotham
potionLabel.TextSize = 12
potionLabel.TextXAlignment = Enum.TextXAlignment.Left
potionLabel.Parent = statsPanel

-- Indicador d'efecte d'estat (verí / cremada)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Text = ""
statusLabel.Size = UDim2.new(1, -12, 0, 18)
statusLabel.Position = UDim2.new(0, 8, 0, 106)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 150, 50)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statsPanel

-- Panel enemic (dreta inferior)
local enemyPanel = Instance.new("Frame")
enemyPanel.Size = UDim2.new(0, 220, 0, 80)
enemyPanel.Position = UDim2.new(1, -236, 1, -100)
enemyPanel.BackgroundColor3 = Color3.fromRGB(20, 8, 8)
enemyPanel.BackgroundTransparency = 0.25
enemyPanel.BorderSizePixel = 0
enemyPanel.Parent = root
Instance.new("UICorner", enemyPanel).CornerRadius = UDim.new(0, 10)

local enemyNameLabel = Instance.new("TextLabel")
enemyNameLabel.Text = "---"
enemyNameLabel.Size = UDim2.new(1, -12, 0, 22)
enemyNameLabel.Position = UDim2.new(0, 8, 0, 6)
enemyNameLabel.BackgroundTransparency = 1
enemyNameLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
enemyNameLabel.Font = Enum.Font.GothamBold
enemyNameLabel.TextSize = 14
enemyNameLabel.TextXAlignment = Enum.TextXAlignment.Left
enemyNameLabel.Parent = enemyPanel

local enemyHpFill, enemyHpVal = makeBar(enemyPanel, 32, Color3.fromRGB(220, 60, 60), "HP")

-- Indicador de sala
local roomLabel = Instance.new("TextLabel")
roomLabel.Text = "Sala 1"
roomLabel.Size = UDim2.new(0, 150, 0, 30)
roomLabel.Position = UDim2.new(0.5, -75, 0, 10)
roomLabel.BackgroundTransparency = 1
roomLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
roomLabel.Font = Enum.Font.GothamBold
roomLabel.TextSize = 18
roomLabel.Parent = root

-- Log de combat (esquerra superior)
local logFrame = Instance.new("ScrollingFrame")
logFrame.Size = UDim2.new(0, 340, 0, 160)
logFrame.Position = UDim2.new(0, 16, 0, 48)
logFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 15)
logFrame.BackgroundTransparency = 0.3
logFrame.BorderSizePixel = 1
logFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
logFrame.ScrollBarThickness = 4
logFrame.Parent = root
Instance.new("UICorner", logFrame).CornerRadius = UDim.new(0, 8)
local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Parent = logFrame

local logCount = 0
local LOG_COLORS = {
	normal  = Color3.fromRGB(200, 200, 200),
	info    = Color3.fromRGB(100, 180, 255),
	damage  = Color3.fromRGB(255, 100, 100),
	heal    = Color3.fromRGB(100, 220, 130),
	skill   = Color3.fromRGB(180, 120, 255),
	crit    = Color3.fromRGB(255, 220, 50),
	defend  = Color3.fromRGB(120, 200, 255),
	victory = Color3.fromRGB(255, 215, 0),
	boss    = Color3.fromRGB(255, 80, 80),
	danger  = Color3.fromRGB(255, 80, 80),
	poison  = Color3.fromRGB(100, 220, 80),
	burn    = Color3.fromRGB(255, 140, 40),
}

local function addLog(message, msgType)
	logCount += 1
	local entry = Instance.new("TextLabel")
	entry.Text = message
	entry.LayoutOrder = logCount
	entry.Size = UDim2.new(1, -8, 0, 0)
	entry.AutomaticSize = Enum.AutomaticSize.Y
	entry.Position = UDim2.new(0, 4, 0, 0)
	entry.BackgroundTransparency = 1
	entry.TextColor3 = LOG_COLORS[msgType] or LOG_COLORS.normal
	entry.Font = Enum.Font.Gotham
	entry.TextSize = 13
	entry.TextXAlignment = Enum.TextXAlignment.Left
	entry.TextWrapped = true
	entry.Parent = logFrame
	task.wait()
	logFrame.CanvasPosition = Vector2.new(0, logFrame.AbsoluteCanvasSize.Y)
end

-- Botons d'acció
local btnFrame = Instance.new("Frame")
btnFrame.Size = UDim2.new(0, 520, 0, 56)
btnFrame.Position = UDim2.new(0.5, -260, 1, -70)
btnFrame.BackgroundTransparency = 1
btnFrame.Parent = root

local BTN_DEFS = {
	{ key = "attack", label = "⚔️ ATACAR",    color = Color3.fromRGB(160, 40, 40)  },
	{ key = "skill",  label = "✨ HABILITAT",  color = Color3.fromRGB(80, 40, 160)  },
	{ key = "potion", label = "🧃 POCIÓ",      color = Color3.fromRGB(40, 120, 60)  },
	{ key = "defend", label = "🛡️ DEFENSAR",   color = Color3.fromRGB(40, 80, 140)  },
}

local actionButtons = {}
local btnW, gap = 120, 10
for i, def in ipairs(BTN_DEFS) do
	local btn = Instance.new("TextButton")
	btn.Text = def.label
	btn.Size = UDim2.new(0, btnW, 0, 48)
	btn.Position = UDim2.new(0, (i-1)*(btnW+gap), 0, 4)
	btn.BackgroundColor3 = def.color
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.AutoButtonColor = true
	btn.Parent = btnFrame
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(function()
		combatRemote:FireServer(def.key)
	end)
	actionButtons[def.key] = btn
end

-- Botó START
local startBtn = Instance.new("TextButton")
startBtn.Text = "▶️  INICIAR COMBAT"
startBtn.Size = UDim2.new(0, 240, 0, 54)
startBtn.Position = UDim2.new(0.5, -120, 0.5, -27)
startBtn.BackgroundColor3 = Color3.fromRGB(20, 100, 40)
startBtn.TextColor3 = Color3.new(1, 1, 1)
startBtn.Font = Enum.Font.GothamBold
startBtn.TextSize = 20
startBtn.Parent = root
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

-- Pantalla de resultat (victòria/derrota)
local resultScreen = Instance.new("Frame")
resultScreen.Size = UDim2.new(1, 0, 1, 0)
resultScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
resultScreen.BackgroundTransparency = 0.4
resultScreen.Visible = false
resultScreen.Parent = root

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(0, 400, 0, 80)
resultLabel.Position = UDim2.new(0.5, -200, 0.5, -80)
resultLabel.BackgroundTransparency = 1
resultLabel.Font = Enum.Font.GothamBold
resultLabel.TextSize = 48
resultLabel.TextColor3 = Color3.new(1, 1, 1)
resultLabel.Parent = resultScreen

local retryBtn = Instance.new("TextButton")
retryBtn.Text = "Tornar a intentar"
retryBtn.Size = UDim2.new(0, 220, 0, 50)
retryBtn.Position = UDim2.new(0.5, -110, 0.5, 20)
retryBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
retryBtn.TextColor3 = Color3.new(1, 1, 1)
retryBtn.Font = Enum.Font.GothamBold
retryBtn.TextSize = 16
retryBtn.Parent = resultScreen
Instance.new("UICorner", retryBtn).CornerRadius = UDim.new(0, 8)

-- Estadístiques de la partida (es mostren a la pantalla de victòria)
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0, 480, 0, 44)
scoreLabel.Position = UDim2.new(0.5, -240, 0.5, 80)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Font = Enum.Font.Gotham
scoreLabel.TextSize = 15
scoreLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
scoreLabel.TextWrapped = true
scoreLabel.Text = ""
scoreLabel.Parent = resultScreen

-- ============================================================
-- LÒGICA
-- ============================================================

local function setActionButtonsVisible(v)
	btnFrame.Visible = v
end

local function showResultScreen(isVictory)
	resultScreen.Visible = true
	resultLabel.Text = isVictory and "🏆 VICTÒRIA!" or "💀 GAME OVER"
	resultLabel.TextColor3 = isVictory
		and Color3.fromRGB(255, 215, 0)
		or  Color3.fromRGB(255, 80, 80)
end

local function updateBars(data)
	-- Jugador
	local hpPct = math.clamp(data.hp / data.maxHp, 0, 1)
	hpFill.Size = UDim2.new(hpPct, 0, 1, 0)
	hpVal.Text = data.hp .. "/" .. data.maxHp
	local manaPct = math.clamp(data.mana / data.maxMana, 0, 1)
	manaFill.Size = UDim2.new(manaPct, 0, 1, 0)
	manaVal.Text = data.mana .. "/" .. data.maxMana
	potionLabel.Text = "🧪 Pocions: " .. data.potions
	-- Efecte d'estat (verí / cremada)
	local se = data.statusEffect
	if se and se.turnsLeft and se.turnsLeft > 0 then
		local icons = { poison = "☠", burn = "🔥" }
		local names = { poison = "Verí", burn = "Cremada" }
		statusLabel.Text = (icons[se.type] or "?") .. " " ..
			(names[se.type] or se.type) .. ": " .. se.turnsLeft .. " torn" ..
			(se.turnsLeft == 1 and "" or "s")
		statusLabel.TextColor3 = se.type == "burn"
			and Color3.fromRGB(255, 150, 50)
			or  Color3.fromRGB(100, 220, 80)
	else
		statusLabel.Text = ""
	end
	-- Enemic (amb indicador de Fase 2)
	local ePct = math.clamp(data.enemyHp / data.enemyMaxHp, 0, 1)
	enemyHpFill.Size = UDim2.new(ePct, 0, 1, 0)
	enemyHpVal.Text = data.enemyHp .. "/" .. data.enemyMaxHp
	if data.enemyPhase == 2 then
		enemyNameLabel.Text = "⚠ " .. (data.enemyName or "---") .. " [FASE 2]"
		enemyNameLabel.TextColor3 = Color3.fromRGB(255, 60, 60)
	else
		enemyNameLabel.Text = data.enemyName or "---"
		enemyNameLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
	end
	-- Sala
	local roomText = data.room == 4 and "💀 BOSS FIGHT" or ("Sala " .. (data.room or "?"))
	roomLabel.Text = roomText
	roomLabel.TextColor3 = data.room == 4
		and Color3.fromRGB(255, 80, 80)
		or  Color3.fromRGB(255, 220, 100)
end

-- Billboard de l'enemic (creat al client)
local currentBillboard = nil
local function setupEnemyBillboard(data)
	if currentBillboard then currentBillboard:Destroy() currentBillboard = nil end
	task.wait(0.5) -- espera que el model aparegui
	local model = workspace:FindFirstChild("CurrentEnemy")
	if not model then return end
	local attachPart = model:FindFirstChild("Head")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart")
	if not attachPart then return end

	local bb = Instance.new("BillboardGui")
	bb.Name = "EnemyBillboard"
	bb.Size = UDim2.new(0, 180, 0, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Parent = attachPart

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bg.BackgroundTransparency = 0.4
	bg.BorderSizePixel = 0
	bg.Parent = bb
	Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Text = data.enemyName
	nameLbl.Size = UDim2.new(1, -4, 0.45, 0)
	nameLbl.Position = UDim2.new(0, 2, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = data.isBoss and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 220, 180)
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 13
	nameLbl.TextScaled = false
	nameLbl.Parent = bg

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(0.9, 0, 0.3, 0)
	barBg.Position = UDim2.new(0.05, 0, 0.65, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
	barBg.BorderSizePixel = 0
	barBg.Parent = bg
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 4)

	local barFill = Instance.new("Frame")
	barFill.Name = "HPFill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg
	Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 4)

	currentBillboard = bb
	return barFill
end

local enemyBarFill = nil

local function updateEnemyBillboard(hp, maxHp)
	if enemyBarFill then
		enemyBarFill.Size = UDim2.new(math.clamp(hp/maxHp, 0, 1), 0, 1, 0)
	end
end

-- ============================================================
-- EVENTS
-- ============================================================

setActionButtonsVisible(false)
resultScreen.Visible = false

startBtn.MouseButton1Click:Connect(function()
	startBtn.Visible = false
	resultScreen.Visible = false
	setActionButtonsVisible(true)
	combatRemote:FireServer("startGame")
	addLog("Iniciant combat...", "info")
end)

retryBtn.MouseButton1Click:Connect(function()
	resultScreen.Visible = false
	startBtn.Visible = true
	setActionButtonsVisible(false)
	scoreLabel.Text = ""
	-- Netejar log
	for _, c in ipairs(logFrame:GetChildren()) do
		if c:IsA("TextLabel") then c:Destroy() end
	end
	logCount = 0
	addLog("Benvingut de nou a Aincrad Duel!", "info")
end)

uiRemote.OnClientEvent:Connect(function(action, data)
	if action == "log" then
		addLog(data.message, data.msgType)

	elseif action == "stats" then
		updateBars(data)
		updateEnemyBillboard(data.enemyHp, data.enemyMaxHp)

	elseif action == "spawnEnemy" then
		task.spawn(function()
			enemyBarFill = setupEnemyBillboard(data)
		end)

	elseif action == "bossPhase2" then
		addLog("⚠️ FASE 2 ACTIVADA!", "boss")

	elseif action == "roomClear" then
		addLog("=== SALA SUPERADA! Recuperes 20 HP i 10 Mana. ===", "victory")
		task.wait(1.5)
		combatRemote:FireServer("nextRoom")

	elseif action == "victory" then
		if data.score then
			scoreLabel.Text = string.format(
				"⚔ Dany causat: %d   |   ⚡ Crítics: %d   |   🎯 Torns: %d   |   🧃 Pocions: %d",
				data.score.damageDealt, data.score.critsLanded,
				data.score.turnsUsed, data.score.potionsUsed
			)
		end
		showResultScreen(true)
		setActionButtonsVisible(false)

	elseif action == "gameOver" then
		showResultScreen(false)
		setActionButtonsVisible(false)
	end
end)

addLog("Benvingut a Aincrad Duel!", "info")
addLog("Prem INICIAR COMBAT per començar.", "info")
