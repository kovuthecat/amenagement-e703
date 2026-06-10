# Structure du Projet Aménagement E703

## Organisation logique du dossier

```
Amenagement appartement/
├── CLAUDE.md                      # Instructions Claude Code (à lire en premier)
├── STRUCTURE.md                   # Ce fichier
├── index.html                     # Entrée app web (Vercel deployment) ⭐
├── manifest.json                  # PWA manifest
├── robots.txt                     # SEO robots.txt
│
├── 📁 docs/                       # Documentation + contexte projet
│   ├── PROJECT_BRIEF.md           # Objectifs et scope
│   ├── PROJECT_MAP.md             # Index fichiers et paramètres
│   ├── DECISIONS.md               # Décisions d'aménagement archivées
│   ├── CONTRAINTES.md             # Contraintes métier & réglementaires
│   ├── STATUS.md                  # État actuel du projet
│   ├── TASKS.md                   # Tâches en cours et à faire
│   ├── ROADMAP.md                 # Roadmap globale
│   └── GUIDE_AGENCEMENT.md        # Guide d'utilisation de l'outil
│
├── 📁 specs/                      # Spécifications de features
│   ├── SPEC_OUTIL_AGENCEMENT.md   # Outil d'agencement interactif
│   ├── SPEC_VIEWER_3D.md          # Viewer 3D web (model.glb)
│   ├── SPEC_MIGRATION_ONLINE.md   # Migration vers plateforme online
│   └── SPEC_PINTEREST.md          # Intégration Pinterest
│
├── 📁 data/                       # Données sources
│   ├── Plan E703.pdf              # Plan de vente (source du relevé)
│   ├── plan-source/               # Plans extraits du PDF (DXF, etc.)
│   └── supabase_setup.sql         # Schéma BDD (viewer + intégrations)
│
├── 📁 3d/                         # Assets 3D et scripts
│   ├── Plan 3D.skp                # Maquette SketchUp (artefact central)
│   ├── Plan 3D.skb                # Backup SketchUp
│   ├── model.glb                  # Export glb pour viewer web
│   └── scripts/
│       ├── convert-glb.cmd        # Script batch (SketchUp → GLB)
│       ├── Plan 3D.obj            # Obj intermédiaire
│       └── (scripts Python)
│
├── 📁 assets/                     # Assets publiques (icons, etc.)
│   └── icons/
│       ├── icon-180.png
│       ├── icon-192.png
│       └── icon-512.png
│
├── .git/                          # Repository git (local)
└── .vercel/                       # Config Vercel deployment
```

## ✅ Organisation complétée (2026-06-10)

- ✓ Fichiers de contexte → `docs/`
- ✓ Specs de features → `specs/`
- ✓ Plans sources → `data/`
- ✓ Maquette 3D + scripts → `3d/`
- ✓ Fichiers web → **racine** (pour Vercel deployment)
- ✓ Icons publiques → `assets/icons/`

## Principes

- **docs/** = tous les contextes du projet (BRIEF, DECISIONS, STATUS, TASKS)
- **specs/** = spécifications des features web/outils associés
- **data/** = sources brutes (PDF, SQL, plans extraits)
- **3d/** = maquette SketchUp, exports et scripts de génération 3D
- **web/** = application web (viewer, agencement, etc)

## Utilisation post-organisation

Avant toute modification, lire (dans cet ordre) :
1. `docs/PROJECT_BRIEF.md` – le "pourquoi"
2. `docs/DECISIONS.md` – les choix d'aménagement
3. `docs/CONTRAINTES.md` – les limites métier
4. Puis modifier selon la spec ou la décision archivée

Après chaque session, mettre à jour :
- `docs/STATUS.md` (état courant)
- `docs/TASKS.md` (avancement)
- `docs/PROJECT_MAP.md` (si localisation de fichiers change)
