# 03 — Entorn i prototip funcional

## IDE utilitzat

**Roblox Studio** — Entorn integrat per desenvolupar jocs amb Luau (superset de Lua 5.1).

### Per què Roblox Studio?

| Motiu | Justificació |
|---|---|
| **Motor integrat** | Inclou editor de codi, depurador, simulador multijugador i visor 3D en un sol entorn. |
| **Luau natiu** | El llenguatge Luau és el natiu de Roblox i permet OOP via `setmetatable` — adequat per a la jerarquia de classes del projecte. |
| **GUI integrada** | Es pot crear la interfície de combat directament des del codi (LocalScript) sense llibreries externes. |
| **Arquitectura client-servidor** | Roblox separa automàticament el codi de servidor (Script) del client (LocalScript), alineant-se amb el patró MVC. |
| **Eines de depuració** | La consola d'Output mostra errors i `print()` en temps real durant la simulació. |

Alternativa descartada: VS Code pur amb un framework Lua independent. Descartada perquè requeriria configurar el motor gràfic i la gestió de xarxa des de zero, massa complex per a l'abast de 10h.

### Eines i extensions addicionals

| Eina | Ús |
|---|---|
| **Rojo 7** (CLI) | Sincronitza els fitxers del sistema de fitxers (VS Code) amb Roblox Studio en temps real. |
| **Plugin Rojo** (Studio) | Connector que rep la sincronització de Rojo dins de Roblox Studio. |
| **VS Code** | Editor extern per als fitxers `.luau` i `.md`. Permet extensions com Luau Language Server. |

## Com s'executa el projecte

```bash
# 1. Ves a la carpeta del projecte Rojo
cd Aincrad-Duel/joc

# 2. Inicia el servidor Rojo
rojo serve
# Ha de mostrar: "Listening on port 34872"
```

3. Obre **Roblox Studio** → crea un lloc nou buit (Baseplate).
4. Al plugin Rojo → prem **Connect** (es connecta a `localhost:34872`).
5. Els scripts i RemoteEvents apareixeran a l'Explorer de Studio automàticament.
6. Prem **Play ▶** a Studio per iniciar la simulació i provar el joc.

## Configuració bàsica

Estructura de scripts del projecte:

- ServerScriptService
  - CombatManager (Script)
    - CharacterStats (ModuleScript)
    - PlayerStats (ModuleScript)
    - Enemy (ModuleScript)
    - Boss (ModuleScript)

- ReplicatedStorage
  - CombatAction (RemoteEvent)

- StarterGui
  - BattleGUI (ScreenGui)
    - UIController (LocalScript)

## Decisions inicials d'implementació

1. **Arquitectura client-servidor**: Tota la lògica de combat s'executa al servidor (CombatManager). La interfície d'usuari s'executa al client (UIController). La comunicació es fa mitjançant RemoteEvents.

2. **Sistema de mòduls**: S'han creat 4 ModuleScripts dins del CombatManager per estructurar el codi:
   - `CharacterStats`: Classe base amb HP, ATK, DEF i mètodes comuns
   - `PlayerStats`: Hereta de CharacterStats, afegeix Mana i pocions
   - `Enemy`: Hereta de CharacterStats, inclou IA senzilla
   - `Boss`: Hereta de Enemy, afegeix sistema de 2 fases

3. **Interfície creada per codi**: Tots els elements de la GUI (botons, barres, text) es generen des del LocalScript per evitar errors de disseny manual.

4. **Màquina d'estats**: El combat es controla amb una variable `combatState` que pot ser IDLE, PLAYER_TURN, ENEMY_TURN, ROOM_CLEAR, GAME_OVER o VICTORY.

## Captures de pantalla

### Estructura dels scripts a l'Explorador de Roblox Studio

![Estructura scripts](../evidencies/captures/captura_estructura.png)

### Interfície de combat en execució

![Combat actiu](../evidencies/captures/captura_combat.png)

### Missatge de victòria

![Victòria contra enemic](../evidencies/captures/captura_victoria.png)

## Estat actual del prototip

| Funcionalitat | Estat |
|---|---|
| Combat per torns | ✅ Implementat |
| Botó ATACAR | ✅ Funcional |
| Botó HABILITAT ESPECIAL | ✅ Funcional (gasta Mana) |
| Botó POCIÓ | ✅ Funcional (recupera HP) |
| Botó DEFENSAR | ✅ Implementat (estructural) |
| Transició entre sales | ✅ Funcional |
| Enemic resposta automàtica | ✅ Funcional |
| Sistema de HP i Mana | ✅ Funcional |
| Victòria | ✅ Detecta quan enemic mor |
| Derrota | ✅ Detecta quan jugador mor |
| Boss amb 2 fases | ✅ Implementat (canvia ATK al 50% HP) |

## Problemes detectats (pendents per Fase 4)

- La defensa redueix dany però no està completament polida
- No hi ha sistema de crítics (es va descartar per simplificar)
- La interfície és funcional però poc estètica