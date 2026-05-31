# IA Log — Aincrad Duel

Registre de tots els prompts enviats a eines d'IA durant el desenvolupament del projecte, amb el context, objectiu i decisió presa.

---

## Taula de prompts

| # | Fase | Eina IA | Prompt (resum) | Objectiu | Resultat / Decisió |
|---|---|---|---|---|---|
| 1 | Fase 1 | Claude | "Estic fent un joc de combat per torns a Roblox inspirat en SAO. Quines mecàniques addicionals senzilles podria afegir per fer el combat més interessant sense complicar massa la implementació?" | Explorar mecàniques de combat viables | S'adopta sistema de crítics (15% probabilitat, dany ×1.5). Es descarten verí i buff/debuff per complexitat afegida. |
| 2 | Fase 1 | Claude | "Per a un joc de combat per torns a Roblox en Lua, quins mòduls o ModuleScripts hauria de crear per estructurar bé el codi? Tinc jugador, enemics normals, boss amb 2 fases i GUI." | Definir arquitectura modular del projecte | S'adopta l'estructura CharacterStats / PlayerStats / Enemy / Boss / CombatManager / GUIController. S'elimina ItemManager per fusionar-lo amb CombatManager. |
| 3 | Fase 3 | Claude | "Com configuro Rojo per sincronitzar Roblox Studio amb VS Code? Necessito que els meus scripts Lua quedin sincronitzats." | Configurar entorn de desenvolupament | Es crea `default.project.json` amb el mapatge complet: ServerScriptService, StarterGui, ReplicatedStorage, ServerStorage amb models `.rbxm`. |
| 4 | Fase 3 | Claude | "Tinc objectes duplicats a Roblox Studio després de sincronitzar amb Rojo (ServerScriptService i ReplicatedStorage amb contingut doble). Com ho soluciono?" | Depurar problema de sincronització Rojo | S'identifica que els objectes originals de Studio no s'eliminen en connectar Rojo — cal eliminar-los manualment. S'explica el mètode per identificar quins són els Rojo-managed. |
| 5 | Fase 3 | Claude | "He esborrat el Script de servidor de Roblox Studio i Rojo no l'ha restaurat. Com el recupero?" | Recuperar script eliminat accidentalment | Es descobreix que Rojo necessita un canvi de fitxer per disparar la sincronització. Solució: desconnectar i reconnectar el plugin de Studio, o fer un canvi menor al fitxer corresponent. |
| 6 | Fase 4 | Claude | "Revisa la funció enemyTurn() del CombatManager. L'estat isDefending s'hauria de resetar al final del torn enemic, oi?" | Detectar bug de defensa permanent | Es confirma el bug: `isDefending` no es resetejava. S'afegeix `playerObj.isDefending = false` a `enemyTurn()` just després d'aplicar el dany. |
| 7 | Fase 4 | Claude | "La funció attack() de Enemy hauria de comprovar isDefending del jugador per doblar la defensa, però no ho fa. Com ho corrijo?" | Corregir fórmula de dany amb defensa activa | S'actualitzen `Enemy:attack` i `Enemy:specialAttack` per usar l'expressió ternària `player.isDefending and player.def * 2 or player.def`. |
| 8 | Fase 5 | Claude | "Com puc separar la comunicació de UI de les accions de combat en Roblox? Ara ho faig tot per un sol RemoteEvent." | Millorar arquitectura de comunicació | S'afegeix `UIUpdate` com a segon RemoteEvent dedicat exclusivament a notificacions servidor→client. `CombatAction` queda per accions client→servidor. |

---

## Observacions generals sobre l'ús d'IA

**Utilitat principal:**
- Explorar opcions de disseny ràpidament sense buscar documentació extensa (Fases 1-2).
- Depurar bugs de lògica quan el símptoma és clar però la causa no (Fase 4).
- Configurar eines noves com Rojo que no s'havien usat mai (Fase 3).

**Limitacions observades:**
- La IA no coneix l'estat exacte del projecte ni els noms de variables concrets fins que se li proporciona el codi. Les primeres propostes van generar noms incorrectes (`playerStats` en lloc de `playerObj`, `gameState` en lloc de `combatState`) que s'han hagut de corregir.
- No substitueix la comprensió pròpia del codi. Cada resposta s'ha validat contra el codi real abans d'aplicar-la.
- Per a problemes molt específics de Roblox (sincronització Rojo, comportament de RemoteEvents), sovint cal experimentar manualment i usar la IA per entendre el "per què" del problema, no per obtenir la solució directament.

**Percentatge d'ús estimat:** Aproximadament el 30% del temps de desenvolupament ha implicat consultes a IA, principalment en les fases d'exploració inicial i depuració. El codi final és producte de les decisions pròpies informades per les propostes de la IA.
