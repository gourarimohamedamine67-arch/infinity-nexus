# Infinity Nexus
Jeu open-world multivers en Godot 4.6 (GDScript) : portails procéduraux, IA adaptative, monde persistant, impact global des joueurs. Fait par Amine + un partenaire, budget zéro.
Repo GitHub : gourarimohamedamine67-arch/infinity-nexus

## Façon de travailler
- Toujours répondre en français.
- Donner les instructions en blocs d'étapes, je signale seulement les blocages.
- Faire un commit git avant chaque gros changement.
- Après une modif, me dire quoi tester dans Godot.

## Roadmap
1. Fondations (en cours)
2. Le Nexus : portails et téléportation
3. Gameplay : craft, inventaire, ennemis
4. Vie du monde : événements, persistance, sauvegardes
5. Multijoueur
6. Polish

## État actuel (phase 1)
- world.tscn : joueur CharacterBody3D (gravité, saut Espace, déplacement ZQSD ou flèches)
- Caméra orbitale SpringArm3D, souris capturée, Échap pour libérer, clic pour reprendre
- Terrain procédural SurfaceTool (sin/cos), collision ConcavePolygonShape3D
- Ciel sci-fi WorldEnvironment + ProceduralSkyMaterial bleu/violet
- Perso Zlorp (Mixamo) sous Player : tourne vers la direction du mouvement, anims Idle/Walking avec fondu
- Prochaine étape : le premier portail Nexus (phase 2)

## Pièges Mixamo connus
- Échelle : l'importeur FBX de Godot 4.6 convertit déjà les cm en mètres (Zlorp = 1,77 m en scale 1). Ne PAS mettre 0.01
- Noms d'anims à l'import : "Take 001" et/ou "mixamo_com" (Walking.fbx n'a que "mixamo_com")
- Les anims s'importent sans boucle : player.gd les copie dans la librairie "zlorp" (zlorp/idle, zlorp/walk) en LOOP_LINEAR
- Les anims de marche Mixamo avancent les hanches (root motion) : player.gd bloque X/Z de mixamorig1_Hips (sinon télécharger en « In Place »)
- Les modèles Mixamo regardent vers +Z (Godot vise -Z) : angle = atan2(dir.x, dir.z)
- Os nommés mixamorig1_* ; origine du Player aux pieds, capsule décalée de +1 m
- AnimationPlayer : $zlorp/AnimationPlayer (pas $zlorp/Idle/AnimationPlayer)
- Modèle de base « with skin », animations « without skin »

## Structure du projet
- `project.godot` : scène principale = world.tscn, physique Jolt, rendu Forward+ (D3D12)
- `world.tscn` : World → DirectionalLight3D, Player (script player.gd), Terrain (script terrain.gd), WorldEnvironment
- `player.gd` : déplacement (actions move_forward/back/left/right, jump), saut, caméra souris, animations Zlorp
- Touches en physical_keycode : ZQSD sur AZERTY, WASD sur QWERTY, + flèches
- `terrain.gd` : grille 100×100 m, 50×50 cases, hauteur `sin(x*0.1)*3 + cos(z*0.1)*3`
- `zlorp.tscn` : instance de `assets/characters/Idle.fbx` (racine nommée "Idle", renommée "zlorp" dans world.tscn)
- `assets/characters/` : Idle.fbx (modèle + skin), Walking/Running/Jumping/Running Jump.fbx (animations)
- Git LFS suit *.fbx et *.png (.gitattributes). GitHub refuse les fichiers > 100 Mo hors LFS
- Si des .fbx/.png font ~130 octets, ce sont des pointeurs LFS : lancer `git lfs checkout` (sinon Godot écrit valid=false dans les .import)
- Godot 4.6.2 : C:/Users/goura/Downloads/Godot_v4.6.2-stable_win64.exe/ (dossier ; le _console.exe sert pour --headless)
