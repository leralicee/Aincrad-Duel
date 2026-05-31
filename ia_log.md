# Registre d'ús de la IA — Aincrad Duel

## Normes personals d'ús

He utilitzat eines d'IA principalment per a tres finalitats: explorar alternatives de disseny abans de programar, desbloquejar errors de lògica o configuració quan coneixia el símptoma però no la causa, i revisar decisions arquitecturals. En tots els casos he validat les respostes contra el codi real i he pres les decisions finals de manera autònoma. He evitat copiar codi directament sense entendre'l.

---

## Taula de prompts

| Núm. | Data | Eina | Prompt utilitzat | Resposta resumida | Què he aprofitat | Què he descartat | Justificació |
|---|---|---|---|---|---|---|---|
| 1 | 16/04/2026 | Claude | "Estic fent un joc de combat per torns a Roblox inspirat en SAO. Quines mecàniques addicionals senzilles podria afegir per fer el combat més interessant sense complicar massa la implementació?" | Va proposar: sistema de crítics, efectes de verí/buff, sistema de nivells i multi-enemic. | Sistema de crítics (15% probabilitat, dany ×1.5) perquè era senzill i afegia variança al combat. | Verí, buffs i multi-enemic | Massa complexos per implementar correctament dins del temps disponible. |
| 2 | 16/04/2026 | Claude | "Per a un joc de combat per torns a Roblox en Lua, quins mòduls o ModuleScripts hauria de crear per estructurar bé el codi? Tinc jugador, enemics normals, boss amb 2 fases i GUI." | Va proposar una arquitectura amb CharacterStats (base), PlayerStats, Enemy, Boss, CombatManager, GUIController i ItemManager. | Estructura CharacterStats / PlayerStats / Enemy / Boss / CombatManager i UIController. | ItemManager | Era innecessari: la gestió de pocions és prou simple per estar dins de PlayerStats. |
| 3 | 07/05/2026 | Claude | "Com configuro Rojo per sincronitzar Roblox Studio amb VS Code? Necessito que els meus scripts Lua quedin sincronitzats." | Va explicar l'estructura de `default.project.json`, els noms de fitxer per tipus de Script (`.server.luau`, `.client.luau`, `.luau`) i com definir RemoteEvents sense fitxer. | El mapatge complet de carpetes al `default.project.json` i la convenció de noms de fitxers Luau. | La proposta de sincronitzar Assets amb Rojo | Preferia gestionar els models `.rbxm` manualment per tenir més control. |
| 4 | 07/05/2026 | Claude | "Tinc objectes duplicats a Roblox Studio després de sincronitzar amb Rojo. Com ho soluciono?" | Va explicar que Rojo afegeix objectes nous però no elimina els originals de Studio, i que cal eliminar manualment els objectes no gestionats per Rojo. | El mètode d'identificació d'objectes Rojo-managed (icona de fitxer) i el procediment d'eliminació manual. | — | La solució era correcta i directa; no hi havia res a descartar. |
| 5 | 07/05/2026 | Claude | "He esborrat el Script de servidor de Roblox Studio i Rojo no l'ha restaurat. Com el recupero?" | Va explicar que Rojo necessita un canvi de fitxer per disparar la re-sincronització, i va proposar fer un canvi menor o desconnectar/reconnectar el plugin. | La solució de desconnectar i reconnectar el plugin de Rojo per forçar la sincronització. | La proposta de modificar el fitxer temporalment | La reconnexió era més neta i no deixava canvis innecessaris al codi. |
| 6 | 14/05/2026 | Claude | "Revisa la funció enemyTurn() del CombatManager. L'estat isDefending s'hauria de resetar al final del torn enemic, oi?" | Va confirmar el bug: `isDefending` no es resetejava mai, cosa que feia que la defensa fos permanent un cop activada. Va proposar afegir el reset just després d'aplicar el dany. | Afegir `playerObj.isDefending = false` a `enemyTurn()` just després d'aplicar el dany de l'enemic. | — | La diagnosi era correcta i la solució mínima; no calia canviar res més. |
| 7 | 14/05/2026 | Claude | "La funció attack() de Enemy hauria de comprovar isDefending del jugador per doblar la defensa, però no ho fa. Com ho corrijo?" | Va proposar substituir `player.def` per l'expressió `player.isDefending and player.def * 2 or player.def` a les funcions `attack` i `specialAttack`. | L'expressió ternària Lua per calcular la defensa efectiva depenent de l'estat `isDefending`. | — | Era exactament el que necessitava; la solució era concisa i correcta. |
| 8 | 21/05/2026 | Claude | "Com puc separar la comunicació de UI de les accions de combat en Roblox? Ara ho faig tot per un sol RemoteEvent." | Va recomanar tenir dos RemoteEvents: un de client→servidor per a accions (`CombatAction`) i un de servidor→client per a notificacions d'estat (`UIUpdate`). | La separació en `CombatAction` i `UIUpdate` com a dos canals de comunicació independents. | La proposta d'usar atributs de Instance per estat compartit | Els RemoteEvents ja cobrien bé les necessitats; afegir atributs hauria complicat el codi. |

---

## Exemple detallat d'una interacció important

### Prompt

```text
Revisa la funció enemyTurn() del CombatManager. L'estat isDefending s'hauria de resetar 
al final del torn enemic, oi? Aquí tens el codi actual: [codi enganxat]
```

### Resposta resumida de la IA

Va confirmar que el bug existia: si el jugador usava "Defensar" en un torn i l'enemic no atacava amb prou força per matar-lo, `isDefending` continuaria sent `true` al torn següent indefinidament. Va proposar afegir el reset en el lloc correcte del flux.

### Decisió presa

Es va afegir `playerObj.isDefending = false` dins de `enemyTurn()`, just després d'aplicar el dany de l'enemic i abans de comprovar si el jugador ha mort.

### Valoració crítica

La resposta era tècnicament correcta i ben ubicada al flux del codi. La IA va identificar el problema i va proposar la solució mínima sense suggerir canvis innecessaris. Útil per confirmar un diagnòstic que ja intuïa.

---

## Valoració general de l'ús d'IA

**Utilitat principal:**
- Explorar opcions de disseny ràpidament sense buscar documentació extensa (Fases 1–2).
- Depurar bugs de lògica quan el símptoma era clar però la causa no (Fase 4).
- Configurar eines noves com Rojo que no s'havien usat mai (Fase 3).

**Limitacions observades:**
- La IA no coneix l'estat exacte del projecte ni els noms de variables concrets fins que se li proporciona el codi. Les primeres propostes van generar noms incorrectes (`playerStats` en lloc de `playerObj`) que s'han hagut de corregir.
- No substitueix la comprensió pròpia del codi. Cada resposta s'ha validat contra el codi real.
- Per a problemes molt específics de Roblox (sincronització Rojo, RemoteEvents), sovint cal experimentar manualment.

**Percentatge estimat d'ús:** ~30% del temps de desenvolupament ha implicat consultes a IA, principalment en les fases d'exploració i depuració.
