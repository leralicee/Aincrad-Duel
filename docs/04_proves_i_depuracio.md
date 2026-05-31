# 04 — Proves i depuració

## 1. Casos de prova

### TC-01 — Atac bàsic: càlcul de dany correcte

| Camp | Valor |
|---|---|
| **Descripció** | L'acció "attack" del jugador ha de reduir l'HP de l'enemic amb la fórmula `max(1, ATK_jugador - DEF_enemic)`. |
| **Precondicions** | playerObj.atk = 15, currentEnemyData.def = 2, currentEnemyData.hp = 30 |
| **Acció** | El jugador prem el botó ATACAR |
| **Resultat esperat** | Dany = 13, enemyHp = 17, missatge "Ataces Goblin Scout per 13 de dany!" |
| **Resultat obtingut** | Dany = 13, HP actualitzat correctament, missatge mostrat al log |
| **Estat** | ✅ PASSA |

---

### TC-02 — Defensa: reducció de dany al torn de l'enemic

| Camp | Valor |
|---|---|
| **Descripció** | Quan el jugador s'ha defensat, el dany rebut a l'atac de l'enemic ha de calcular-se amb `DEF × 2`. |
| **Precondicions** | playerObj.def = 5, playerObj.isDefending = true, currentEnemyData.atk = 8 |
| **Acció** | L'enemic executa atac bàsic (enemyTurn) |
| **Resultat esperat** | Dany = max(1, 8 - 10) = 1, isDefending es reseteja a false |
| **Resultat obtingut** | Dany = 1, isDefending = false després del torn de l'enemic |
| **Estat** | ✅ PASSA |

---

### TC-03 — Usar poció sense existències

| Camp | Valor |
|---|---|
| **Descripció** | Si el jugador no té pocions i prem POCIÓ, el sistema ha de mostrar un error i no canviar cap stat. |
| **Precondicions** | playerObj.potions = 0, playerObj.hp = 50 |
| **Acció** | El jugador selecciona l'acció "potion" |
| **Resultat esperat** | Missatge "No tens pocions!", HP i potions sense canvis, el torn NO avança a ENEMY_TURN |
| **Resultat obtingut** | Missatge d'error mostrat, HP = 50, potions = 0, combatState continua a PLAYER_TURN |
| **Estat** | ✅ PASSA |

---

### TC-04 — Habilitat especial amb mana insuficient

| Camp | Valor |
|---|---|
| **Descripció** | Si el jugador intenta usar la habilitat especial amb menys de 10 de mana, l'acció ha de ser rebutjada. |
| **Precondicions** | playerObj.mana = 5 |
| **Acció** | El jugador selecciona l'acció "skill" |
| **Resultat esperat** | Missatge "Mana insuficient!", mana sense canvis, enemic no rep dany |
| **Resultat obtingut** | Missatge "Mana insuficient! (necessites 10)", mana = 5, HP enemic sense canvis |
| **Estat** | ✅ PASSA |

---

### TC-05 — Boss entra a Fase 2 al 50% HP

| Camp | Valor |
|---|---|
| **Descripció** | Quan l'HP del Boss baixa per sota del 50% del seu màxim, ha de passar a Fase 2 i augmentar el seu ATK. |
| **Precondicions** | Boss.maxHp = 120, Boss.hp > 60, Boss.phase = 1, Boss.atk = 18 |
| **Acció** | El jugador ataca fins que Boss.hp ≤ 60 |
| **Resultat esperat** | checkPhase() retorna true, Boss.atk = 27 (×1.5), missatge "FASE 2", event bossPhase2 disparat |
| **Resultat obtingut** | Fase 2 activada correctament, ATK augmentat, pantalla notificada |
| **Estat** | ✅ PASSA |

---

### TC-06 — Game Over quan el jugador mor

| Camp | Valor |
|---|---|
| **Descripció** | Si l'HP del jugador arriba a 0 durant el torn de l'enemic, el combat ha d'acabar amb Game Over. |
| **Precondicions** | playerObj.hp = 5, currentEnemyData.atk = 20, playerObj.isDefending = false |
| **Acció** | L'enemic executa atac bàsic (enemyTurn) |
| **Resultat esperat** | playerObj.hp = 0, combatState = "GAME_OVER", event "gameOver" disparat al client |
| **Resultat obtingut** | HP = 0, pantalla de Game Over mostrada, botons de combat desactivats |
| **Estat** | ✅ PASSA |

