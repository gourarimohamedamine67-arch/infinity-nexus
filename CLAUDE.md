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
2. Le Nexus : portails et téléportation (en cours)
3. Gameplay : craft, inventaire, ennemis
4. Vie du monde : événements, persistance, sauvegardes
5. Multijoueur
6. Polish

## État actuel (phase 1 terminée)
- game.tscn (scène principale) : Player persistant + mondes chargés dans $World + fondu au noir
- player.tscn : joueur CharacterBody3D (gravité, saut Espace, déplacement ZQSD ou flèches)
- Caméra orbitale SpringArm3D, souris capturée, Échap pour libérer, clic pour reprendre
- Terrain procédural SurfaceTool + FastNoiseLite (graine), dégradé de couleur selon la hauteur, collision ConcavePolygonShape3D
- Ciel sci-fi WorldEnvironment + ProceduralSkyMaterial bleu/violet
- Perso Zlorp (Mixamo) sous Player : tourne vers la direction du mouvement, anims Idle/Walking/Jump avec fondu
- Portail Nexus : aller-retour entre le monde d'origine et des mondes procéduraux (graine), fondu au noir
- Filet de sécurité : si le joueur tombe à plus de 15 m sous le sol, il est reposé au point d'arrivée
- Prochaine étape : test de l'étape 5 de la phase 2, puis plan de la phase 3

## Phase 2 : plan validé (une étape = un commit, pause test dans Godot entre chaque)
1. ✅ Terrain paramétrable (FastNoiseLite, graine)
2. ✅ game.tscn racine : Player persistant + nœud World où on charge les mondes + écran de fondu
3. ✅ portal.tscn : anneau + shader tourbillon + particules + lumière
4. ✅ Téléportation : Area3D, fondu, génération du monde destination (autre graine/ciel), joueur posé au sol près du portail retour, délai anti-boucle
5. ✅ Ressource WorldData (graine, relief, couleurs, ciel, soleil) + MAJ CLAUDE.md
Choix : on entre en marchant dans le portail (pas de touche), destination procédurale, pas de hub tant qu'il n'y a pas 3 mondes

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
- `world.tscn` / `world.gd` : modèle de monde (pas de joueur dedans), configuré par `setup(world_data, return_seed)` AVANT add_child (applique terrain, ciel, soleil). Les valeurs de la .tscn ne servent que de défaut. L'Environment est dupliqué avant modification (sinon partagé entre instances). → DirectionalLight3D, Terrain (groupe "terrain"), WorldEnvironment, Portal (0, 0, -10)
- `world_data.gd` (class_name WorldData, Resource) : world_seed, display_name, terrain (amplitude, frequency, octaves, couleurs), ciel, soleil (couleur, énergie, angles). `WorldData.generate(seed)` = monde procédural déterministe
- `worlds/origin.tres` : le monde d'origine, réglable dans l'inspecteur
- `portal.tscn` / `portal.gd` : Portal → Ring (TorusMesh émissif), Swirl (QuadMesh + `portal_swirl.gdshader`), Particles, OmniLight3D, TriggerZone (Area3D → game.travel_through). `destination_seed` = monde visé. Origine = base au sol, centre de l'anneau à 1,6 m, face vers +Z. Se pose seul sur le terrain (`snap_to_ground`)
- `player.tscn` : Player → zlorp, capsule, SpringArm3D/Camera3D
- `player.gd` : déplacement (actions move_forward/back/left/right, jump), saut, caméra souris, animations Zlorp
- Touches en physical_keycode : ZQSD sur AZERTY, WASD sur QWERTY, + flèches
- `terrain.gd` (@tool) : exports world_seed, size, resolution, amplitude, frequency, octaves, color_low/high ; `get_height(x, z)` = hauteur locale, `get_global_height(x, z)` = y global du sol. Le mesh n'est pas sauvegardé dans la .tscn (vidé avant chaque sauvegarde)
- `zlorp.tscn` : instance de `assets/characters/Idle.fbx` (racine nommée "Idle", renommée "zlorp" dans player.tscn)
- `assets/characters/` : Idle.fbx (modèle + skin), Walking/Running/Jumping/Running Jump.fbx (animations)
- Git LFS suit *.fbx et *.png (.gitattributes). GitHub refuse les fichiers > 100 Mo hors LFS
- Si des .fbx/.png font ~130 octets, ce sont des pointeurs LFS : lancer `git lfs checkout` (sinon Godot écrit valid=false dans les .import)
- Godot 4.6.2 : C:/Users/goura/Downloads/Godot_v4.6.2-stable_win64.exe/ (dossier ; le _console.exe sert pour --headless)
- Nouveau `class_name` : en headless, lancer d'abord `--headless --import` pour l'enregistrer dans le cache des classes, sinon « Could not find type »
- Ne jamais tuer Godot par nom de processus (`taskkill /IM`) : ça fermerait aussi l'éditeur d'Amine. Toujours mettre un `timeout` aux tests headless
- Avertissements GDScript : interroger le LSP de l'éditeur ouvert (port 6005, textDocument/didOpen → publishDiagnostics)
