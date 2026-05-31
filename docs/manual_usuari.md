# Manual d'usuari — Aincrad Duel

## Descripció del joc

Aincrad Duel és un microvideojoc de combat per torns ambientat al món de *Sword Art Online*. El jugador avança per 3 sales de combat i s'enfronta a un Floor Boss final per completar el floor d'Aincrad.

El combat és per torns: primer actua el jugador, després l'enemic. L'objectiu és gestionar els recursos (HP, Mana i pocions) de manera estratègica per sobreviure fins al Boss final.

---

## Com accedir al joc

1. Obre **Roblox Studio** i carrega el projecte.
2. Prem el botó **Play** a la barra superior per iniciar la simulació.
3. La pantalla de combat apareixerà automàticament.
4. Prem el botó **INICIAR PARTIDA** per començar el combat.

---

## Interfície de combat

La pantalla de combat mostra els elements següents:

| Element | Descripció |
|---|---|
| **Barra HP (vermella)** | Vida actual del jugador. Comença a 100/100. Si arriba a 0, és Game Over. |
| **Barra Mana (blava)** | Mana disponible per a habilitats especials. Comença a 50/50. |
| **Pocions** | Nombre de pocions de HP restants. Comences amb 3. |
| **Barra HP enemic** | Vida de l'enemic actual amb el seu nom i sala. |
| **Log de combat** | Registre de les últimes accions del combat (dany fet/rebut, efectes especials). |
| **Sala actual** | Indica en quina sala et trobes (1-3 + Boss). |

---

## Accions disponibles

### ATACAR
Realitza un atac físic bàsic contra l'enemic.
- **Dany** = `max(1, ATK_jugador - DEF_enemic)`
- 15% de probabilitat de **cop crític** que fa ×1.5 de dany
- No consumeix Mana
- Sempre disponible

### HABILITAT ESPECIAL
Atac potent que consumeix 10 de Mana.
- **Dany** = `max(1, ATK_jugador × 1.5 - DEF_enemic)`
- Pot fer crític (dany addicional ×1.5)
- Requereix almenys **10 de Mana** — si no en tens prou, l'acció és cancel·lada

### POCIÓ
Consumeix una poció HP per recuperar vida.
- Recupera **30 HP** (fins al màxim de 100)
- Disposes de **3 pocions** per partida (no es recarreguen entre sales)
- Si no tens pocions, l'acció és cancel·lada

### DEFENSAR
Entra en posició defensiva.
- La teva defensa es **dobla** (`DEF × 2`) durant el pròxim atac de l'enemic
- L'efecte s'elimina automàticament al final del torn de l'enemic
- Útil quan l'enemic té molt d'ATK o quan el Boss entra a Fase 2

---

## Progressió de sales

Has de superar 3 sales d'enemics i el Boss final. Cada enemic és més difícil que l'anterior.

| Sala | Enemic | HP | ATK | DEF |
|---|---|---|---|---|
| Sala 1 | Goblin Scout | 30 | 8 | 2 |
| Sala 2 | Orc Warrior | 45 | 12 | 3 |
| Sala 3 | Stone Troll | 60 | 15 | 4 |
| Boss | Kobold King | 120 | 18 → 27 | 6 |

En derrotar cada enemic, recuperes **20 HP** i **10 de Mana** per preparar-te per a la sala següent.

---

## El Boss: Kobold King

El Kobold King és el repte final i té **dues fases**:

**Fase 1** (HP > 60):
- Comportament normal. ATK = 18.
- Combina atacs bàsics (70% probabilitat) i habilitats especials (30% probabilitat).

**Fase 2** (HP ≤ 60, el 50% del seu màxim):
- S'activa automàticament quan el Boss arriba al 50% de vida.
- La pantalla mostra un avís de canvi de fase.
- **ATK augmenta a 27** — els atacs fan molt més dany.
- Considera defensar-te un torn per aguantar mentre recuperes Mana per a la habilitat especial.

---

## Condicions de victòria i derrota

**Victòria:** Derrota el Kobold King amb HP > 0. Apareix la pantalla de victòria.

**Derrota:** El teu HP arriba a 0 en qualsevol moment. Apareix la pantalla de Game Over.

En ambdós casos pots reiniciar la partida des de zero.

---

## Consells estratègics

- **Guarda les pocions per al Boss.** Les sales 1-3 són manejables sense pocions si ataques amb cap. El Boss Fase 2 és on et caldrà recuperar HP.
- **Usa la habilitat especial a les sales 2 i 3.** El mana es recupera parcialment entre sales, compensa gastar-lo en enemics resistents.
- **Defensa contra el Boss Fase 2.** Quan el Boss entra a Fase 2 (ATK 27), una ronda de defensa pot salvar-te si tens poc HP.
- **El crític és aleatori.** No comptes amb ell, però si apareix pot canviar el resultat d'una batalla ajustada.
- **La habilitat especial del boss és perillosa.** Té un 30% de probabilitat d'usar-la cada torn — fa dany molt superior al bàsic.