---

### TC-07 — Victòria en derrotar el Boss final

| Camp | Valor |
|---|---|
| **Descripció** | Quan el Boss mor i currentRoom == 4, el joc ha d'enviar l'event "victory" i no avançar a cap sala nova. |
| **Precondicions** | currentRoom = 4, Boss.hp = 1, playerObj.hp > 0 |
| **Acció** | El jugador ataca (qualsevol acció que faci ≥ 1 de dany) |
| **Resultat esperat** | combatState = "VICTORY", event "victory" disparat, NO event "roomClear" |
| **Resultat obtingut** | Pantalla de victòria mostrada correctament |
| **Estat** | ✅ PASSA |

---

## 2. Errors detectats i correccions

### ERROR-01 — La defensa no aplicava el multiplicador correctament

**Descripció del símptoma:**
Durant les proves del combat, la defensa reduïa el dany però no l'eliminava gairebé del tot quan l'ATK de l'enemic era proper al DEF del jugador. Es va detectar que la funció `attack` de l'enemic no comprovava si el jugador estava en mode de defensa.

**Causa:**
La funció `attack` de l'enemic calculava el dany sempre amb `player.def` simple, sense tenir en compte l'estat `isDefending`:

```lua
-- CODI INCORRECTE (versió inicial)
function Enemy:attack(player)
    local actualDamage = math.max(1, self.atk - player.def)
    player.hp = math.max(0, player.hp - actualDamage)
    return actualDamage
end
```

**Solució aplicada:**
S'afegeix una comprovació condicional per doblar la defensa quan `isDefending` és `true`:

```lua
-- CODI CORREGIT
function Enemy:attack(player)
    local actualDamage = math.max(1, self.atk - (player.isDefending and player.def * 2 or player.def))
    player.hp = math.max(0, player.hp - actualDamage)
    return actualDamage
end
```

La mateixa correcció s'aplica a `Enemy:specialAttack(player)`.

---

### ERROR-02 — L'estat `isDefending` no es resetejava entre torns

**Descripció del símptoma:**
Un cop el jugador havia seleccionat "Defendre" en un torn, la defensa es mantenia activa indefinidament en tots els torns posteriors. L'enemic feia molt poc dany en tots els torns, fent el joc trivial.

**Causa:**
La variable `playerObj.isDefending` s'assignava a `true` quan el jugador es defensava, però no hi havia cap instrucció que la retornés a `false` al final del torn de l'enemic:

```lua
-- CODI INCORRECTE (enemyTurn inicial)
local function enemyTurn()
    if combatState ~= "ENEMY_TURN" then return end
    task.wait(1.2)
    local action = currentEnemyData:chooseAction()
    local damage = currentEnemyData:attack(playerObj)
    -- ← isDefending mai es reseteja!
    pushStats()
    ...
end
```

**Solució aplicada:**
S'afegeix `playerObj.isDefending = false` just après d'aplicar l'atac de l'enemic:

```lua
-- CODI CORREGIT
local function enemyTurn()
    if combatState ~= "ENEMY_TURN" then return end
    task.wait(1.2)
    local action = currentEnemyData:chooseAction()
    local damage = currentEnemyData:attack(playerObj)
    playerObj.isDefending = false  -- ← reset explícit al final del torn enemic
    pushStats()
    ...
end
```

---

## 3. Metodologia de proves

Les proves es van realitzar en dues modalitats:

1. **Proves manuals amb Roblox Studio Play**: S'inicia la simulació amb el botó Play i es prova cada botó d'acció, verificant els missatges del combat log i les barres de HP/Mana. Es comprova cada cas límit (0 pocions, 0 mana, HP crític, Boss al 50%).

2. **Proves de codi amb `print`**: Per verificar valors interns (dany calculat, valor de `combatState`, fase del Boss), s'afegien `print()` temporals al servidor i s'observaven a la consola d'Output de Roblox Studio.

**Limitació tècnica:** Roblox Studio no disposa d'un framework de testing unitari natiu. Totes les proves realitzades són proves d'integració manuals sobre el joc en execució. Una millora futura seria implementar un mòdul de test que comprovi les funcions de `CharacterStats` de manera aïllada.
