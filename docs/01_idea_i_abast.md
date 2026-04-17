# 01 — Idea i Abast del Projecte

---

## 1. Títol del joc

**Aincrad Duel** — *A Floor Boss Combat Experience*

---

## 2. Tipus de microvideojoc escollit

**Joc de combat per torns** amb elements de RPG, inspirat en la sèrie *Sword Art Online (SAO)*.  
Implementat a **Roblox Studio** amb scripts en **Lua**, incloent una interfície gràfica (GUI) per gestionar els combats i un mapa estructurat en sales (floors).

---

## 3. Objectiu del joc

L'objectiu del joc és avançar per una sèrie de sales de combat inspirades en el castell d'Aincrad de SAO, derrotar els enemics de cada sala i finalment enfrontar-se al **Floor Boss** per completar el floor i guanyar la partida.

El jugador ha de gestionar els seus recursos (HP, mana) de manera estratègica per sobreviure fins al final.

---

## 4. Rol del jugador

El jugador controla un **personatge guerrer** dins d'Aincrad amb les accions següents disponibles en combat:

| Acció | Descripció |
|---|---|
| **Atacar** | Atac físic bàsic. Fa dany basat en l'stat ATK del jugador. |
| **Habilitat especial** | Atac potent que consumeix Mana (ex: *Horizontal*, *Sonic Leap*). |
| **Usar ítem** | Consumir una poció de HP o Mana de l'inventari. |
| **Defendre** | Redueix el dany rebut al torn següent. |

Fora del combat, el jugador es mou lliurement pel mapa i entra a les sales per iniciar el combat.

---

## 5. Regles bàsiques

- El combat és **per torns estrictes**: primer actua el jugador, després l'enemic.
- Cada acció del jugador consumeix el seu torn.
- El dany es calcula amb una fórmula simple: `Dany = ATK - DEF_enemic` (mínim 1).
- Les habilitats especials fan dany extra però gasten Mana.
- Les pocions es poden usar com a acció de torn (no és gratuïta).
- Si el HP del jugador arriba a 0 → derrota immediata.
- Si el HP de l'enemic arriba a 0 → sala superada, el jugador avança.

---

## 6. Condicions de victòria i derrota

**Victòria:**
- Derrotar tots els enemics de les sales (3 sales) i superar el **Floor Boss** final.
- Apareix una pantalla de victòria amb el temps total i les estadístiques.

**Derrota:**
- El HP del jugador arriba a 0 en qualsevol moment.
- Apareix una pantalla de "Game Over" amb l'opció de tornar a intentar-ho.

---

## 7. Bucle principal del joc

```
[Inici] → Selecció de personatge/stats
    ↓
[Sala de combat] → Combat per torns vs enemic NPC
    ↓ (enemic derrotat)
[Recompensa] → HP recuperat parcialment / ítem opcional
    ↓
[Següent sala] → Repetir combat (x3 sales)
    ↓ (totes les sales superades)
[Sala del Boss] → Combat especial vs Floor Boss (2 fases)
    ↓
[Victòria / Derrota] → Pantalla final
```

El bucle central és: **entrar a la sala → combatre → sobreviure → avançar**.

---

## 8. Repte principal i dificultat

**Repte principal:** Gestionar els recursos (HP i Mana) de manera eficient per arribar al Boss amb prou vida i pocions.

**Dificultat prevista:**
- Sales 1-3: enemics progressivament més difícils (dany i HP creixents).
- Boss final: té **2 fases**. Quan arriba al 50% HP, canvia d'atac i fa més dany. Requereix que el jugador hagi gestionat bé els seus recursos.
- No hi ha sistema de nivells ni grind — l'estratègia en combat és el factor clau.

---

## 9. Limitacions explícites

Les funcionalitats següents **NO s'inclouran** en aquesta versió:

- ❌ Sistema de progressió de personatge (XP, level up).
- ❌ Múltiples floors o dungeons (només 1 floor complet).
- ❌ Equipament o sistema d'inventari complex.
- ❌ Guardar partides (save/load).
- ❌ Animacions de combat elaborades o sistemes de partícules avançats.
- ❌ Mode PvP multijugador (queda fora de l'abast de les 10h, tot i que l'arquitectura ho permetria en el futur).
- ❌ Música o efectes de so personalitzats.
- ❌ Narració o diàlegs entre personatges.

---

## 10. Riscos tècnics

### Risc 1 — Gestió d'estat del combat (CRÍTIC)
**Problema:** En un combat per torns, cal controlar en tot moment a qui li toca actuar, si el combat ha acabat, si el jugador o l'enemic estan morts, etc. Si no s'implementa correctament, poden aparèixer bugs com atacar quan el combat ja ha acabat o estats inconsistents.  
**Solució prevista:** Implementar una variable `combatState` (IDLE / PLAYER_TURN / ENEMY_TURN / ENDED) i validar-la abans de cada acció.

### Risc 2 — Comunicació Client-Server a Roblox (MODERAT)
**Problema:** Roblox separa el codi de client (LocalScript) del codi de servidor (Script). La GUI de combat corre al client, però la lògica de joc hauria de córrer al servidor per seguretat. Gestionar els `RemoteEvents` entre els dos pot complicar-se.  
**Solució prevista:** Mantenir la lògica de combat al servidor i usar `RemoteEvents` per comunicar les accions del jugador i els resultats. Documentar clarament quina part corre a cada costat.

