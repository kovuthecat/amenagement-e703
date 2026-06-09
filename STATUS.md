# STATUS.md

État du projet à un instant T. À mettre à jour en fin de session importante.

> **Dernière mise à jour :** 2026-06-09

## Phase actuelle

**Phase 1 — Coque 3D.** Construire une maquette SketchUp fidèle aux contraintes du logement
avant tout travail d'agencement.

## Ce qui est fait

- Plan de vente PDF analysé : c'est un **PDF vectoriel** (extraction propre possible).
- **Échelle calée à 37,50 mm/pt** (vérifiée sur cotes réelles du plan : 480, 400, 100/200/150 cm).
- Conversion PDF → DXF réalisée (échelle réelle, mm), en calques MURS / SURFACES / DETAILS.
- Murs **pré-extrudés en 3D** (hauteur 2500 mm), 1 composant SketchUp par mur, volumes fermés.
- Correctif appliqué : sous-contours traités séparément (fin des géométries tordues + gaine refermée).
- **Maquette importée dans SketchUp** : `Plan 3D.skp` (présent dans le dossier).

## Ce qui reste prototypal / à confirmer

- Hauteur sous plafond (2500 mm supposé).
- Quelques murs en L ont une triangulation de cap (diagonale à adoucir si gênant).
- Cotes globales = plan de vente, non vérifiées sur site.

## Ce qui n'est pas commencé

- Portes + fenêtres en vraies ouvertures dans la maquette.
- Contraintes techniques (eau, élec, gaine, radiateurs) → voir `CONTRAINTES.md`.
- Zoning / circulation.
- Conception mobilier.
- Saisie des données dans `index.html` (outil disponible, à remplir pièce par pièce).
- **Section « Tableau Pinterest »** (T1.1 + T1.2 + T1.3 — 2026-06-09) : accordéon par pièce, `pinit.js`, `renderPinBoard`, fallback lien, migration état.

## Prochaines étapes immédiates

1. Ajouter **portes + fenêtres** (ouvertures + sens) dans `Plan 3D.skp`.
2. Reporter les **contraintes techniques** connues dans la maquette (`CONTRAINTES.md`).
3. Choisir la **pièce pilote** pour le mobilier sur mesure.

## Notes / décisions en attente

- Date de remise des clés (déclenche les relevés sur site).
- Usage de la terrasse.
- Occupants / besoins (nb de couchages, bureau, etc.).
