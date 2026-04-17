# 02 — Model del joc

---

## 1. Components principals del joc

El sistema d'Aincrad Duel es compon de sis components principals:

- **CharacterStats** — Mòdul base amb les dades comunes a qualsevol entitat que combati (jugador o enemic).
- **Player** — Entitat controlada per l'usuari. Hereta de CharacterStats i afegeix Mana, potions i les accions disponibles.
- **Enemy** — Entitat NPC controlada per la IA. Hereta de CharacterStats i incorpora la lògica de decisió automàtica.
- **Boss** — Extensió d'Enemy amb dues fases de combat i comportament enrageat.
- **CombatManager** — Cervell del joc. Controla el flux de torns, calcula el dany, gestiona els estats i decideix quan una sala ha acabat.
- **GUIController** — Responsable de tota la interfície: barres de HP/Mana, log de combat i pantalles de victòria/derrota.

---

## 2. Entitats identificades

| Entitat | Tipus | Descripció |
|---|---|---|
| CharacterStats | ModuleScript (base) | Dades compartides per Player i Enemy |
| Player | ModuleScript | Personatge del jugador |
| Enemy | ModuleScript | Enemics de les sales 1–3 |
| Boss | ModuleScript | Enemic final amb 2 fases |
| CombatManager | Script (servidor) | Lògica central del combat |
| GUIController | LocalScript (client) | Interfície gràfica del combat |

---

## 3. Atributs clau de cada entitat

### CharacterStats
| Atribut | Tipus | Descripció |
|---|---|---|
| `name` | string | Nom del personatge o enemic |
| `hp` | number | Punts de vida actuals |
| `maxHp` | number | Vida màxima |
| `atk` | number | Atac base |
| `def` | number | Defensa base |

### Player (hereta CharacterStats)
| Atribut | Tipus | Descripció |
|---|---|---|
| `mana` | number | Mana actual per habilitats especials |
| `maxMana` | number | Mana màxim |
| `potions` | number | Nombre de pocions HP disponibles |

### Enemy (hereta CharacterStats)
| Atribut | Tipus | Descripció |
|---|---|---|
| `roomId` | number | Sala a la qual pertany (1, 2 o 3) |
| `dropItem` | boolean | Si deixa caure un ítem en morir |

### Boss (hereta Enemy)
| Atribut | Tipus | Descripció |
|---|---|---|
| `phase` | number | Fase actual (1 o 2) |
| `phase2Threshold` | number | Percentatge de HP que activa la fase 2 (0.5 = 50%) |

### CombatManager
| Atribut | Tipus | Descripció |
|---|---|---|
| `state` | string | Estat actual: IDLE / PLAYER_TURN / ENEMY_TURN / ROOM_CLEAR / BOSS_FIGHT / BOSS_PHASE_2 / VICTORY / GAME_OVER |
| `currentRoom` | number | Sala actual (1–4, sent 4 el Boss) |

### GUIController
| Atribut | Tipus | Descripció |
|---|---|---|
| `hpBar` | Frame | Barra de vida del jugador |
| `manaBar` | Frame | Barra de mana del jugador |
| `combatLog` | TextLabel | Log de combat (últimes accions) |

---

## 4. Accions, mètodes o funcions principals

