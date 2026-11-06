# Phase 3 : questions de game design (tranchées le 2026-11-06)

Choix d'Amine cochés `[x]`, précisions en **Décision**. Les options non retenues sont gardées pour mémoire.

**Vision** : survie + construction + exploration multivers. **Règle d'or** : chaque mécanique doit servir la boucle principale. On simplifie le développement, pas la vision.

**Boucle principale** : traverser des portails vers des mondes dangereux → y récolter des ressources propres à chaque monde → revenir construire sa base → la base permet d'ouvrir des mondes plus lointains.

---

## A. La boucle de jeu

### A1. Pourquoi le joueur traverse-t-il les portails ?
- [ ] **Exploration / collection** : chaque monde contient des ressources ou objets uniques ; on voyage pour les récolter. Simple, s'appuie directement sur les graines.
- [ ] **Quête principale** : un objectif global (ex. réparer le Nexus, retrouver quelque chose) qui demande de visiter des mondes précis.
- [x] **Les deux** : collection libre + un fil rouge léger qui donne une direction sans obliger.

> **Décision** : collection + fil rouge léger **porté par la construction** (ce qu'on peut bâtir ouvre des mondes plus lointains). Pas de quête écrite pour l'instant.

### A2. Les mondes sont-ils permanents ou jetables ?
- [ ] **Permanents** : un monde garde les modifications du joueur (ressources récoltées, constructions). Cohérent avec « monde persistant » de la roadmap, mais demande les sauvegardes (phase 4).
- [ ] **Jetables** : un monde se régénère à chaque visite. Beaucoup plus simple pour la phase 3.
- [x] **Jetables en phase 3, permanents en phase 4** : on code la phase 3 sans bloquer sur la sauvegarde, en gardant `known_worlds` comme point d'accroche.

### A3. Comment le joueur choisit-il sa destination ?
- [ ] **Au hasard** : chaque portail mène à une nouvelle graine (comme maintenant).
- [x] **Coordonnées / clés** : le joueur fabrique ou trouve des « clés de portail » qui ouvrent une graine précise (relie le craft aux portails).
- [ ] **Hub** : un monde-carrefour avec plusieurs portails (prévu quand il y aura au moins 3 mondes).

> **Décision** : système **hybride à clés de portail**.
> - **La clé = la graine** : une même recette de ressources donne toujours le même monde (partie fixe).
> - **Les ressources rares** mènent à des mondes inconnus et plus dangereux (partie mystère).
> - **La couleur/famille des ressources** oriente la famille du monde visé.
> - **Vraie logique de découverte** : avant d'utiliser une clé, le joueur voit un **aperçu** (couleur du monde, niveau de danger). Pas de clés fabriquées au hasard sans comprendre.
> - **V1** : un seul portail (dans la base) + des clés. Portails anciens et technologies : plus tard.

---

## B. Craft

### B1. D'où viennent les ressources ?
- [ ] **Ramassées au sol** : objets éparpillés (cristaux, rochers…), on marche dessus ou on appuie sur E.
- [x] **Récoltées avec un outil** : on frappe un rocher/cristal plusieurs fois ; plus engageant, réutilise les rochers/cristaux du décor.
- [ ] **Lâchées par les ennemis** : pousse au combat.

### B2. Les ressources dépendent-elles du monde ?
- [ ] **Oui, selon la palette/le schéma du monde** (ex. cristaux rouges seulement dans les mondes rouges) : donne une vraie raison de voyager.
- [ ] **Non, les mêmes partout** : plus simple à équilibrer.
- [x] **Mélange** : ressources de base partout + une ressource rare propre à chaque monde.

> **Décision** : ressources de base partout + **une ressource rare par famille de monde**.

### B3. Comment le joueur découvre-t-il les recettes ?
- [ ] **Toutes connues dès le départ** (liste dans un menu).
- [x] **Débloquées en ramassant un nouvel ingrédient** (« vous avez trouvé X : 2 nouvelles recettes »).
- [ ] **Expérimentation libre** : on combine des objets pour découvrir (fun mais frustrant, beaucoup de contenu à écrire).

### B4. Où crafte-t-on ?
- [ ] **Partout, depuis l'inventaire.**
- [ ] **Sur un établi** qu'on fabrique et pose dans le monde.
- [x] **Les deux** : objets simples partout, objets avancés sur établi.

### B5. Que fabrique-t-on en priorité ? (choisir 2-3 pour la première version)
- [x] Outils (pioche, hache…)
- [ ] Armes / armure
- [ ] Consommables (soins, vitesse…)
- [x] Clés de portail (voir A3)
- [x] Constructions (murs, lumières…)

> **Décision** : V1 = outils, clés de portail, constructions de base.

---

## C. Inventaire

### C1. Quelle forme ?
- [x] **Grille de cases avec piles** (ex. 24 cases, 99 par pile) : classique, facile à comprendre.
- [ ] **Poids maximum** : plus réaliste, oblige à choisir, plus dur à afficher clairement.
- [ ] **Illimité** : aucune gestion, mais aucun choix non plus.

### C2. Barre d'accès rapide ?
- [x] **Oui, 6 à 9 cases** sélectionnées avec les touches 1-9 / molette.
- [ ] **Non**, tout passe par le menu d'inventaire.

> **Décision** : barre rapide de 9 cases (touches 1-9).

### C3. Que se passe-t-il à la mort ?
- [ ] **On garde tout** (jeu détendu).
- [x] **On perd une partie** (ex. ressources mais pas les outils), récupérable là où on est mort.
- [ ] **On perd tout** (jeu exigeant).

> **Décision** : les **ressources transportées** sont perdues dans un **sac** posé sur le lieu du décès, récupérable. Coffres et constructions conservés.

### C4. Stockage
- [ ] **Uniquement sur soi.**
- [x] **Coffres** qu'on fabrique et pose (lié à la persistance des mondes, A2).
- [ ] **Un coffre « Nexus » partagé**, accessible depuis n'importe quel portail.

---

## D. Ennemis

### D1. Quel style de combat ?
- [x] **Corps à corps simple** (coup, esquive) : réutilise les anims Mixamo, facile à lire en 3e personne.
- [ ] **À distance** (tir) : demande une visée, un réticule, des projectiles.
- [ ] **Les deux.**

### D2. Que veut dire « IA adaptative » (promesse du jeu) ?
- [ ] **Les ennemis apprennent du joueur** : s'il esquive souvent à gauche, ils anticipent ; s'il fuit, ils deviennent plus prudents.
- [ ] **La difficulté s'ajuste** : plus fort si le joueur gagne facilement, plus faible s'il meurt souvent.
- [ ] **Les créatures s'adaptent à leur monde** : comportement et apparence générés depuis la graine (nocturnes, en meute, territoriales…).

> **Décision** : **plus tard** (pas en phase 3). La génération par famille de monde (D3) prépare le terrain.

### D3. Les ennemis sont-ils liés au monde ?
- [x] **Oui, générés depuis la graine** (couleur, taille, comportement), comme le terrain.
- [ ] **Un petit bestiaire fixe** (3-5 types) qu'on retrouve partout.

> **Décision** : chaque **famille de mondes** a ses créatures, leurs caractéristiques et leurs dangers.

### D4. Où sont les ennemis ?
- [ ] **Partout, en permanence.**
- [ ] **Certains mondes seulement** (mondes « dangereux » vs mondes « paisibles »), annoncés par la couleur du portail.
- [x] **Surtout la nuit** (si le cycle jour/nuit est gardé).

### D5. Les ennemis peuvent-ils traverser les portails ?
- [x] **Non**, ils restent dans leur monde (simple).
- [ ] **Oui**, s'ils poursuivent le joueur (spectaculaire, mais complexe).

---

## E. Questions transversales

### E1. Barres de vie / faim / énergie ?
- [ ] **Vie seulement.**
- [x] **Vie + endurance** (l'endurance limite la course et les coups).
- [ ] **Vie + faim + endurance** (survie complète).

### E2. Interface
- [ ] **Minimaliste** : rien à l'écran sauf quand c'est utile.
- [x] **Classique** : vie/endurance en bas, barre rapide, nom du monde à l'arrivée.

### E3. Ton général
- [ ] **Contemplatif** : exploration, beauté des mondes, peu de danger.
- [ ] **Survie** : ressources rares, ennemis dangereux.
- [ ] **Aventure** : entre les deux, danger modéré.

> **Décision** : **survie modérée** (entre « Survie » et « Aventure ») : mondes dangereux, surtout la nuit, mais mort peu punitive (sac récupérable, base conservée).

---

## F. PNJ (personnages non joueurs)

> **Décision** : **plus tard** (pas en phase 3). Les options ci-dessous restent ouvertes.

### F1. Les PNJ ont-ils leur place dans le jeu ?
- [ ] **Non** : le joueur est seul (ou avec d'autres joueurs en phase 5). Ambiance d'exploration solitaire, beaucoup moins de travail.
- [ ] **Oui, peu nombreux et marquants** : quelques personnages (ex. un gardien du Nexus) qui donnent le fil rouge (A1) et des quêtes.
- [ ] **Oui, des peuples entiers** : chaque monde peut avoir ses habitants générés depuis la graine. Très riche, très coûteux (modèles, IA, dialogues).

### F2. Où vivent-ils ?
- [ ] **Dans un hub** (le monde-carrefour de A3) : un lieu sûr où revenir.
- [ ] **Dans certains mondes**, en petits villages générés.
- [ ] **Partout**, en voyageurs croisés au hasard.

### F3. Que font-ils pour le joueur ?
- [ ] **Commerce** (échanger des ressources, acheter des recettes).
- [ ] **Quêtes** (aller chercher X dans un monde de telle couleur).
- [ ] **Compagnons** qui suivent et aident au combat.
- [ ] **Histoire / ambiance** seulement (dialogues, indices sur le Nexus).

### F4. Comment parle-t-on avec eux ?
- [ ] **Bulles de texte simples** (une phrase, pas de choix).
- [ ] **Dialogues à choix** (2-3 réponses).
- [ ] **Dialogues générés** par l'« IA adaptative » (ambitieux, coûteux, à garder pour plus tard).

### F5. Apparence
- [ ] **Personnages Mixamo** (comme Zlorp), recolorés : gratuit et cohérent.
- [ ] **Créatures générées** (formes simples + couleurs du monde), cohérent avec les mondes procéduraux.

---

## G. Véhicules (au sol)

> **Décision** : **plus tard** (pas en phase 3). Les options ci-dessous restent ouvertes.

### G1. Les véhicules ont-ils leur place ?
- [ ] **Non** : les mondes font 160 m de côté, on les traverse à pied en 30 s ; un véhicule n'apporte rien tant qu'ils restent petits.
- [ ] **Oui, plus tard, si les mondes grandissent** (terrains de plusieurs km ou monde infini par morceaux).
- [ ] **Oui, dès la phase 3**, comme objet de craft majeur (récompense).

### G2. Sous quelle forme ?
- [ ] **Monture** (créature qu'on apprivoise) : colle à l'univers multivers et à l'IA adaptative.
- [ ] **Engin sci-fi** (aéroglisseur, moto à lévitation) : colle à l'ambiance Nexus, facile à animer (pas de roues).
- [ ] **Véhicule à roues** : physique plus complexe (VehicleBody3D), peu adapté aux collines.

### G3. Peut-on emmener un véhicule à travers un portail ?
- [ ] **Non**, il reste dans son monde.
- [ ] **Oui**, il voyage avec le joueur.
- [ ] **Seuls certains portails (plus grands)** l'acceptent.

---

## H. Vaisseaux spatiaux

### H1. Les vaisseaux ont-ils leur place, alors que les portails font déjà voyager entre les mondes ?
- [ ] **Non** : les portails *sont* le moyen de voyager ; un vaisseau ferait doublon et coûterait énormément.
- [x] **Oui, comme objectif de fin de jeu** : construire un vaisseau pour atteindre des mondes sans portail (ou réparer le Nexus).
- [ ] **Oui, comme moyen de transport central** : changerait la nature du jeu (vol, espace, atterrissages).

> **Décision** : objectif de fin de jeu **à long terme**. Rien en phase 3 ; H2 et H3 restent ouvertes.

### H2. Si oui, que fait-on avec ?
- [ ] **Voyage seulement** (choisir une destination sur une carte des graines connues), avec une courte cinématique.
- [ ] **Vol libre au-dessus d'un monde** (survoler le terrain, atterrir où on veut).
- [ ] **Combats spatiaux** (très gros chantier, à éviter avec un budget zéro).

### H3. Comment l'obtient-on ?
- [ ] **En le fabriquant pièce par pièce** (pièces rares dans des mondes différents) : relie craft, exploration et portails.
- [ ] **En le trouvant** (épave à réparer dans un monde particulier).
- [ ] **Dès le départ** (le joueur arrive en vaisseau, crash au début du jeu = fil rouge).

### H4. Échelle de travail (à garder en tête)
Un vaisseau pilotable demande : un modèle 3D, une physique de vol, une caméra dédiée, des transitions sol/air. Pour un projet à 2 et budget zéro, la version « voyage seulement » (H2, option 1) est 10 fois moins coûteuse que le vol libre.
