# DECISIONS.md

Journal des décisions du projet.

## Format

```md
## YYYY-MM-DD — Titre
### Décision
### Contexte
### Alternatives
### Raison
### Conséquences
```

---

## Décisions

## 2026-06-05 — Échelle de la maquette : 37,50 mm/pt PDF

### Décision
Caler toute la géométrie sur **37,50 mm par point PDF** (1 pt = 3,75 cm).

### Contexte
Le plan de vente est un PDF vectoriel ; le texte (cotes chiffrées) a un encodage non extractible.
La barre d'échelle seule était ambiguë.

### Raison
L'échelle a été validée géométriquement : à 37,5 mm/pt, les longueurs tombent pile sur les cotes
du plan (chambre 1 = 480 cm, terrasse = 400 cm, modules 100/200/150 cm). L'autre hypothèse donnait
des valeurs fausses (98,5 / 196 / 472 cm).

### Conséquences
Maquette en millimètres, dimensions réelles fiables à ±0,3 % près (sous réserve que le plan de vente
soit lui-même exact → à revérifier au relevé sur site).

---

## 2026-06-05 — Murs : footprints réels + ouvertures

### Décision
Modéliser les murs avec leur **épaisseur réelle** (16–18 cm) et conserver les **ouvertures**
(portes/fenêtres en creux), plutôt que des axes simplifiés.

### Raison
Plus fidèle au logement réel ; indispensable pour le mobilier encastré et la circulation.

### Conséquences
Les noms de pièces et cotes chiffrées ne sont pas dans le DXF (police non extractible) → le calque
DETAILS sert de gabarit visuel.

---

## 2026-06-05 — Version 3D : 1 composant SketchUp par mur, caps propres

### Décision
Livrer les murs **pré-extrudés à 2500 mm**, chaque mur dans un bloc → composant SketchUp séparé.
Chaque **sous-contour** du PDF est traité indépendamment ; points alignés supprimés ; rectangles
cappés par un quad unique (pas de diagonale), earcut réservé aux murs concaves.

### Contexte
Première version : triangulation globale qui produisait des sommets tordus et une gaine non fermée.

### Raison
Volumes fermés et manifold, manipulables individuellement, géométrie propre.

### Conséquences
86 composants. Hauteur 2500 mm **à confirmer** (sinon régénérer via `extrude_murs_3d_E703.py`, variable `H`).

---

## 2026-06-05 — Ne pas fabriquer avant relevé sur site

### Décision
Aucune cote de fabrication de mobilier n'est figée avant un **relevé laser sur site**.

### Raison
Le plan de vente est explicitement indicatif (NOTA) ; un écart de 2 cm ruine un meuble encastré.
