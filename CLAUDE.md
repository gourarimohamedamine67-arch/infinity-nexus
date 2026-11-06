# Infinity Nexus
Jeu open-world multivers en Godot 4.6 (GDScript) : portails procéduraux, IA adaptative, monde persistant, impact global des joueurs. Fait par Amine + un partenaire, budget zéro.
Repo GitHub : gourarimohamedamine67-arch/infinity-nexus

## Façon de travailler
- Toujours répondre en français.
- Donner les instructions en blocs d'étapes, je signale seulement les blocages.
- Faire un commit git avant chaque gros changement.
- Après une modif, me dire quoi tester dans Godot.

## Roadmap
1. Fondations ✅ (terminée le 2026-11-05)
2. Le Nexus : portails et téléportation ✅ (validée le 2026-11-05, extras de la branche `nuit` fusionnés le 2026-11-06)
3. Gameplay : craft, inventaire, ennemis (en cours, plan validé le 2026-11-06)
4. Vie du monde : événements, persistance, sauvegardes
5. Multijoueur
6. Polish

## État actuel (phases 1 et 2 terminées)
- game.tscn (scène principale) : Player persistant + mondes chargés dans $World + fondu au noir
- player.tscn : joueur CharacterBody3D (gravité, saut Espace, déplacement ZQSD ou flèches, course Shift)
- Caméra orbitale SpringArm3D, souris capturée, Échap pour libérer, clic pour reprendre
- Terrain procédural SurfaceTool + FastNoiseLite (graine), dégradé de couleur selon la hauteur, collision ConcavePolygonShape3D
- Ciel : shader `sky.gdshader` (dégradé jour/nuit, soleil, étoiles, lune), cycle jour/nuit lent (6-10 min)
- Météo par monde (pluie, neige, brume ou rien) ; rochers et cristaux lumineux procéduraux avec collision
- Perso Zlorp (Mixamo) sous Player : tourne vers la direction du mouvement, anims Idle/Walking/Running/Jump avec fondu
- Portail Nexus : aller-retour entre le monde d'origine et des mondes procéduraux (graine), fondu au noir
- Bords : terrain de 160 m dont les 18 derniers mètres remontent en crêtes (+14 m) + murs invisibles ; filet de sécurité si chute de plus de 15 m
- Son de portail généré par le code (sfx.gd), aucun fichier audio
- Travail de nuit (branche `nuit`, validée et fusionnée dans main le 2026-11-06, puis supprimée) : course, bords, son, nettoyage, décor, PHASE3_QUESTIONS.md
- Phase 3 : blocs 1 et 2 faits (assets, familles/danger/ressources, inventaire, vie/endurance/HUD, récolte, craft) ; prochaine étape : bloc 3 (base persistante, construction, coffres)

## Phase 2 : plan validé (une étape = un commit, pause test dans Godot entre chaque)
1. ✅ Terrain paramétrable (FastNoiseLite, graine)
2. ✅ game.tscn racine : Player persistant + nœud World où on charge les mondes + écran de fondu
3. ✅ portal.tscn : anneau + shader tourbillon + particules + lumière
4. ✅ Téléportation : Area3D, fondu, génération du monde destination (autre graine/ciel), joueur posé au sol près du portail retour, délai anti-boucle
5. ✅ Ressource WorldData (graine, relief, couleurs, ciel, soleil) + MAJ CLAUDE.md
Choix : on entre en marchant dans le portail (pas de touche), destination procédurale, pas de hub tant qu'il n'y a pas 3 mondes

