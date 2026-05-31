-- Enemy (ModuleScript)
local CharacterStats = require(script.Parent.CharacterStats)
local Enemy = setmetatable({}, CharacterStats)
Enemy.__index = Enemy

-- specialEffect: { type="poison"|"burn", damage=N, turns=N } o nil
function Enemy.new(name, maxHp, atk, def, roomId, specialEffect)
	local self = setmetatable(CharacterStats.new(name, maxHp, atk, def), Enemy)
	self.roomId = roomId or 1
	self.specialEffect = specialEffect or nil
	return self
end

function Enemy:chooseAction()
	return math.random(1, 100) <= 70 and "attack" or "special"
end

function Enemy:specialAttack(player)
	local damage = math.floor(self.atk * 1.5)
	local actualDamage = math.max(1, damage - (player.isDefending and player.def * 2 or player.def))
	player.hp = math.max(0, player.hp - actualDamage)
	-- Aplica efecte d'estat si l'enemic en té un configurat
	if self.specialEffect and player.applyStatusEffect then
		player:applyStatusEffect(self.specialEffect.type, self.specialEffect.damage, self.specialEffect.turns)
	end
	return actualDamage
end

function Enemy:attack(player)
	local actualDamage = math.max(1, self.atk - (player.isDefending and player.def * 2 or player.def))
	player.hp = math.max(0, player.hp - actualDamage)
	return actualDamage
end

return Enemy
