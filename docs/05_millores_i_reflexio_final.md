# 05 — Millores i reflexió final

## 1. Millores identificades

Durant el procés de proves i la revisió final del projecte es van identificar les millores potencials següents:

### Millora A — Separació de canals de comunicació Client-Servidor

**Problema identificat:**
La versió inicial del projecte usava un sol `RemoteEvent` ("CombatAction") per a tot tipus de missatges entre servidor i client: actualitzacions de GUI, resultats de combat, logs de text, etc. Això obligava el client a filtrar per tipus de missatge i barrejava les responsabilitats del channel.

**Millora proposada:**
Crear un segon `RemoteEvent` ("UIUpdate") dedicat exclusivament a actualitzacions de la interfície d'usuari, separant semànticament les accions de combat (client → servidor) de les notificacions d'estat (servidor → client).

**Estat:** ✅ **Aplicada** (vegeu secció 2, Millora 1)

---

### Millora B — Funció centralitzada d'actualització de la GUI

**Problema identificat:**
A la versió inicial, cada funció del `CombatManager` que modificava un stat enviava les actualitzacions de GUI individualment i de manera dispersa. Era fàcil oblidar actualitzar la UI en algun punt del flux, causant que les barres mostressin valors incorrectes.

**Millora proposada:**
Crear una funció `pushStats()` que recopili tots els stats actuals (HP, Mana, potions, HP enemic, fase Boss, sala actual) i els enviï al client en una sola crida. Qualsevol funció que modifiqui stats simplement crida `pushStats()` al final.

**Estat:** ✅ **Aplicada** (vegeu secció 2, Millora 2)

---

### Millora C — Fallback segur per a models sense BasePart

**Problema identificat:**
La funció `spawnEnemy` fallava amb un error de Roblox si el model 3D de l'enemic no tenia cap `BasePart` configurada com a `PrimaryPart`. La crida a `SetPrimaryPartCFrame` sense `PrimaryPart` genera un error que atura l'execució del script del servidor.

**Millora proposada:**
Afegir una comprovació: si el model no té `BasePart`, crear una `Part` transparent invisible com a placeholder per permetre que el `CFrame` s'apliqui sense errors, mantenint la lògica de combat funcional fins i tot amb assets incomplets.

**Estat:** ✅ **Aplicada** (integrada a la Millora 2, secció 2)

---

## 2. Millores aplicades (amb codi)

### Millora 1 — Separació de RemoteEvents (CombatAction / UIUpdate)

**Situació inicial:**

Originalment, s'enviaven totes les comunicacions servidor→client per `CombatAction`, el mateix RemoteEvent que el client usava per enviar accions al servidor. El servidor havia de reutilitzar-lo en sentit invers, barrejant fluxos:

```lua
-- CODI INICIAL: un sol RemoteEvent per a tot
local combatRemote = ReplicatedStorage:WaitForChild("CombatAction")

local function notifyClient(msgType, data)
    -- el client rep per CombatAction tant accions com notificacions d'UI
    combatRemote:FireClient(currentPlayer, msgType, data)
end

combatRemote.OnServerEvent:Connect(function(player, action)
    -- el servidor rep accions del jugador pel mateix event
    processAction(player, action)
end)
```

El client havia de distingir si el missatge rebut era una acció de joc o una actualització de UI, amb la mateixa connexió.

**Codi millorat:**

S'afegeix un segon RemoteEvent al `default.project.json`:

```json
"ReplicatedStorage": {
  "CombatAction": { "$className": "RemoteEvent" },
  "UIUpdate":     { "$className": "RemoteEvent" }
}
```

El servidor separa les responsabilitats: `CombatAction` rep accions del jugador, `UIUpdate` envia actualitzacions de UI:

```lua
-- CODI MILLORAT: RemoteEvents separats per responsabilitat
local combatRemote = ReplicatedStorage:WaitForChild("CombatAction")
local uiRemote     = ReplicatedStorage:WaitForChild("UIUpdate")

local function sendUI(action, data)
    if currentPlayer then
        uiRemote:FireClient(currentPlayer, action, data or {})
    end
end

-- El client escolta UIUpdate exclusivament per actualitzar la GUI
-- CombatAction.OnServerEvent rep NOMÉS accions del jugador
combatRemote.OnServerEvent:Connect(function(player, action)
    processAction(player, action)
end)
```

**Benefici:** Separació clara de responsabilitats. El flux de dades és unidireccional per a cada canal, el codi és més llegible i menys propens a errors de routing.

---

### Millora 2 — Funció `pushStats()` centralitzada + Fallback per a models sense BasePart

**Situació inicial:**

Cada funció que modificava stats enviava les actualitzacions manualment i de manera incompleta:

