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
- world.tscn : joueur CharacterBody3D (gravité, saut Espace, déplacement flèches)
- Caméra orbitale SpringArm3D, souris capturée, Échap pour libérer
- Terrain procédural SurfaceTool (sin/cos), collision ConcavePolygonShape3D
- Ciel sci-fi WorldEnvironment + ProceduralSkyMaterial bleu/violet
- Perso Zlorp (Mixamo) sous Player
- Prochaine étape : finir la rotation de Zlorp dans la direction du mouvement, puis le premier portail Nexus

## Pièges Mixamo connus
- Échelle FBX en cm : Zlorp en scale 0.01
- Les animations s'importent sous le nom "Take 001"
- AnimationPlayer : $zlorp/AnimationPlayer (pas $zlorp/Idle/AnimationPlayer)
- Modèle de base « with skin », animations « without skin »

## Structure du projet
- `project.godot` : scène principale = world.tscn, physique Jolt, rendu Forward+ (D3D12)
- `world.tscn` : World → DirectionalLight3D, Player (script player.gd), Terrain (script terrain.gd), WorldEnvironment
- `player.gd` : déplacement (actions `ui_*`), saut, caméra souris, animation Zlorp
- `terrain.gd` : grille 100×100 m, 50×50 cases, hauteur `sin(x*0.1)*3 + cos(z*0.1)*3`
- `zlorp.tscn` : instance de `assets/characters/Idle.fbx` (racine nommée "Idle", renommée "zlorp" dans world.tscn)
- `assets/characters/` : Idle.fbx (modèle + skin), Walking/Running/Jumping/Running Jump.fbx (animations)
- GitHub refuse les fichiers > 100 Mo : les gros assets doivent passer par Git LFS
