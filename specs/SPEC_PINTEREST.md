# SPEC — Tableau Pinterest par pièce (affichage des épingles)

> **Statut :** spec validée (T0.1, 2026-06-09). Référence pour T1.x → T2.x.
> **Auteur :** Opus 4.8. **Exécution :** Sonnet 4.6 (implémentation) + Haiku 4.5 (doc/tests).
> **Décision d'architecture :** widget d'intégration officiel Pinterest (`pinit.js`), tableaux **publics**. Pas de backend, pas d'OAuth.

---

## 1. Objectif & périmètre

Rattacher **un tableau Pinterest à chaque pièce** et **afficher ses épingles** directement dans la vue pièce de l'app.

**Dans le périmètre :**
- Champ par pièce pour coller l'URL d'un tableau Pinterest public.
- Affichage de la grille d'épingles via le widget officiel `pinit.js`.
- Fallback lien + cohérence avec le thème.

**Hors périmètre :**
- Tableaux **secrets/privés** (le widget ne les intègre pas → exigerait l'API v5 + serveur, écarté).
- Épingler/modifier depuis l'app (lecture seule).
- Remplacement de l'« assistant mots-clés Pinterest » existant (PIN_BANKS / `pin-modal`) : **conservé**, complémentaire.

> **Concept :** le widget `pinit.js` est un script officiel Pinterest. On insère une balise `<a data-pin-do="embedBoard" href="URL_DU_TABLEAU">` et le script la remplace par une iframe affichant les épingles — sans compte ni serveur. Fonctionne uniquement sur les tableaux **publics**.

---

## 2. Chargement du script (une fois, dans `<head>`)

À côté des autres scripts (Supabase, model-viewer), dans `index.html` `<head>` :
```html
<script async defer src="https://assets.pinterest.com/js/pinit.js"></script>
```
- `async defer` : ne bloque pas le rendu.
- Le script s'auto-exécute au chargement, mais pour du contenu **injecté dynamiquement** (SPA), il faut **rappeler `window.PinUtils.build()`** après insertion (cf. §5).

---

## 3. Modèle de données

**3.1 — `mkRoom()` (l.770-773)** : ajouter le champ.
```js
return {id:r.id,name:r.name,area:r.area,order:r.order,
  usages:'',needs:[],ambiance:'',constraints:'',zones:'',
  variants:[],furniture:[],validation,answers,notes:'',images:[],
  survey:mkSurvey(),surveyNote:'',plan:null,
  pinterestBoard:''};            // ← URL du tableau public (vide par défaut)
```

**3.2 — `migrate()` (l.786-793)** : compléter les états déjà sauvegardés.
```js
for(const rid in s.rooms){
  const r=s.rooms[rid];
  ...
  if(typeof r.pinterestBoard!=='string') r.pinterestBoard='';   // ← ajout
}
```

---

## 4. UI — nouvelle section dans la vue pièce

Fichier : `renderRoom()` (`index.html`). Ajouter un **accordéon « 📌 Tableau Pinterest »** juste **après** l'accordéon Visuels (`acc-img`, l.980-986), avant la fermeture du template (l.986).

```html
<div class="acc" id="acc-pinterest">
  <div class="acc-hdr" onclick="togAcc('acc-pinterest')">
    <div class="step-num" style="background:var(--text3)">📌</div>
    <h3>Tableau Pinterest</h3><span class="acc-arrow">▼</span>
  </div>
  <div class="acc-body">
    <div class="fg">
      <label class="fl">URL du tableau (public)</label>
      <input type="url" id="inp-pinterest" placeholder="https://www.pinterest.com/utilisateur/mon-tableau/"
             value="${esc(room.pinterestBoard||'')}">
      <p class="text-sm mt2">Le tableau doit être <strong>public</strong>. Colle l'URL puis valide (Entrée).</p>
    </div>
    <div id="pin-board-embed"></div>
  </div>
</div>
```

Réutilise les classes existantes `.acc`, `.fg`, `.fl`, `.text-sm`.

---

## 5. Rendu du widget & câblage (`bindRoom` + helper)

**5.1 — Helper de rendu** (nouveau, à placer près des fonctions de la vue pièce) :
```js
function renderPinBoard(url){
  const box=document.getElementById('pin-board-embed');
  if(!box) return;
  box.innerHTML='';
  const u=(url||'').trim();
  if(!u){ return; }                         // pas d'URL → rien
  if(!/^https?:\/\/(.*\.)?pinterest\.[a-z.]+\//i.test(u)){
    box.innerHTML='<p class="text-sm">URL Pinterest invalide.</p>'; return;
  }
  // Lien de secours (toujours présent, utile si le widget ne charge pas)
  const fallback=`<p class="text-sm mt2"><a href="${esc(u)}" target="_blank" rel="noopener">Ouvrir le tableau sur Pinterest ↗</a></p>`;
  // Largeur responsive selon le conteneur
  const w=Math.max(236, Math.min(box.clientWidth||400, 740));
  box.innerHTML=`<a data-pin-do="embedBoard"
       data-pin-board-width="${w}"
       data-pin-scale-height="320"
       data-pin-scale-width="115"
       href="${esc(u)}"></a>${fallback}`;
  buildPinWidget();                         // (re)scan pinit.js
}

// Rappelle PinUtils.build() ; si pinit.js pas encore chargé, réessaie une fois prêt
function buildPinWidget(){
  if(window.PinUtils && PinUtils.build){ PinUtils.build(); return; }
  let n=0; const t=setInterval(()=>{
    if(window.PinUtils && PinUtils.build){ clearInterval(t); PinUtils.build(); }
    else if(++n>20) clearInterval(t);       // abandon après ~5 s
  },250);
}
```

**5.2 — Câblage dans `bindRoom()` (l.1178+)** : gérer le champ URL et déclencher le rendu.
```js
// Tableau Pinterest
const pin=document.getElementById('inp-pinterest');
if(pin){
  const apply=()=>{ state.rooms[rid].pinterestBoard=pin.value.trim(); save(); renderPinBoard(pin.value); };
  pin.addEventListener('change',apply);                                  // blur
  pin.addEventListener('keydown',e=>{ if(e.key==='Enter'){ pin.blur(); }});
}
```

**5.3 — Rendu initial** : à la fin de `renderRoom()` (près de `loadImgs(room)`, l.988), afficher le widget si une URL est déjà enregistrée :
```js
renderPinBoard(room.pinterestBoard);
```

---

## 6. Fallback & cas limites

- **Pas d'URL** → section vide (juste le champ). Aucune erreur.
- **URL non-Pinterest** → message « URL invalide ».
- **Widget qui ne charge pas** (script bloqué, tableau privé, réseau) → le **lien de secours** « Ouvrir le tableau ↗ » reste visible. Pas de blocage.
- **Changement de pièce** : `renderRoom` réinjecte le markup et rappelle `renderPinBoard` → le widget se reconstruit proprement (conteneur vidé avant insertion).

---

## 7. Thème, responsive & confidentialité

- **Thème :** l'iframe Pinterest est stylée par Pinterest (fond clair, non thémable). L'afficher sur le fond de carte de l'accordéon ; ne pas tenter de forcer le dark-mode dedans. *(Limitation acceptée.)*
- **Responsive :** `data-pin-board-width` calculé depuis la largeur du conteneur (`renderPinBoard`, §5.1), borné 236-740 px. Sur mobile, le widget s'ajuste à la largeur dispo.
- **Confidentialité :** charger `pinit.js` envoie des requêtes à Pinterest (script tiers). Cohérent avec le reste (CDN Supabase / model-viewer). Acceptable ; noté.

---

## 8. Améliorations optionnelles (Phase 2, non requises)

- Bouton dans la section qui **ouvre l'assistant mots-clés** existant (`pin-modal`) pré-rempli pour la pièce courante.
- Un tableau Pinterest **global** (niveau Plan global), même mécanique avec `state.meta.pinterestBoard`.

---

## 9. Critères d'acceptation

- [ ] Chaque pièce a une section « Tableau Pinterest » avec un champ URL persistant.
- [ ] Coller l'URL d'un tableau **public** + valider affiche la grille d'épingles dans l'app.
- [ ] Le lien « Ouvrir le tableau ↗ » est présent en secours.
- [ ] URL vide → rien ; URL invalide → message ; widget en échec → lien toujours là.
- [ ] Le widget s'affiche correctement après changement de pièce (pas de doublon/iframe morte).
- [ ] Fonctionne sur PC et iPhone (largeur adaptée).
- [ ] L'« assistant mots-clés Pinterest » existant fonctionne toujours.

---

## 10. Tâches par modèle

| ID | Tâche | Modèle | Dépend de |
|----|-------|--------|-----------|
| T0.1 | Cette SPEC | Opus 4.8 | — |
| T1.1 | Modèle de données : `pinterestBoard` dans `mkRoom` + `migrate` (§3) | Sonnet 4.6 | T0.1 |
| T1.2 | `pinit.js` dans `<head>` + accordéon « Tableau Pinterest » dans `renderRoom` + helpers `renderPinBoard`/`buildPinWidget` + câblage `bindRoom` (§2,4,5) | Sonnet 4.6 | T1.1 |
| T1.3 | Fallback/cas limites (§6) + vérif responsive/thème + déploiement | Sonnet 4.6 | T1.2 |
| T2.1 | Doc « rendre un tableau public + récupérer son URL » | Haiku 4.5 | T0.1 |
| T2.2 | Tester sur 2-3 pièces avec de vrais tableaux (PC + iPhone) ; MàJ `STATUS.md`/`PROJECT_MAP.md` | Haiku 4.5 | T1.3 |
| **Humain** | Rendre les tableaux concernés **publics** et récupérer leurs URLs | Thibault | — |
