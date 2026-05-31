-- Boss (ModuleScript)
local Enemy = require(script.Parent.Enemy)
local Boss = setmetatable({}, Enemy)
Boss.__index = Boss

function Boss.new(name, maxHp, atk, def)
	local self = setmetatable(Enemy.new(name, maxHp, atk, def, 4), Boss)
	self.phase = 1
	self.phase2Threshold = 0.5
	self.enraged = false
	return self
end

function Boss:checkPhase()
	if not self.enraged and self.hp <= self.maxHp * self.phase2Threshold then
		self.phase = 2
		self.enraged = true
		self.atk = math.floor(self.atk * 1.5)
		return true
	end
	return false
end

-- En Fase 2 és més agressiu (50% especial) i aplica cremada
function Boss:chooseAction()
	local specialChance = self.phase == 2 and 50 or 30
	return math.random(1, 100) > specialChance and "attack" or "special"
end

function Boss:specialAttack(player)
	local multiplier = self.phase == 2 and 1.75 or 1.5
	local damage = math.floor(self.atk * multiplier)
	local actualDamage = math.max(1, damage - (player.isDefending and player.def * 2 or player.def))
	player.hp = math.max(0, player.hp - actualDamage)
	-- Fase 2: aplica cremada al jugador
	if self.phase == 2 and player.applyStatusEffect then
		player:applyStatusEffect("burn", 6, 2)
	end
	return actualDamage
end

return Boss