### Risc 3 — Sincronització de la GUI amb l'estat del joc (MODERAT)
**Problema:** Les barres de HP i Mana s'han d'actualitzar en temps real cada cop que el valor canvia. Si no es gestiona bé, la GUI pot mostrar valors incorrectes o no actualitzar-se.  
**Solució prevista:** Crear una funció `updateGUI()` centralitzada que es cridi sempre que canviï un stat, en lloc d'actualitzar la GUI manualment des de cada funció.

---

## 11. Exploració amb IA

### Prompt 1 — Exploració de mecàniques de combat

**Prompt enviat a Claude:**
> "Estic fent un joc de combat per torns a Roblox Studio inspirat en Sword Art Online. El jugador pot atacar, usar habilitats especials amb mana, usar ítems o defendre's. L'enemic actua automàticament. Quines mecàniques addicionals senzilles podria afegir per fer el combat més interessant sense complicar massa la implementació?"

**Resum de la resposta:**
La IA va proposar diverses mecàniques: sistema de crítics (probabilitat d'impactar x2), estats alterats senzills (verí, atordiment per un torn), buff/debuff temporals (augmentar ATK o reduir DEF per X torns), i un sistema de "Sword Skill charge" (carregar una habilitat especial al llarg de X torns d'atac bàsic). 

**Decisió presa:** Incorporo el sistema de **crítics** (10-15% probabilitat, dany x1.5) i un **estat alterat senzill** (verí que fa dany passiu al final de cada torn del jugador). Descarto buff/debuff temporals i el charge system per no complicar la lògica en el temps disponible.

---

### Prompt 2 — Estructura de classes i arquitectura

**Prompt enviat a Claude:**
> "Per a un joc de combat per torns a Roblox en Lua, quins mòduls o ModuleScripts hauria de crear per estructurar bé el codi? Tinc un jugador, enemics normals, un boss amb 2 fases, i una GUI de combat."

**Resum de la resposta:**
La IA va suggerir una estructura modular: un `CombatManager` que controla el flux del combat (torns, fi de combat), un `CharacterStats` amb les dades de cada entitat (HP, ATK, DEF, Mana), un `EnemyAI` per la lògica de decisió dels enemics, un `GUIController` per actualitzar la interfície, i un `ItemManager` per les pocions. Va recomanar usar `ModuleScript` per tots excepte el `CombatManager` que hauria de ser un `Script` normal al servidor.

**Decisió presa:** Adopto aquesta estructura amb una simplificació: fusiono `ItemManager` dins del `CombatManager` per reduir la complexitat. La separació `CharacterStats` / `EnemyAI` / `GUIController` em sembla molt adequada i facilitarà el diagrama de classes de la Fase 2.

---

## 12. Proposta final escollida

**Aincrad Duel** — combat per torns a Roblox Studio, 1 floor complet amb 3 sales d'enemics NPC i un Floor Boss amb 2 fases. GUI amb barres de HP/Mana, sistema de crítics i estat de verí. Arquitectura modular en Lua (ModuleScripts).

---

## 13. Justificació de viabilitat

| Criteri | Avaluació |
|---|---|
| **Temps disponible** | 10 hores. El combat per torns és lògicament senzill i Roblox facilita la GUI. Viable. |
| **Complexitat tècnica** | Mitjana. Conec Roblox Studio i els scripts bàsics. El repte principal (Client-Server) és gestionable amb RemoteEvents. |
| **Recursos necessaris** | Roblox Studio (gratuït). Sense assets externs necessaris. |
| **Abast controlat** | Les limitacions explícites de la secció 9 garanteixen que el projecte no creixi fora de control. |
| **Documentació** | L'estructura modular facilita la creació dels diagrames UML de la Fase 2. |

**Conclusió:** El projecte és viable en 10 hores, té un bucle de joc clar, estats definits (HP, Mana, combatState, roomState) i genera evidències sòlides per a tots els RA del mòdul.

---

## 14. Mini pla de treball

| Fase | Contingut | Temps estimat |
|---|---|---|
| **Fase 1** | Idea, abast i documentació inicial | 1,5 h |
| **Fase 2** | Diagrames de classes i comportament, estructura repositori | 2 h |
| **Fase 3** | Configuració Roblox Studio + prototip mínim funcional | 2 h |
| **Fase 4** | Proves, detecció d'errors i depuració | 2 h |
| **Fase 5** | Refactorització, millores i documentació final | 2 h |
| **Total** | | **~9,5 h** |

---

## 15. Eines previstes i justificació

| Eina | Ús | Justificació |
|---|---|---|
| **Roblox Studio** | IDE principal + motor de joc | Entorn integrat gratuït per a jocs Roblox. Inclou editor de codi, debugger i testejador en temps real. Permet DAM1 amb scripts Lua. |
| **Lua (via Roblox)** | Llenguatge de programació | Llenguatge natiu de Roblox, suficientment expressiu per implementar OOP amb ModuleScripts. |
| **GitHub** | Control de versions i repositori | Permet historial de commits, documentació en Markdown i entrega estructurada del projecte. |
| **draw.io / Mermaid** | Diagrames UML | Eines gratuïtes per crear diagrames de classes i comportament per a la Fase 2. |
| **Claude (IA)** | Suport al desenvolupament | Exploració de mecàniques, revisió de codi, generació d'alternatives. Documentat en `IA_log.md`. |
| **VS Code** (opcional) | Editor de Markdown | Per redactar la documentació del repositori amb comoditat. |