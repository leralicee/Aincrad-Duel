# Manual tècnic — Aincrad Duel

## Arquitectura del sistema

Aincrad Duel segueix l'arquitectura estàndard de Roblox: codi de servidor separat del codi de client, comunicats de manera asíncrona via `RemoteEvent`.

```
[Client - LocalScript]              [Servidor - Script]
  UIController.client.luau    ←→    CombatManager/init.server.luau
        |                                   |
  StarterGui/BattleGUI            ServerScriptService/CombatManager
        |                                   |
        +-------- ReplicatedStorage --------+
                  CombatAction (client → servidor)
                  UIUpdate    (servidor → client)
```

**Principi clau:** Tota la lògica de joc (càlcul de dany, gestió d'estats, control de torns) s'executa al servidor. El client és passiu: envia accions del jugador i rep notificacions d'estat per actualitzar la GUI.

---

## Estructura de fitxers

```
joc/
├── default.project.json              # Configuració Rojo
└── src/
    ├── server/
    │   ├── Server.server.luau        # Script servidor (PlayerAdded/Removing)
    │   └── CombatManager/
    │       ├── init.server.luau      # Lògica central del combat (Script)
    │       ├── CharacterStats.luau   # Classe base HP/ATK/DEF (ModuleScript)
    │       ├── PlayerStats.luau      # Jugador: Mana, pocions, crítics (ModuleScript)
    │       ├── Enemy.luau            # Enemic NPC amb IA (ModuleScript)
    │       └── Boss.luau             # Boss amb 2 fases (ModuleScript)
    ├── client/
    │   └── init.client.luau         # Punt d'entrada del client (LocalScript)
    ├── gui/
    │   └── UIController.client.luau # GUI de combat completa (LocalScript)
    └── assets/
        └── EnemyTemplates/           # Models 3D dels enemics (format binari .rbxm)
            ├── GoblinModel.rbxm
            ├── OrcModel.rbxm
            ├── TrollModel.rbxm
            └── BossModel.rbxm
```

---

## Jerarquia a Roblox Studio (post-sync Rojo)

```
DataModel
├── ReplicatedStorage
│   ├── CombatAction  (RemoteEvent)  ← client → servidor: accions del jugador
│   └── UIUpdate      (RemoteEvent)  ← servidor → client: actualitzacions de GUI
├── ServerScriptService
│   ├── Server        (Script)
│   └── CombatManager (Script)
│       ├── CharacterStats  (ModuleScript)
│       ├── PlayerStats     (ModuleScript)
│       ├── Enemy           (ModuleScript)
│       └── Boss            (ModuleScript)
├── ServerStorage
│   └── EnemyTemplates (Folder)
│       ├── GoblinModel (Model)
│       ├── OrcModel    (Model)
│       ├── TrollModel  (Model)
│       └── BossModel   (Model)
└── StarterGui
    └── BattleGUI (ScreenGui, ResetOnSpawn = false)
        └── UIController (LocalScript)
```

---

## Mòduls del servidor

### CharacterStats (ModuleScript)

Classe base per a totes les entitats de combat. Usada via herència per `PlayerStats`, `Enemy` i `Boss`.

| Mètode | Signatura | Retorna | Descripció |
|---|---|---|---|
| `new` | `(name, maxHp, atk, def)` | self | Constructor. Inicialitza hp = maxHp. |
| `takeDamage` | `(amount)` | actualDamage | Redueix hp per amount. Retorna dany real aplicat. |
| `isDead` | `()` | boolean | true si hp ≤ 0. |
| `getHpPercent` | `()` | number (0–1) | Fracció de vida restant. |
| `heal` | `(amount)` | — | Augmenta hp, màxim = maxHp. |

### PlayerStats (ModuleScript)

Hereta de CharacterStats via `setmetatable`. Valors inicials: hp=100, atk=15, def=5, mana=50, maxMana=50, potions=3.

| Mètode | Signatura | Retorna | Descripció |
|---|---|---|---|
| `rollCrit` | `()` | boolean | 15% de probabilitat de crític. |
| `useSkill` | `(enemy)` | (damage, isCrit) | Atac especial (cost: 10 mana). Retorna (0, false) si mana < 10. |
| `usePotion` | `()` | boolean | +30 HP. Retorna false si potions = 0. |
| `regenerateMana` | `(amount)` | — | Augmenta mana, màxim = maxMana. |

### Enemy (ModuleScript)

Hereta de CharacterStats. Afegeix lògica de IA senzilla i el camp `roomId`.

| Mètode | Signatura | Retorna | Descripció |
|---|---|---|---|
| `chooseAction` | `()` | "attack"\|"special" | 70% atac bàsic, 30% habilitat especial. |
| `attack` | `(player)` | actualDamage | Dany = max(1, atk - defJugador×modificador). |
| `specialAttack` | `(player)` | actualDamage | Dany = max(1, atk×1.5 - defJugador×modificador). |

El modificador de defensa és ×2 si `player.isDefending = true`, ×1 en cas contrari.

### Boss (ModuleScript)

Hereta d'Enemy. Afegeix sistema de 2 fases. `roomId` fix = 4.

| Mètode | Signatura | Retorna | Descripció |
|---|---|---|---|
| `checkPhase` | `()` | boolean | Si hp ≤ 50% i phase == 1: phase = 2, atk = atk × 1.5. Retorna true si hi ha canvi. |

### CombatManager (init.server.luau)

Script principal del servidor. Gestiona tot el flux de combat.

**Variables d'estat globals:**

| Variable | Possibles valors | Descripció |
|---|---|---|
| `combatState` | IDLE / PLAYER_TURN / ENEMY_TURN / ROOM_CLEAR / VICTORY / GAME_OVER | Fase actual del combat |
| `currentRoom` | 1–4 (4 = Boss) | Sala actual |
| `currentPlayer` | Player \| nil | Jugador actiu a la sessió |
| `playerObj` | PlayerStats \| nil | Stats del jugador actiu |
| `currentEnemyData` | Enemy/Boss \| nil | Stats de l'enemic actiu |
| `currentEnemyModel` | Model \| nil | Model 3D a l'Workspace |

**Flux de combat:**

```
OnServerEvent("startGame")
    → playerObj = PlayerStats.new(player.Name)
    → currentRoom = 1
    → startRoom()
        → spawnEnemy() → currentEnemyData = Enemy.new() o Boss.new()
        → combatState = "PLAYER_TURN"
        → pushStats() + log("El teu torn")

OnServerEvent("attack"|"skill"|"potion"|"defend")
    → processAction(player, action)
        → calcula dany / efecte
        → log() + pushStats()
        → [boss: checkPhase()?] → sendUI("bossPhase2")
        → [enemic mort?] → ROOM_CLEAR → sendUI("roomClear") o "victory"
        → combatState = "ENEMY_TURN" → enemyTurn()
            → task.wait(1.2)
            → chooseAction() → attack() o specialAttack()
            → playerObj.isDefending = false
            → log() + pushStats()
            → [jugador mort?] → GAME_OVER → sendUI("gameOver")
            → combatState = "PLAYER_TURN"

OnServerEvent("nextRoom")
    → currentRoom += 1
    → startRoom()
```

---

## Comunicació Client-Servidor

### Client → Servidor (`CombatAction:FireServer`)

| Acció | Quan s'envia |
|---|---|
| `"startGame"` | Jugador prem el botó "Iniciar partida" |
| `"attack"` | Jugador prem "Atacar" |
| `"skill"` | Jugador prem "Habilitat especial" |
| `"potion"` | Jugador prem "Poció" |
| `"defend"` | Jugador prem "Defensar" |
| `"nextRoom"` | Jugador prem "Sala següent" (post ROOM_CLEAR) |

### Servidor → Client (`UIUpdate:FireClient`)

| Acció | Dades | Descripció |
|---|---|---|
| `"log"` | `{message: string, msgType: string}` | Afegeix línia al log de combat |
| `"stats"` | `{hp, maxHp, mana, maxMana, potions, enemyHp, enemyMaxHp, enemyName, enemyPhase, room}` | Actualitza totes les barres i etiquetes |
| `"spawnEnemy"` | `{enemyName, maxHp, isBoss}` | Notifica l'aparició d'un enemic nou |
| `"bossPhase2"` | `{}` | Notifica l'activació de la Fase 2 del Boss |
| `"roomClear"` | `{}` | Mostra el botó "Sala següent" |
| `"victory"` | `{}` | Mostra la pantalla de victòria |
| `"gameOver"` | `{}` | Mostra la pantalla de derrota |

Els `msgType` del log (`"normal"`, `"damage"`, `"heal"`, `"crit"`, `"skill"`, `"defend"`, `"info"`, `"boss"`, `"victory"`, `"danger"`) controlen el color del text al client.

---

## Com configurar i executar el projecte

### Requisits previs

| Eina | Versió | Descàrrega |
|---|---|---|
| Roblox Studio | Última versió | roblox.com/create |
| Rojo (CLI) | 7.x | rojo.space |
| Rojo (plugin de Studio) | Compatible amb CLI | rojo.space |
| Git | Qualsevol | git-scm.com |

### Passos d'instal·lació

1. **Clona el repositori:**
   ```bash
   git clone <url-del-repositori>
   cd Aincrad-Duel/joc
   ```

2. **Inicia el servidor Rojo:**
   ```bash
   rojo serve
   ```
   Ha de mostrar: `Listening on port 34872`

3. **Obre Roblox Studio** i crea un lloc nou buit (Baseplate).

4. Al plugin Rojo de Studio, prem **Connect** (es connecta a `localhost:34872`).

5. Els scripts i RemoteEvents apareixeran automàticament a l'Explorer de Studio.

6. Prem **Play** a Studio per provar el joc en mode local.

### Resolució de problemes comuns

**Problema:** Objectes duplicats a l'Explorer de Studio (ex: dos CombatManager).
**Solució:** Rojo afegeix els seus objectes als originals de Studio. Elimina manualment els originals (els que Rojo no gestiona).

**Problema:** Un script eliminat de Studio no torna en reconnectar.
**Solució:** Rojo necessita un canvi de fitxer per sincronitzar. Fes un canvi menor a qualsevol `.luau` del projecte (espai, retorn de línia) i desa.

**Problema:** Error "Model does not have a PrimaryPart set" en iniciar el combat.
**Solució:** El model 3D de l'enemic no té `BasePart`. El `spawnEnemy` ja inclou un fallback que crea una Part invisible. Si el model és completament buit, revisa el fitxer `.rbxm` corresponent.

### Gestió dels assets 3D

Els models d'enemics estan a `src/assets/EnemyTemplates/` com a fitxers `.rbxm` (format binari de Roblox). Rojo els importa directament a `ServerStorage/EnemyTemplates`. Per substituir un model:

1. Obre el model a Roblox Studio.
2. Fes clic dret → **Save to File** → guarda com a `.rbxm`.
3. Reemplaça el fitxer `.rbxm` corresponent a `src/assets/EnemyTemplates/`.
4. Rojo sincronitzarà el model automàticament.
