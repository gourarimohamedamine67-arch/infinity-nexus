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
- world.tscn : joueur CharacterBody3D (gravité, saut Espace, déplacement ZQSD ou flèches)
- Caméra orbitale SpringArm3D, souris capturée, Échap pour libérer, clic pour reprendre
- Terrain procédural SurfaceTool + FastNoiseLite (graine), dégradé de couleur selon la hauteur, collision ConcavePolygonShape3D
- Ciel sci-fi WorldEnvironment + ProceduralSkyMaterial bleu/violet
- Perso Zlorp (Mixamo) sous Player : tourne vers la direction du mouvement, anims Idle/Walking/Jump avec fondu
- Prochaine étape : le premier portail Nexus (phase 2)

## Phase 2 : plan validé (une étape = un commit, pause test dans Godot entre chaque)
1. ✅ Terrain paramétrable (FastNoiseLite, graine)
2. game.tscn racine : Player persistant + nœud World où on charge les mondes + écran de fondu
3. portal.tscn : anneau + shader tourbillon + particules + lumière
4. Téléportation : Area3D, fondu, génération du monde destination (autre graine/ciel), joueur posé au sol près du portail retour, délai anti-boucle
5. Ressource WorldData (graine, couleurs) + MAJ CLAUDE.md
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
- `project.godot` : scène principale = world.tscn, physique Jolt, rendu Forward+ (D3D12)
- `world.tscn` : World → DirectionalLight3D, Player (script player.gd), Terrain (script terrain.gd), WorldEnvironment
- `player.gd` : déplacement (actions move_forward/back/left/right, jump), saut, caméra souris, animations Zlorp
- Touches en physical_keycode : ZQSD sur AZERTY, WASD sur QWERTY, + flèches
- `terrain.gd` (@tool) : exports world_seed, size, resolution, amplitude, frequency, octaves, color_low/high ; `get_height(x, z)` donne la hauteur du sol (coordonnées locales). Le mesh n'est pas sauvegardé dans la .tscn (vidé avant chaque sauvegarde)
- `zlorp.tscn` : instance de `assets/characters/Idle.fbx` (racine nommée "Idle", renommée "zlorp" dans world.tscn)
- `assets/characters/` : Idle.fbx (modèle + skin), Walking/Running/Jumping/Running Jump.fbx (animations)
- Git LFS suit *.fbx et *.png (.gitattributes). GitHub refuse les fichiers > 100 Mo hors LFS
- Si des .fbx/.png font ~130 octets, ce sont des pointeurs LFS : lancer `git lfs checkout` (sinon Godot écrit valid=false dans les .import)
- Godot 4.6.2 : C:/Users/goura/Downloads/Godot_v4.6.2-stable_win64.exe/ (dossier ; le _console.exe sert pour --headless)
