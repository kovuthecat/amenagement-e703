# SPEC — Viewer 3D interactif de la maquette dans l'app

> **Statut :** spec validée (T0.1, 2026-06-09). Référence pour T1.x → T2.x.
> **Auteur :** Opus 4.8. **Exécution :** Sonnet 4.6 (pipeline + intégration) + Haiku 4.5 (export/conversion/tests).
> **Décision d'architecture :** `<model-viewer>` + **GLB**, source d'export SketchUp = **OBJ**.

---

## 1. Objectif & périmètre

Afficher la maquette SketchUp en **3D interactive** (orbit, zoom, panoramique tactile) dans la vue **Plan global** de l'app en ligne, sur PC et mobile.

**Dans le périmètre :**
- Conversion d'un export SketchUp en format web (GLB).
- Affichage via le composant `<model-viewer>` dans `renderPlanGlobal()`.
- Responsive + thème clair/sombre + plein écran + AR (Android d'office ; iOS optionnel, voir §5).

**Hors périmètre :**
- Édition 3D dans le navigateur (la modélisation reste **locale dans SketchUp**).
- Synchronisation du modèle par appareil : le `.glb` est un **asset unique partagé** (pas de upload utilisateur).

---

## 2. Format & pipeline de conversion

> **Concept :** SketchUp n'exporte pas GLB directement. On exporte en **OBJ** (géométrie + matériaux via `.mtl` + textures), puis on convertit en **GLB** (binaire compact lu nativement sur le web) avec `obj2gltf` — un outil npm, **sans Blender**.

**Pipeline :**
```
SketchUp  ──Export OBJ──►  Plan 3D.obj (+ .mtl + dossier textures)
          ──obj2gltf────►  model.glb
```

**Commande de conversion (T1.1) :**
```bash
npx obj2gltf -i "Plan 3D.obj" -o model.glb
```
- `obj2gltf` lit automatiquement le `.mtl` référencé et les textures du même dossier.
- Sortie `.glb` = binaire auto-contenu (géométrie + matériaux + textures dans un seul fichier).
- Fournir un petit script (`scripts/convert-glb.cmd` ou note README) pour relancer la commande à chaque mise à jour du modèle.

**Options d'export OBJ côté SketchUp (doc T2.1) :**
- **Exporter les matériaux/textures** : activé.
- **« Swap YZ coordinates (Y up) »** : activé → la maquette est droite dans `<model-viewer>` (glTF est Y-up, SketchUp est Z-up).
- Unités : sans importance pour la visualisation (`camera-controls` recadre automatiquement).

---

## 3. Hébergement du fichier `model.glb`

**Choix par défaut : asset statique dans le repo**, à la racine, servi par Vercel.
- Ajouter `model.glb` à la racine du projet.
- Le whitelister dans `.vercelignore` (T1.3) — sinon il est exclu par la liste blanche actuelle.
- Référence dans l'app : URL **relative** `model.glb`.
- Mise à jour = remplacer le fichier + `git push` (déploie le nouveau modèle).

**Bascule si `model.glb` > ~10 Mo :** héberger sur **Supabase Storage** (bucket `e703-images`, public-read), **upload manuel via le dashboard** Supabase (contourne le souci RLS d'upload anonyme déjà rencontré). La référence devient alors l'URL publique Supabase. *(Décision à prendre à la 1ʳᵉ conversion selon le poids — voir §7.)*

---

## 4. Intégration UI — `renderPlanGlobal()`

Fichier : `index.html`, fonction `renderPlanGlobal()` (actuellement l.1464-1478). Elle gère déjà l'image du plan 2D. On **ajoute un panneau 3D au-dessus** de la zone plan 2D, sans toucher à la logique image existante.

**4.1 — Chargement du composant (une fois, dans `<head>`) :**
```html
<script type="module" src="https://cdn.jsdelivr.net/npm/@google/model-viewer/dist/model-viewer.min.js"></script>
```

**4.2 — Markup injecté dans `mc.innerHTML` (en tête du template de `renderPlanGlobal`) :**
```html
<div class="plan-panel">
  <div class="plan-panel-hdr">
    <strong>Maquette 3D</strong>
    <button class="btn btn-ghost btn-sm" onclick="mv3dFullscreen()">⛶ Plein écran</button>
  </div>
  <model-viewer id="mv3d"
    src="model.glb"
    camera-controls
    touch-action="pan-y"
    auto-rotate auto-rotate-delay="3000"
    shadow-intensity="1"
    ar ar-modes="webxr scene-viewer quick-look"
    style="width:100%;height:60vh;background-color:var(--bg2);border-radius:8px">
    <div slot="poster" class="text-sm" style="padding:24px">Chargement de la maquette…</div>
    <div slot="error" class="text-sm" style="padding:24px">
      Maquette 3D non disponible. Convertis le modèle SketchUp en <code>model.glb</code> (voir SPEC).
    </div>
  </model-viewer>
</div>
```
- Réutilise les classes existantes `.plan-panel`, `.plan-panel-hdr`, `.btn-sm` (déjà définies dans le CSS, cf. section « E/F — plans »).
- `slot="error"` couvre proprement le cas **fichier absent** (§6) : `<model-viewer>` affiche ce contenu si le `src` échoue.

**4.3 — Helper plein écran (JS) :**
```js
function mv3dFullscreen(){
  const mv = document.getElementById('mv3d');
  if(mv && mv.requestFullscreen) mv.requestFullscreen();
}
```

**4.4 — Pas de modification** de `wireGlobalPlan`, `setGlobalPlan`, `delGlobalPlan`, `loadGlobalPlan` (logique du plan 2D conservée telle quelle).

---

## 5. Configuration `<model-viewer>` : responsive, thème, AR

- **Responsive :** `width:100%`, hauteur `60vh` (s'adapte à l'écran ; sur mobile le tiroir de nav ne gêne pas, on est dans `#main`).
- **Thème clair/sombre :** `background-color:var(--bg2)` suit la variable CSS du thème. Rien d'autre à faire (l'éclairage par défaut de model-viewer convient).
- **Tactile :** `touch-action="pan-y"` laisse le scroll vertical de la page fonctionner tout en permettant l'orbite à un doigt.
- **AR — nuance importante :**
  - **Android** : fonctionne d'office avec le `.glb` (mode `scene-viewer`).
  - **iOS** : Quick Look exige un fichier **USDZ** séparé, pas le GLB. Pour activer l'AR iOS, ajouter un attribut `ios-src="model.usdz"` + générer ce USDZ (export annexe). **Optionnel / Phase 2** — l'orbite/zoom marche partout sans ça ; seul le bouton AR iOS nécessite le USDZ.

---

## 6. Comportement si `model.glb` est absent

Tant que le modèle n'a pas été converti/déployé :
- `<model-viewer>` tente de charger `model.glb`, échoue, et affiche le contenu de `slot="error"` (message explicatif).
- Aucune erreur bloquante pour le reste de la vue Plan global (l'image 2D reste pleinement fonctionnelle).
- **Aucune détection préalable nécessaire** (pas de HEAD fetch) : le slot d'erreur natif suffit.

---

## 7. Poids, performance & mitigations

Risque : la maquette (murs pré-extrudés + mobilier) peut produire un GLB lourd → lenteur, surtout mobile.

À la **première conversion** (T2.2), vérifier le poids du `.glb` :
- **< 10 Mo** : OK en asset statique (§3).
- **> 10 Mo** ou rendu lent sur mobile → mitigations, par ordre :
  1. **Masquer/supprimer les composants inutiles** dans SketchUp avant export (mobilier non finalisé, calques techniques).
  2. Réduire/supprimer les textures lourdes.
  3. Compresser le GLB (Draco) : `obj2gltf` peut produire un GLB compressé via options, ou post-traiter avec `gltf-pipeline -i model.glb -o model.glb -d` (Draco). `<model-viewer>` décode Draco nativement.
  4. En dernier recours, héberger sur Supabase Storage (§3).

---

## 8. Critères d'acceptation

- [ ] La vue **Plan global** affiche un panneau « Maquette 3D » avec le modèle chargé.
- [ ] Orbite, zoom et panoramique fonctionnent à la souris (PC) **et au doigt** (mobile).
- [ ] Le bouton plein écran fonctionne.
- [ ] Le fond du viewer suit le thème clair/sombre.
- [ ] Si `model.glb` est absent, un message explicatif s'affiche sans casser la vue.
- [ ] Le `.glb` est servi en ligne (whitelisté dans `.vercelignore`) et l'app le charge depuis l'URL relative.
- [ ] Poids du `.glb` vérifié et acceptable sur mobile (< ~10 Mo ou mitigé).
- [ ] (Optionnel) Bouton AR fonctionnel sur Android.

---

## 9. Tâches par modèle

| ID | Tâche | Modèle | Dépend de |
|----|-------|--------|-----------|
| T0.1 | Cette SPEC | Opus 4.8 | — |
| **Humain** | Exporter le modèle SketchUp en **OBJ** (Fichier → Exporter → modèle 3D → OBJ, options §2) | Thibault | — |
| T1.1 | Script/commande de conversion OBJ→GLB (`obj2gltf`) + note README | Sonnet 4.6 | T0.1 |
| T1.2 | Intégrer `<model-viewer>` (CDN dans `<head>` + panneau dans `renderPlanGlobal` + helper plein écran), responsive/thème (§4-5) | Sonnet 4.6 | T0.1 |
| T1.3 | Whitelister `model.glb` dans `.vercelignore` + vérifier le `slot=error` (fichier absent) | Sonnet 4.6 | T1.2 |
| T2.1 | Doc « exporter en OBJ depuis SketchUp » (options à cocher) | Haiku 4.5 | T0.1 |
| T2.2 | Lancer la conversion sur le 1ᵉʳ export OBJ, vérifier le poids (§7), commiter `model.glb`, déployer | Haiku 4.5 | T1.1, T1.3, Humain |
| T2.3 | Tester sur PC + iPhone (orbit/zoom/plein écran), MàJ `STATUS.md`/`PROJECT_MAP.md` | Haiku 4.5 | T2.2 |
