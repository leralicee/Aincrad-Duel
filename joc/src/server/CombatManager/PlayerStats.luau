-- PlayerStats (ModuleScript)
local CharacterStats = require(script.Parent.CharacterStats)
local PlayerStats = setmetatable({}, CharacterStats)
PlayerStats.__index = PlayerStats

function PlayerStats.new(name)
	local self = setmetatable(CharacterStats.new(name, 100, 15, 5), PlayerStats)
	self.maxMana = 50
	self.mana = 50
	self.potions = 3
	self.isDefending = false
	self.critChance = 0.15
	self.statusEffect = nil  -- { type="poison"|"burn", damage=N, turnsLeft=N }
	return self
end

function PlayerStats:rollCrit()
	return math.random() < self.critChance
end

-- Aplica un efecte d'estat (no sobreescriu un efecte actiu)
function PlayerStats:applyStatusEffect(effectType, damage, turns)
	if self.statusEffect == nil then
		self.statusEffect = { type = effectType, damage = damage, turnsLeft = turns }
	end
end

-- Executa el tick de l'efecte d'estat; retorna (dany, tipus) o (0, nil)
function PlayerStats:tickStatusEffect()
	if not self.statusEffect then return 0, nil end
	local dmg = self.statusEffect.damage
	local effectType = self.statusEffect.type
	self.hp = math.max(0, self.hp - dmg)
	self.statusEffect.turnsLeft = self.statusEffect.turnsLeft - 1
	if self.statusEffect.turnsLeft <= 0 then
		self.statusEffect = nil
	end
	return dmg, effectType
end

function PlayerStats:useSkill(enemy)
	if self.mana >= 10 then
		self.mana = self.mana - 10
		local damage = self.atk * 2
		local isCrit = self:rollCrit()
		if isCrit then damage = math.floor(damage * 1.5) end
		local dealt = enemy:takeDamage(damage)
		return dealt, isCrit
	end
	return 0, false
end

function PlayerStats:usePotion()
	if self.potions > 0 then
		self.potions = self.potions - 1
		self:heal(30)
		return true
	end
	return false
end

function PlayerStats:regenerateMana(amount)
	amount = amount or 5
	self.mana = math.min(self.maxMana, self.mana + amount)
end

return PlayerStats
