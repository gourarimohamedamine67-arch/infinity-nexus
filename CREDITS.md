# Crédits

Liste de tous les assets externes utilisés dans Infinity Nexus, avec leur licence.
**Règle** : aucun asset n'entre dans le projet sans que sa licence soit vérifiée (page officielle + fichier de licence de l'archive) et notée ici.

## Modèles 3D

### Kenney : Survival Kit (2.0)
- **Auteur** : Kenney (www.kenney.nl)
- **Source** : https://kenney.nl/assets/survival-kit
- **Licence** : Creative Commons Zero (CC0 1.0), http://creativecommons.org/publicdomain/zero/1.0/
  - vérifiée le 2026-11-06 sur la page officielle et dans `License.txt` de l'archive (copié dans `assets/kenney/survival/License.txt`)
- **Utilisé** (`assets/kenney/survival/`, format GLB + `Textures/colormap.png`) :
  outils (`tool-pickaxe`, `tool-pickaxe-upgraded`, `tool-hammer`), `workbench`, `workbench-anvil`, `chest`,
  construction (`structure-metal-floor`, `structure-metal-wall`, `structure-metal-doorway`, `structure-metal-roof`, `metal-panel`, `fence-fortified`),
  `campfire-pit`, `resource-stone`, `resource-stone-large`, `bedroll-packed`

### Mixamo (Adobe) : personnage Zlorp et animations
- **Source** : https://www.mixamo.com
- **Licence** : conditions d'utilisation Mixamo/Adobe (usage libre, y compris commercial, dans un projet ; pas de redistribution des fichiers bruts comme assets)
- **Utilisé** (`assets/characters/`) : modèle de Zlorp (Idle.fbx, « with skin »), animations Walking, Running, Jumping, Running Jump (« without skin »)

## Sons

### Kenney : Impact Sounds (1.0)
- **Auteur** : Kenney (www.kenney.nl)
- **Source** : https://kenney.nl/assets/impact-sounds
- **Licence** : Creative Commons Zero (CC0 1.0), http://creativecommons.org/publicdomain/zero/1.0/
  - vérifiée le 2026-11-06 sur la page officielle et dans `License.txt` de l'archive (copié dans `assets/kenney/sounds/License.txt`)
- **Utilisé** (`assets/kenney/sounds/`, 45 fichiers .ogg) : `impactMining`, `impactGlass_light`, `impactGlass_medium`, `impactPunch_medium`, `impactPunch_heavy`, `impactPlank_medium`, `impactWood_light`, `impactMetal_light`, `impactSoft_medium` (5 variantes chacun)

### Sons générés par le code
- Son de portail : synthétisé dans `sfx.gd` (aucun fichier externe).

## Abandonné
- Quaternius « Ultimate Monsters » (CC0) : écarté le 2026-11-06, style cartoon incompatible avec Zlorp et l'ambiance sombre. Les créatures viendront de Mixamo.