## Phase 3 : décisions de game design (détail dans PHASE3_QUESTIONS.md)
- **Vision** : survie + construction + exploration multivers. **Règle d'or** : chaque mécanique sert la boucle principale. On simplifie le développement, pas la vision.
- **Boucle** : portail → monde dangereux → récolter ses ressources propres → revenir construire la base → la base ouvre des mondes plus lointains.
- **A. Boucle** : collection + fil rouge léger porté par la construction (pas de quête écrite). Mondes jetables en phase 3, permanents en phase 4.
- **A3. Clés de portail** : clé = graine ; une même recette de ressources → toujours le même monde (partie fixe) ; ressources rares → mondes inconnus plus dangereux (mystère) ; la couleur/famille des ressources oriente la famille du monde ; **aperçu obligatoire** avant usage (couleur, danger). V1 : un seul portail (dans la base) + clés. Portails anciens/technologies : plus tard.
- **B. Craft** : récolte à l'outil (frapper rochers/cristaux du décor) ; ressources de base partout + 1 rare par famille de monde ; recettes débloquées en trouvant un nouvel ingrédient ; objets simples partout, avancés sur établi. V1 : outils, clés de portail, constructions de base.
- **C. Inventaire** : grille avec piles + barre rapide 1-9 ; à la mort, ressources transportées dans un sac récupérable sur place (coffres et constructions conservés) ; coffres à poser.
- **D. Ennemis** : corps à corps simple ; générés depuis la graine (créatures propres à chaque famille de mondes) ; surtout la nuit ; ne traversent pas les portails ; IA adaptative plus tard.
- **E. Général** : vie + endurance, interface classique, survie modérée.
- **Plus tard** : PNJ, véhicules. Vaisseau = objectif de fin de jeu à long terme.
- **Assets** : packs Kenney CC0 (Survival Kit, Impact Sounds) dans `assets/kenney/`, licence dans CREDITS.md (tout nouvel asset y est noté). Animations de Zlorp et **créatures = personnages Mixamo** (mutants, créatures) téléchargés par Amine, recolorés/redimensionnés selon la famille (Quaternius abandonné : style cartoon).
- **Choix confirmés** : la clé de portail est consommée à l'usage (la recette reste connue) ; la base = le monde d'origine (graine 0) ; touches E interagir, clic gauche frapper, B construction, Tab inventaire.
- **Clic gauche** : frappe seulement si la souris est capturée et aucun menu ouvert ; sinon il reprend la souris (après Échap) ou agit dans l'interface. Souris libre tant que l'inventaire est ouvert.

