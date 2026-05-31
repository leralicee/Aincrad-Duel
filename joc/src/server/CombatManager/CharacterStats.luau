-- CharacterStats (ModuleScript)
local CharacterStats = {}
CharacterStats.__index = CharacterStats

function CharacterStats.new(name, maxHp, atk, def)
	local self = setmetatable({}, CharacterStats)
	self.name = name
	self.maxHp = maxHp
	self.hp = maxHp
	self.atk = atk
	self.def = def
	return self
end

function CharacterStats:takeDamage(amount)
	local actualDamage = math.max(1, amount - self.def)
	self.hp = math.max(0, self.hp - actualDamage)
	return actualDamage
end

function CharacterStats:isDead()
	return self.hp <= 0
end

function CharacterStats:getHpPercent()
	return self.hp / self.maxHp
end

function CharacterStats:heal(amount)
	self.hp = math.min(self.maxHp, self.hp + amount)
end

return CharacterStats