```lua
-- CODI INICIAL: actualitzacions disperses, inconsistents i fàcilment oblidades
local function processAction(player, action)
    if action == "attack" then
        local dealt = currentEnemyData:takeDamage(playerObj.atk)
        -- s'envia el log però no s'actualitzen totes les barres
        sendUI("log", { message = "Ataces per " .. dealt })
        sendUI("enemyHp", { hp = currentEnemyData.hp })
        -- ← Mana, potions i stats del jugador no s'actualitzen aquí!
    elseif action == "potion" then
        playerObj:usePotion()
        sendUI("playerHp", { hp = playerObj.hp })
        -- ← potions no actualitzat, barra enemiga sense refresc
    end
end
```

A més, `spawnEnemy` no comprovava si el model tenia `BasePart`, causant un error crític:

```lua
-- CODI INICIAL: sense fallback per a PrimaryPart
local model = template:Clone()
model.Parent = workspace
-- ERROR si el model no té BasePart configurada com a PrimaryPart:
model:SetPrimaryPartCFrame(CFrame.new(10, 2, 0))
```

**Codi millorat:**

Es crea `pushStats()` que centralitza totes les actualitzacions en una sola crida:

```lua
-- CODI MILLORAT: funció centralitzada que sempre envia l'estat complet
local function pushStats()
    if not playerObj or not currentEnemyData then return end
    sendUI("stats", {
        hp = playerObj.hp,       maxHp = playerObj.maxHp,
        mana = playerObj.mana,   maxMana = playerObj.maxMana,
        potions = playerObj.potions,
        enemyHp = currentEnemyData.hp,
        enemyMaxHp = currentEnemyData.maxHp,
        enemyName = currentEnemyData.name,
        enemyPhase = currentEnemyData.phase,
        room = currentRoom,
    })
end

-- Cada funció simplement crida pushStats() al final:
local function processAction(player, action)
    -- ... lògica de l'acció ...
    log(message, msgType)
    pushStats()  -- ← una sola crida garanteix GUI sempre sincronitzada
end
```

I `spawnEnemy` ara crea una `Part` transparent de fallback si el model no té `BasePart`:

```lua
-- CODI MILLORAT: fallback segur per a assets incomplets
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
model:SetPrimaryPartCFrame(CFrame.new(10, 2, 0))  -- ara sempre funciona
```

**Benefici:** Una sola crida a `pushStats()` garanteix que el client sempre té l'estat complet actualitzat sense omissions. El fallback de `BasePart` fa el sistema robust davant d'assets 3D incomplets o en construcció.

---

## 3. Reflexió final

### Sobre el procés de desenvolupament

El projecte ha permès aplicar de manera pràctica conceptes del mòdul que fins ara eren abstractes: la separació client-servidor (equivalent a frontend/backend en una aplicació web), l'herència orientada a objectes en Lua, i la gestió d'estats finits amb una variable de control (`combatState`).

La part tècnicament més interessant va ser dissenyar l'arquitectura de comunicació amb `RemoteEvents`. En un sistema web convencional, el client fa peticions HTTP al servidor i espera una resposta síncrona; a Roblox, el flux és equivalent però amb events asíncrons bidireccionals. Entendre aquesta analogia va facilitar molt el disseny de les funcions `sendUI` i `processAction`.

La configuració de l'entorn (Rojo + VS Code + Roblox Studio) va ser un repte inesperat però valuós: va forçar a entendre com funciona la sincronització de fitxers i els formats que Rojo espera (noms de fitxer, extensió, fitxers binaris `.rbxm`).

### Sobre l'ús d'IA

La IA (Claude) va ser útil en dues fases diferenciades:

**Exploració inicial (Fase 1):** Per validar decisions de disseny (estructura de mòduls, mecàniques de combat) i obtenir alternatives ràpides. En lloc de buscar documentació extensa, la IA va permetre explorar opcions i justificar-les amb arguments tècnics concrets.

**Configuració i depuració (Fase 3-4):** Per configurar el `default.project.json`, entendre els errors de Rojo i depurar bugs com el de `isDefending`. Sense aquest suport, la configuració inicial hauria trigat molt més.

El límit de la IA es va veure quan el context era molt específic al projecte: noms de variables concrets, estructura real vs. estructura teòrica. Cal verificar sempre el codi generat contra el codi real del projecte.

### Sobre el resultat

El joc completa el seu bucle de joc complet: el jugador pot iniciar una partida, derrotar 3 sales d'enemics progressivament difícils, enfrontar-se al Boss amb 2 fases i veure la pantalla de victòria o derrota. La interfície mostra l'estat del combat en temps real amb barres de HP i Mana, log de combat i feedback textual de cada acció.

**Millores futures que no han entrat a l'abast d'aquest projecte:**
- So i música de fons per a cada tipus de combat
- Animacions de combat dels models 3D (atacar, rebre dany, morir)
- Sistema de guardat de millors puntuacions (DataStore de Roblox)
- Mode multijugador cooperatiu (l'arquitectura client-servidor actual ho facilitaria)
- Sistema de verí i estats alterats (explorat a Fase 1 però descartat per temps)