### CharacterStats
_(Mòdul base, no té mètodes propis — les dades s'inicialitzen via constructor del mòdul.)_

### Player
| Mètode | Descripció |
|---|---|
| `attack(enemy)` | Atac bàsic. Calcula dany i l'envia al CombatManager. |
| `useSkill(enemy)` | Habilitat especial (gasta Mana). Dany augmentat. |
| `usePotion()` | Consumeix una poció i recupera HP. |
| `defend()` | Redueix el dany rebut al pròxim torn del enemic. |

### Enemy
| Mètode | Descripció |
|---|---|
| `chooseAction(player)` | IA senzilla: tria atacar o usar habilitat especial aleatòriament. |
| `takeDamage(amount)` | Redueix HP. Comprova si ha mort. |
| `isDead()` | Retorna true si hp ≤ 0. |

### Boss (+ herència d'Enemy)
| Mètode | Descripció |
|---|---|
| `checkPhase()` | Comprova si hp ≤ phase2Threshold × maxHp i activa la fase 2. |
| `specialAttack(player)` | Atac especial exclusiu del Boss (fase 1). |
| `enrage()` | Augmenta ATK al passar a fase 2. |

### CombatManager
| Mètode | Descripció |
|---|---|
| `startCombat(player, enemy)` | Inicialitza el combat i posa l'estat a PLAYER_TURN. |
| `processTurn(action)` | Processa l'acció del jugador, executa la resposta del enemic, actualitza estat. |
| `calcDamage(attacker, defender)` | Fórmula: `max(1, atk - def)`. Aplica crític (15% chance ×1.5). |
| `endCombat(result)` | Transiciona a ROOM_CLEAR, VICTORY o GAME_OVER. |
| `nextRoom()` | Carrega la sala següent o el Boss. |

### GUIController
| Mètode | Descripció |
|---|---|
| `updateHP(current, max)` | Actualitza la mida de la barra de HP. |
| `updateMana(current, max)` | Actualitza la barra de Mana. |
| `showMessage(text)` | Afegeix una línia al log de combat. |
| `showScreen(type)` | Mostra pantalla de victòria o game over. |

---

## 5. Explicació del diagrama de classes

El diagrama de classes (vegeu `diagrames/diagrama_classes.png`) representa l'arquitectura estàtica del sistema.

**Per què està organitzat així:**

- `CharacterStats` és el mòdul base del qual hereten `Player` i `Enemy`. Això evita duplicació de codi (hp, atk, def apareixen una sola vegada) i reflectirà una herència real de ModuleScript a Lua, o bé un patró de composició si Lua no admet herència directament.
- `Boss` hereta d'`Enemy` perquè comparteix tota la lògica de combat bàsica, i només afegeix el comportament de les dues fases.
- `CombatManager` **usa** Player i Enemy (associació), perquè és el coordinador central que rep les dues entitats i gestiona la partida. No crea ni posseeix Player o Enemy — els rep des del joc.
- `CombatManager` **notifica** GUIController (associació unidireccional), perquè és ell qui sap quan ha canviat un valor i ha d'actualitzar la interfície.
- `GUIController` és completament passiu: no pren cap decisió de joc, només mostra informació.

**Relacions presents al diagrama:**
- Herència (fletxa discontínua): `Player → CharacterStats`, `Enemy → CharacterStats`, `Boss → Enemy`
- Associació / ús (fletxa sòlida): `CombatManager → Player`, `CombatManager → Enemy`, `CombatManager → GUIController`

---

## 6. Explicació del diagrama de comportament

El diagrama de comportament escollit és un **diagrama d'estats** (vegeu `diagrames/diagrama_comportament.png`). Representa l'evolució de l'estat intern de `CombatManager` al llarg d'una partida completa.

**Per què un diagrama d'estats:**
El repte tècnic central del projecte és gestionar correctament en quina fase del combat es troba el sistema en cada moment. Un diagrama d'estats captura això millor que un diagrama d'activitat o de seqüència, perquè posa el focus en la variable `state` del CombatManager i en les condicions que provoquen les transicions.

**Estats i transicions principals:**

| Estat | Descripció |
|---|---|
| `IDLE` | La sala és accessible però el combat no ha començat. El jugador entra a la sala i s'activa el combat. |
| `PLAYER_TURN` | El jugador pot triar una acció (atacar, habilitat, poció, defendre's). |
| `ENEMY_TURN` | L'enemic executa la seva acció automàticament (IA). |
| `ROOM_CLEAR` | L'enemic ha mort. El jugador rep recompensa i avança. |
| `BOSS_FIGHT` | Combat contra el Boss (fase 1). |
| `BOSS_PHASE_2` | El Boss ha passat al 50% de vida — s'activa la fase 2 (atacs més forts). |
| `VICTORY` | El Boss ha mort. Pantalla de victòria. |
| `GAME_OVER` | El jugador ha mort en qualsevol punt. Pantalla de derrota. |

**Com reflecteix el bucle de joc:**
El bucle central (`PLAYER_TURN ↔ ENEMY_TURN`) es repeteix fins que es compleix una condició de sortida: l'enemic mort (`ROOM_CLEAR`) o el jugador mort (`GAME_OVER`). El diagrama també mostra com `ROOM_CLEAR` torna a `IDLE` per a les sales 1–2, però transiciona a `BOSS_FIGHT` en arribar a la sala 3.

---

## 7. Correspondència entre diagrames i codi futur

| Diagrama | Element | Implementació a Lua |
|---|---|---|
| Classes | `CharacterStats` | `ModuleScript` amb taula de stats i funció constructora `new()` |
| Classes | `Player` / `Enemy` / `Boss` | `ModuleScript` per a cada un, que usa `CharacterStats` com a base |
| Classes | `CombatManager` | `Script` al servidor. Gestiona els `RemoteEvent` del client |
| Classes | `GUIController` | `LocalScript` al client. Escolta `RemoteEvent` i actualitza la GUI |
| Estats | Variable `state` | Variable local a `CombatManager`: `local state = "IDLE"` |
| Estats | Transicions | Funcions com `startCombat()`, `processTurn()`, `endCombat()` que modifiquen `state` |
| Estats | BOSS_PHASE_2 | Crida a `boss:checkPhase()` al final de cada torn del jugador |

---

## 8. Estructura inicial del repositori

```
aincrad-duel/
│
├── README.md
├── IA_log.md
│
├── docs/
│   ├── 01_idea_i_abast.md
│   ├── 02_model_del_joc.md
│   ├── 03_entorn_i_prototip.md       ← (Fase 3)
│   ├── 04_proves_i_depuracio.md      ← (Fase 4)
│   └── 05_millores_i_reflexio_final.md ← (Fase 5)
│
├── diagrames/
│   ├── diagrama_classes.png
│   └── diagrama_comportament.png
│
└── src/
    ├── CharacterStats.lua
    ├── Player.lua
    ├── Enemy.lua
    ├── Boss.lua
    ├── CombatManager.lua
    └── GUIController.lua
```

**Justificació de l'estructura:**
- `docs/` conté tota la documentació de fases, separada del codi.
- `diagrames/` conté les imatges UML referenciades des dels documents.
- `src/` conté els scripts Lua exportats o copiats des de Roblox Studio.
- `IA_log.md` a l'arrel, visible i accessible, per documentar l'ús de la IA.

---

## 9. Primer commit i README inicial

### Contingut del README.md inicial

```markdown
# Aincrad Duel

Microvideojoc de combat per torns desenvolupat a Roblox Studio (Lua)  
Inspirat en Sword Art Online — Projecte de l'assignatura Entorns de Desenvolupament (DAM1)

## Descripció
Un floor d'Aincrad amb 3 sales de combat i un Floor Boss final amb 2 fases.
El jugador gestiona HP, Mana i potions per sobreviure fins al Boss.

## Estructura del repositori
- `docs/` — Documentació de les 5 fases del projecte
- `diagrames/` — Diagrames UML de classes i comportament
- `src/` — Codi font Lua

## Tecnologies
- Roblox Studio + Lua
- GitHub (control de versions)

## Estat actual
Fase 2 completada — Model i diagrames definits.
```

### Primer commit
- **Missatge:** `init: estructura del repositori i documentació de Fase 1 i Fase 2`
- **Contingut:** README.md, `docs/01_idea_i_abast.md`, `docs/02_model_del_joc.md`, `diagrames/diagrama_classes.png`, `diagrames/diagrama_comportament.png`, estructura de carpetes `src/` i `docs/` buida.
- **Propòsit:** Deixar evidència d'inici real del projecte i estructura pensada des del principi, no afegida a última hora.