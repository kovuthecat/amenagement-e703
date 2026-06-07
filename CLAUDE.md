# CLAUDE.md

Instructions pour Claude Code dans ce dossier.

## Nature du projet

Projet d'**aménagement intérieur + mobilier sur mesure** (pas un projet de code). L'artefact
central est la maquette SketchUp `Plan 3D.skp`. Les scripts Python ne servent qu'à générer la
géométrie depuis le plan PDF.

## Avant toute tâche

- Lire `PROJECT_BRIEF.md`, `DECISIONS.md` et `CONTRAINTES.md`.
- Consulter `PROJECT_MAP.md` pour localiser fichiers et paramètres (échelle, hauteur, scripts).
- Vérifier `STATUS.md` / `TASKS.md` pour l'état courant.

## Règles métier

- **Échelle = 37,50 mm/pt**, maquette en **mm**. Ne pas changer sans recaler sur les cotes du plan.
- **Aucune cote de fabrication figée avant relevé sur site** (le plan de vente est indicatif).
- Murs régénérables via `extrude_murs_3d_E703.py` (hauteur = variable `H`).
- Mobilier : composants à l'épaisseur réelle des matériaux ; penser fabricabilité + manutention R+7.

## Après une intervention

Mettre à jour les fichiers de contexte concernés (`STATUS.md`, `TASKS.md`, `DECISIONS.md`,
`PROJECT_MAP.md`, `ROADMAP.md`). Pas de git ici (dossier sur SynologyDrive) sauf demande explicite.

## Si la demande devient stratégique (arbitrage d'aménagement, choix de parti)

Proposer 2-3 options max, recommander la plus simple, et laisser la décision à Thibault.
