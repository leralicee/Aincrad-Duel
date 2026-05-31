# Casos de prova — Aincrad Duel

Registre de tots els casos de prova executats durant la Fase 4 (Proves i depuració).

Per a la descripció detallada de cada cas (precondicions, resultats, metodologia), vegeu [`docs/04_proves_i_depuracio.md`](../docs/04_proves_i_depuracio.md).

---

## Resum de l'estat de les proves

| ID | Descripció | Mòdul | Estat |
|---|---|---|---|
| TC-01 | Atac bàsic: càlcul de dany correcte | Enemy:attack / CombatManager | ✅ PASSA |
| TC-02 | Defensa: reducció de dany al torn de l'enemic | Enemy:attack / PlayerStats | ✅ PASSA |
| TC-03 | Usar poció sense existències | PlayerStats:usePotion / CombatManager | ✅ PASSA |
| TC-04 | Habilitat especial amb mana insuficient | PlayerStats:useSkill / CombatManager | ✅ PASSA |
| TC-05 | Boss entra a Fase 2 al 50% HP | Boss:checkPhase / CombatManager | ✅ PASSA |
| TC-06 | Game Over quan el jugador mor | CombatManager:enemyTurn | ✅ PASSA |
| TC-07 | Victòria en derrotar el Boss final | CombatManager:processAction | ✅ PASSA |

**Total: 7/7 casos passen** ✅

---

## Bugs detectats durant les proves

| ID | Descripció | Mòdul afectat | Estat |
|---|---|---|---|
| ERROR-01 | Defensa no aplica el multiplicador ×2 | Enemy:attack, Enemy:specialAttack | ✅ Corregit |
| ERROR-02 | `isDefending` no es reseteja entre torns | CombatManager:enemyTurn | ✅ Corregit |

---

## Metodologia

- **Entorn:** Roblox Studio Play (simulació local, 1 jugador)
- **Mètode:** Proves manuals + `print()` a la consola del servidor
- **Limitació:** No hi ha framework de testing unitari — totes les proves són d'integració
