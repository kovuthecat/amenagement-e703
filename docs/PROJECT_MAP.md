# PROJECT_MAP.md

Carte synthétique du projet : où trouver quoi.

## Vue d'ensemble

Projet d'aménagement + mobilier sur mesure du logement E703 (T5, Saint-Ouen). Pas un projet de code :
l'« artefact » central est la **maquette SketchUp**, alimentée par le plan de vente et des scripts
de conversion PDF→DXF.

## Arborescence du dossier

```text
Amenagement appartement/
│
├─ 📄 CLAUDE.md           # instructions pour Claude Code
├─ 📄 STRUCTURE.md        # documentation de la structure organisée
├─ 📄 index.html          # entrée app web (Vercel deployment)
├─ 📄 manifest.json       # PWA manifest
├─ 📄 robots.txt          # SEO robots
│
├─ 📁 docs/               # Documentation + contexte projet
│  ├─ PROJECT_BRIEF.md       # objectif, périmètre, contraintes
│  ├─ DECISIONS.md           # journal des décisions d'aménagement
│  ├─ CONTRAINTES.md         # contraintes techniques du logement
│  ├─ STATUS.md              # état actuel du projet
│  ├─ TASKS.md               # tâches en cours / à faire / relevés site
│  ├─ ROADMAP.md             # phases 1→4
│  ├─ GUIDE_AGENCEMENT.md    # méthode 6 étapes + fiches par pièce
│  └─ PROJECT_MAP.md         # ce fichier
│
├─ 📁 specs/              # Spécifications des features web
│  ├─ SPEC_OUTIL_AGENCEMENT.md    # outil interactif agencement.html
│  ├─ SPEC_VIEWER_3D.md           # viewer 3D (model.glb)
│  ├─ SPEC_MIGRATION_ONLINE.md    # migration vers plateforme online
│  └─ SPEC_PINTEREST.md           # intégration Pinterest
│
├─ 📁 data/               # Données sources
│  ├─ Plan E703.pdf          # plan de vente (source géométrique, indicatif)
│  └─ supabase_setup.sql     # schéma BDD (viewer + intégrations)
│
├─ 📁 3d/                 # Assets 3D + scripts
│  ├─ Plan 3D.skp            # MAQUETTE SketchUp (artefact principal)
│  ├─ Plan 3D.skb            # backup SketchUp
│  ├─ model.glb              # export GLB pour viewer web
│  └─ scripts/
│     ├─ convert-glb.cmd     # batch SketchUp → GLB
│     ├─ Plan 3D.obj         # obj intermédiaire
│     └─ (scripts Python : extrude_murs_3d_E703.py, etc.)
│
└─ 📁 assets/            # Assets publiques (icons, etc.)
   └─ icons/
      ├─ icon-180.png
      ├─ icon-192.png
      └─ icon-512.png
```

## Fichiers générés

### À rapatrier depuis `C:\Users\kovu\Downloads\` → `data/plan-source/`
- `Plan_E703.dxf` — plan complet, calques MURS / SURFACES / DETAILS
- `Plan_E703_MURS_SU.dxf` — murs 2D (80 faces fermées) à extruder soi-même
- `Plan_E703_MURS_3D.dxf` — murs **pré-extrudés 3D** (86 composants, 2500 mm) → importé dans `Plan 3D.skp`
- `Plan_E703_DETAILS.dxf` — **nettoyé** : seulement le fixe → calques OUVERTURES (portes+arcs, fenêtres) + SANITAIRES

### Scripts de conversion → `3d/scripts/`
- `pdf_to_dxf_E703.py` — PDF → DXF complet
- `murs_sketchup_E703.py` — extraction murs SU
- `extrude_murs_3d_E703.py` — extrude murs 2D en 3D (hauteur = var `H`)
- `details_clean_E703.py` — nettoyage calques détails

## Paramètres clés

- Échelle : **37,50 mm/pt** · unités maquette : **mm**
- Hauteur sous plafond modélisée : **2500 mm** (à confirmer)
- Régénérer les murs 3D : `python extrude_murs_3d_E703.py` (variable `H` = hauteur)

## Données logement (plan de vente)

T5, 106,62 m² + terrasse 36,56 m². Séjour 29,94 · Ch4 15,09 · Ch1 15,01 · Ch2 12,02 · Ch3 10,67 ·
SDE 5,97 · Entrée 5,71 · SDB 5,37 · DGT 4,80 · WC 2,04 m².

> **Découpage de travail cuisine/séjour** (cf. DECISIONS 2026-06-07) : le lot « Séjour 29,94 m² »
> du plan englobe la cuisine ouverte. Pour l'agencement on dissocie **cuisine ≈ 7,5 m²** (zone
> carrelée mesurée dans SketchUp) et **séjour net ≈ 22,5 m²**. Valeurs de travail, à confirmer au relevé.

## Règles locales

- Toute fabrication attend le **relevé sur site** (cf. DECISIONS).
- Mobilier modélisé en composants, à l'épaisseur réelle des matériaux.
- Outils de production : SketchUp + OpenCutList ; laser/DXF et impression 3D en appoint.