## Phase 3 : plan validé
Rythme : blocs 1-3 enchaînés (un commit par étape, pause test à la fin de chaque bloc) ; blocs 4-5 : pause après chaque étape.
- Bloc 1 : 0. assets + CREDITS.md · 1. familles de mondes (Braise, Sylve, Abysse, Givre, Arcane, Ombre) + danger 1-5 + ressources (Pierre, Quartz, Cristal de famille) en `ItemData` · 2. inventaire 24 cases (piles 99) + barre rapide 1-9 · 3. vie + endurance + HUD + bandeau d'arrivée
- Bloc 2 : 4. récolte (clic gauche, anim Mining, PV des rochers/cristaux, pioche requise pour les cristaux) · 5. craft (recettes `.tres` débloquées par nouvel ingrédient ; simples partout, avancées près d'un établi)
- Bloc 3 : 6. base persistante pendant la session (monde d'origine gardé en mémoire) · 7. construction (aperçu vert/rouge, R pour tourner, grille) · 8. coffres
- Bloc 4 : 9. clés de portail (graine = recette, famille = cristal dominant, danger = rareté) + socle avec aperçu · 10. Stabilisateur (débloque les dangers 3-5)
- Bloc 5 : 11. créatures Mixamo + combat · 12. apparition surtout la nuit selon le danger · 13. mort + sac récupérable · 14. boucle complète + équilibrage

## Pièges Mixamo connus
- Échelle : l'importeur FBX de Godot 4.6 convertit déjà les cm en mètres (Zlorp = 1,77 m en scale 1). Ne PAS mettre 0.01
- La bonne anim est toujours "mixamo_com". Dans Idle.fbx, "Take 001" = T-pose (1 clé égale à la pose de repos), à ne pas utiliser
- Vérifier une anim = vérifier la pose du squelette (ex. angle du bras vs pose de repos), pas seulement le nom de l'anim jouée
- Les anims s'importent sans boucle : player.gd les copie dans la librairie "zlorp" (zlorp/idle, zlorp/walk en LOOP_LINEAR, zlorp/jump sans boucle)
- Les anims Mixamo déplacent les hanches (root motion) : player.gd bloque X/Z de mixamorig1_Hips (sinon télécharger en « In Place »)
- Jumping.fbx dure 2,37 s (accroupi → saut → réception) contre ~0,9 s de saut physique : player.gd démarre l'anim au point le plus accroupi et cale son sommet sur celui du saut
- Les modèles Mixamo regardent vers +Z (Godot vise -Z) : angle = atan2(dir.x, dir.z)
- Os nommés mixamorig1_* ; origine du Player aux pieds, capsule décalée de +1 m
- AnimationPlayer : $zlorp/AnimationPlayer (pas $zlorp/Idle/AnimationPlayer)
- Modèle de base « with skin », animations « without skin »

## Structure du projet
- `project.godot` : scène principale = game.tscn, physique Jolt, rendu Forward+ (D3D12)
- `game.tscn` / `game.gd` : Game → World (conteneur du monde actuel), Player (player.tscn), Fade (CanvasLayer + ColorRect noir)
  - `get_world_data(seed)` : graine 0 = `worlds/origin.tres`, sinon `WorldData.generate(seed)` ; mis en cache dans `known_worlds`
  - `enter_world(seed, return_seed)` remplace le monde et pose le joueur devant le portail ; `travel_through(portal)` = fondu + changement de monde (délai anti-boucle 1 s) ; `get_ground_height(x, z)` ; `await fade_out()` / `await fade_in()`
  - Groupes : "game" (Game), "player" (Player), "terrain" (Terrain du monde actuel)
- `world.tscn` / `world.gd` : modèle de monde (pas de joueur dedans), configuré par `setup(world_data, return_seed)` AVANT add_child (applique terrain, ciel, soleil). `_ready` crée la lune, le décor et la météo ; `_process` fait avancer `time_of_day` (0-0,5 jour, 0,5-1 nuit), ciel mis à jour 4×/s (Sky en mode incrémental, radiance 128), ombres du soleil limitées à 80 m. Les valeurs de la .tscn ne servent que de défaut. L'Environment est dupliqué avant modification (sinon partagé entre instances). → DirectionalLight3D, Terrain (groupe "terrain"), WorldEnvironment, Portal (0, 0, -10)
- `world_data.gd` (class_name WorldData, Resource) : world_seed, display_name, terrain (amplitude, frequency, octaves, couleurs), ciel, brouillard, soleil, jour/nuit (day_length_s, start_time, star_density), météo (0 aucune, 1 pluie, 2 neige, 3 brume), décor (rock_count, crystal_count, couleurs). `WorldData.generate(seed)` = monde procédural déterministe : teinte de base = graine × nombre d'or (graines voisines bien différentes), sol saturé dans la teinte du ciel, sommets selon un schéma (Analogue, Décalé, Triadique, Complémentaire), luminosité nuit→jour, brouillard couleur horizon, soleil teinté comme le ciel
- `worlds/origin.tres` : le monde d'origine, réglable dans l'inspecteur
- `portal.tscn` / `portal.gd` : Portal → Ring (TorusMesh émissif), Swirl (QuadMesh + `portal_swirl.gdshader`), Particles, OmniLight3D, TriggerZone (Area3D → game.travel_through). `destination_seed` = monde visé. Origine = base au sol, centre de l'anneau à 1,6 m, face vers +Z. Se pose seul sur le terrain (`snap_to_ground`)
- `player.tscn` : Player → zlorp, capsule, SpringArm3D/Camera3D
- `player.gd` : déplacement (actions move_forward/back/left/right, sprint, jump), course 8 m/s (anim Running ×1,3), saut, caméra souris, animations Zlorp
- Touches en physical_keycode : ZQSD sur AZERTY, WASD sur QWERTY, + flèches ; Shift course, Espace saut, Tab inventaire, E interagir, clic gauche frapper, B construction, 1-9/molette barre rapide
- `sky.gdshader` : ciel jour/nuit (uniforms day_*/night_*, night, moon_dir, star_density) ; la lune (DirectionalLight3D) est en `SKY_MODE_LIGHT_ONLY` pour ne pas être dessinée comme un 2e soleil
- `weather.gd` : GPUParticles3D pluie/neige qui suit le joueur (local_coords = false), enum Kind
- `decor.gd` : `scatter(world, data, terrain)` → MultiMesh « Rocks » et « Crystals » + StaticBody3D « DecorBody » (cylindres, pas de collision mise à l'échelle). Max ~220 objets. Rien à moins de 7 m du segment (0,0)→(0,-10)
- `families.gd` : 6 familles (enum Family, NAMES, HUE_RANGES, CRYSTAL_COLORS), `from_hue()`, `random_hue()`, `crystal_item_id()`
- `item_data.gd` (class_name ItemData) + `items/*.tres` (un fichier par objet) + registre `items.gd` (`Items.get_item(&"pierre")`, `Items.all()`)
- `inventory.gd` (class_name Inventory) : 33 cases (0-8 barre rapide, 9-32 sac), piles 99 ; `add()` renvoie le surplus, `remove()` tout ou rien, `move()` fusionne/échange ; porté par le Player (`player.inventory`)
- `ui/hud.gd` (CanvasLayer, groupe "hud") : barre rapide, inventaire (Tab), barres Vie/Endurance, bandeau `show_arrival(data)` ; `is_menu_open()`, signal `menu_toggled` ; F1 = ressources de debug ; `ui/slot_ui.gd` = une case (glisser-déposer)
- Player : `health`/`stamina`, `take_damage()`, `heal()`, `spend_stamina()` (faux si pas assez), signaux `health_changed`, `stamina_changed`, `died` ; `controls_enabled` (faux si menu ouvert) ; actions de jeu en `_unhandled_input`
- Récolte : clic gauche = coup (anim Attack_Downward jouée de 0,15 à 1,4 s à ×1,4, impact à 0,54 s), Zlorp se tourne vers la caméra ; `player._find_decor_target()` (sphère devant Zlorp) → `world.hit_decor(col, dégâts, puissance)` ; règles dans `world.gd` HARVEST (pierre 6 PV main nue OK, quartz/cristaux 6/9 PV pioche requise) ; main nue 1 dégât, outil = puissance × 3
- `recipe_data.gd` (class_name RecipeData) + `recipes/*.tres` + registre `recipes.gd` (`known(discovered)`, `can_craft()`) ; recette connue quand tous ses ingrédients ont été trouvés (`player.discovered`) ; `player.craft(recipe)`
- `placeables.gd` : `create(item)` → StaticBody3D (modèle + boîte ajustée), groupes "placed" (+ "workbench" pour l'établi) ; `near_workbench()` (3,5 m). Clic avec un objet PLACEABLE sélectionné = le poser (version simple, l'étape 7 ajoute l'aperçu)
- `sounds.gd` : `Sounds.play_at(parent, pos, "impactMining")` (variante au hasard parmi 5)
- ItemData : `short_name` (abréviation sur l'icône), `model`, `model_scale` (outils ~3,5, établi/coffre ~3,2), `tool_power`
- `sfx.gd` : sons synthétisés (`portal_whoosh()` → AudioStreamWAV), chargé par `preload` (pas de class_name)
- `terrain.gd` (@tool) : exports world_seed, size (160), resolution (80), rim_width/rim_height (crêtes du bord), amplitude, frequency, octaves, color_low/high ; `get_height(x, z)` = hauteur locale, `get_global_height(x, z)` = y global du sol, `get_playable_half_size()` = zone sans les crêtes. Murs invisibles (`Bounds`) créés en jeu seulement. Le mesh n'est pas sauvegardé dans la .tscn (vidé avant chaque sauvegarde). Couleurs de sommets en sRGB (`vertex_color_is_srgb`, sinon délavées) et dégradé creux→sommets en teinte HSV (un mélange RGB de couleurs opposées passe par le gris)
- `zlorp.tscn` : instance de `assets/characters/Idle.fbx` (racine nommée "Idle", renommée "zlorp" dans player.tscn)
- `assets/characters/` : Idle.fbx (modèle + skin) ; animations Walking, Running, Jumping, Running Jump, Attack_Downward (pioche), Attack_Horizontal, Hit_Reaction, Dying, Dodge (recule de 2,2 m), Picking_Up (9,6 s : plusieurs gestes) — toutes vérifiées : 49 os identiques à Zlorp
- `assets/kenney/survival/` (GLB, très petits : mur 0,5 m → ×4 pour la construction, coffre/établi ×3) et `assets/kenney/sounds/` (.ogg). Les GLB pointent vers `Textures/colormap.png` à côté d'eux
- Git LFS suit *.fbx et *.png (.gitattributes). GitHub refuse les fichiers > 100 Mo hors LFS
- Si des .fbx/.png font ~130 octets, ce sont des pointeurs LFS : lancer `git lfs checkout` (sinon Godot écrit valid=false dans les .import)
- Godot 4.6.2 : C:/Users/goura/Downloads/Godot_v4.6.2-stable_win64.exe/ (dossier ; le _console.exe sert pour --headless)
- Nouveau `class_name` : en headless, lancer d'abord `--headless --import` pour l'enregistrer dans le cache des classes, sinon « Could not find type »
- Ne jamais tuer Godot par nom de processus (`taskkill /IM`) : ça fermerait aussi l'éditeur d'Amine. Toujours mettre un `timeout` aux tests headless
- Avertissements GDScript : interroger le LSP de l'éditeur ouvert (port 6005, textDocument/didOpen → publishDiagnostics)
- En headless, le rendu factice ne garde pas les transforms des MultiMesh (tout à l'origine) : tester le décor avec rendu (sans --headless)
- Tests d'interface/souris : lancer AVEC fenêtre (le headless ne gère pas la capture de la souris), injecter les événements avec `Input.parse_input_event`
- Mesurer le FPS avec `DisplayServer.window_set_vsync_mode(VSYNC_DISABLED)`, sinon plafonné/faussé. Référence 1280×720 GPU intégré AMD : ~70 FPS jour, ~90 FPS nuit
- Scripts utilitaires sans class_name (sfx, weather, decor) : chargés par `preload`, pas besoin de --import
