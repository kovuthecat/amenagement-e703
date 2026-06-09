# SPEC — Mise en ligne de `agencement.html` (sync multi-terminaux via Supabase, sans authentification)

> **Statut :** spec validée (T0.1, 2026-06-09 ; révisée — **sans auth**). Document de référence pour T1.x → T3.x.
> **Auteur de la spec :** Opus 4.8. **Exécution :** Sonnet 4.6 (dev) + Haiku 4.5 (migration/doc).

---

## 1. Objectif & périmètre

Rendre l'outil `agencement.html` **consultable et modifiable depuis plusieurs terminaux** (PC + téléphone), avec des données **partagées et synchronisées** (et non plus isolées par navigateur).

**Dans le périmètre :**
- Hébergement statique du fichier HTML (URL accessible partout).
- Persistance partagée dans le cloud (état + images) via **Supabase**.
- **Pas d'authentification** : un seul jeu de données partagé, accessible directement.

**Hors périmètre :**
- La modélisation SketchUp (`.skp`) reste **100 % locale**.
- Pas d'édition collaborative temps réel.
- Refonte UI : aucune. On ne touche pas au rendu ni au flux de l'app.

**⚠️ Confidentialité (décision assumée) :** sans auth, quiconque possède l'URL a un accès lecture **et écriture** complet (la clé anon est dans le code source). Le plan contient une adresse réelle. **Mitigation retenue : URL non devinable** (slug aléatoire long, page non listée/non indexée). Voir §7.

**Principe directeur :** la persistance est déjà isolée dans **4 fonctions** (`openDB`, `dbGet`, `dbSet`, `dbDel`, lignes 670-684). On remplace **uniquement** ces fonctions par un adaptateur Supabase qui **conserve exactement les mêmes signatures**. Tout le reste de l'app (`save`, `loadImgs`, `exportBackup`, `importBackup`, `init`, les vues…) reste **inchangé**.

---

## 2. Modèle de données actuel (rappel)

IndexedDB `agencement-e703` (v1), 2 object stores :

| Store | Clé | Valeur |
|-------|-----|--------|
| `data` | `'state'` (clé unique) | l'**état JSON complet** (objet `state`) |
| `images` | `blobRef` (uid) | un **Blob JPEG** (photo d'inspiration ou plan, redimensionné ≤1600px) |

Structure de l'objet `state` (voir `mkSeedState`/`mkRoom`, lignes 699-713) :
```
state = {
  meta: { appName, version, lastModified (ISO), planGlobalRef (blobRef|null) },
  rooms: {
    [roomId]: {
      id, name, area, order,
      usages, needs[], ambiance, constraints, zones,
      variants[], furniture[], validation{}, answers{}, notes,
      images[],          // chaque image : { id, caption, source, tags[], blobRef }
      survey[], surveyNote,
      plan               // { blobRef, ... } | null
    }
  }
}
```
> **Important :** l'état JSON ne contient **pas** les binaires. Il ne stocke que des **références** (`blobRef`, `plan.blobRef`, `meta.planGlobalRef`). Les binaires vivent dans le store `images`.

Points d'usage des 4 fonctions (à NE PAS modifier dans le reste du code) :
- `save()` (l.734) — debounce 500 ms → `dbSet('data','state',state)`.
- `loadImgs()` (l.1151) — pour chaque image : `dbGet('images',blobRef)` → `URL.createObjectURL(blob)`.
- ajout/suppression image & plan → `dbSet('images',ref,blob)` / `dbDel('images',ref)`.
- `exportBackup()` (l.1857) — inline les blobs en dataURL dans un `.json`.
- `importBackup()` (l.1883) — réextrait les dataURL en blobs via `dbSet('images',…)`.

---

## 3. Cible Supabase (sans auth)

Sans authentification, on travaille avec le rôle **`anon`** (clé anon embarquée dans le HTML). Le modèle « par utilisateur » disparaît : **une seule ligne d'état partagée** (clé fixe) et **un seul espace d'images**.

### 3.1 Table d'état (Postgres) — ligne unique partagée

```sql
-- Une seule ligne pour toute l'app (id fixe 'e703').
create table public.app_state (
  id            text primary key default 'e703',
  state         jsonb not null,
  last_modified timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

alter table public.app_state enable row level security;

-- Accès complet au rôle anonyme (pas d'auth). Limité à la ligne 'e703'.
create policy "anon read"   on public.app_state for select to anon using (id = 'e703');
create policy "anon insert" on public.app_state for insert to anon with check (id = 'e703');
create policy "anon update" on public.app_state for update to anon
  using (id = 'e703') with check (id = 'e703');

-- Met à jour updated_at à chaque écriture (détection de conflit, §5).
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

create trigger trg_app_state_touch
  before update on public.app_state
  for each row execute function public.touch_updated_at();
```

### 3.2 Bucket Storage (images)

- Bucket nommé `e703-images`.
- Chemin d'un objet : `{blobRef}` (le `blobRef` = uid existant ; `plan.blobRef` et `meta.planGlobalRef` suivent la même convention). Pas de dossier utilisateur.
- Content-Type : `image/jpeg`.
- Le plus simple : bucket **public en lecture** + policies autorisant le rôle `anon` à `insert`/`delete`. (Alternative : bucket privé + policies `anon` complètes ; mais public-read suffit et évite de générer des URLs signées.)

```sql
-- Si bucket public : la lecture passe par getPublicUrl, pas besoin de policy select.
create policy "anon images insert" on storage.objects
  for insert to anon with check (bucket_id = 'e703-images');
create policy "anon images delete" on storage.objects
  for delete to anon using (bucket_id = 'e703-images');
```

### 3.3 Authentification

**Aucune.** Pas d'écran de login, pas de session, pas de `onAuthStateChange`. La protection repose uniquement sur le caractère **non devinable de l'URL** de déploiement (§7).

---

## 4. Adaptateur — réécriture des 4 fonctions

L'adaptateur **conserve les signatures** : `openDB()`, `dbGet(store,key)`, `dbSet(store,key,val)`, `dbDel(store,key)`. Le reste de l'app ne voit aucune différence.

Pseudocode (à implémenter en T1.2) :

```js
// Inclure le SDK : <script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
const SB_URL = '...';        // config injectée au déploiement (T2.1)
const SB_ANON = '...';
const sb = supabase.createClient(SB_URL, SB_ANON);
const STATE_ID = 'e703';
let stateBaseline = null;    // updated_at chargé, pour la détection de conflit (§5)

// openDB() : plus de garde d'auth. Peut juste vérifier la connectivité (optionnel).
async function openDB(){ /* no-op : le client sb est déjà prêt */ }

async function dbGet(store, key){
  if(store === 'data'){            // key === 'state'
    const { data, error } = await sb.from('app_state')
      .select('state, updated_at').eq('id', STATE_ID).maybeSingle();
    if(error) throw error;
    if(!data) return undefined;    // déclenche le seed dans init()
    stateBaseline = data.updated_at;
    return data.state;
  }
  if(store === 'images'){          // key === blobRef
    // bucket public : télécharger le blob via l'URL publique
    const { data } = sb.storage.from('e703-images').getPublicUrl(key);
    const resp = await fetch(data.publicUrl);
    if(!resp.ok) return null;      // loadImgs tolère null (cf. .catch(()=>null))
    return await resp.blob();      // renvoie un Blob, comme avant
  }
}

async function dbSet(store, key, val){
  if(store === 'data'){
    const { data, error } = await sb.from('app_state')
      .upsert({ id:STATE_ID, state:val, last_modified:new Date().toISOString() })
      .select('updated_at').single();
    if(error) throw error;
    stateBaseline = data.updated_at;
  }
  if(store === 'images'){          // val === Blob
    const { error } = await sb.storage.from('e703-images')
      .upload(key, val, { contentType:'image/jpeg', upsert:true });
    if(error) throw error;
  }
}

async function dbDel(store, key){
  if(store === 'images'){
    await sb.storage.from('e703-images').remove([key]);
  }
}
```

**Remarques :**
- `dbGet('images')` reste **asynchrone et renvoie un Blob** → `loadImgs` (qui fait déjà `await … .catch(()=>null)`) fonctionne tel quel.
- `dbSet('data')` écrit l'**objet entier** (comme aujourd'hui). Simple, robuste, suffisant.
- `exportBackup` / `importBackup` passent par ces mêmes fonctions → **compatibles sans modification** (T1.4 = simple vérification).

---

## 5. Stratégie de synchronisation & conflits

Usage **solo, rarement deux appareils en écriture simultanée** → **last-write-wins** acceptable, avec garde-fous légers :

1. **Rechargement au focus** — sur `visibilitychange`/`focus` de la fenêtre, si aucune modif locale n'est en attente, recharger l'état depuis Supabase (`dbGet('data','state')` → `migrate` → re-render). Évite d'éditer une version périmée. *(implémentation T1.2)*
2. **Détection de conflit à l'écriture** — avant chaque `upsert` d'état, comparer le `updated_at` serveur courant au `stateBaseline` mémorisé au dernier chargement/sauvegarde. S'il a avancé (un autre appareil a écrit entre-temps) → afficher un avertissement (« Données modifiées sur un autre appareil. Recharger / Écraser ? »). Par défaut **bloquer l'écrasement silencieux**. *(implémentation T1.2)*
3. **Indicateur de sauvegarde** — `#save-ind` (états saving/saved/error, fonction `setSI`) reflète désormais l'état **cloud** : `saving` pendant l'upsert, `saved` au succès, `error` si réseau échoue. *(vérif T3.2)*
4. **Images** — immuables une fois uploadées (clé = uid), pas de conflit ; suppression idempotente.

> Cache local optionnel (IndexedDB comme cache d'images pour la perf/offline) = **amélioration future**, hors v1.

---

## 6. Point d'intégration dans le code (`init`)

`init()` (l.1976) appelle `await openDB()` puis `dbGet('data','state')`. Sans auth, **l'intégration est minimale** :

1. `openDB()` devient un no-op (ou un simple ping de connectivité). Le client Supabase est créé au chargement du script.
2. Le reste de `init` (`saved = await dbGet('data','state')`, seed si `!saved`, `renderMemo`, `selRoom`/`showDash`) **ne change pas**.
3. Le `try/catch` global (l.1995) gère les erreurs réseau (afficher un message « hors-ligne / réessayer »).
4. Ajouter le listener `visibilitychange`/`focus` pour le rechargement (§5.1).

---

## 7. Configuration, déploiement & URL non devinable (cadrage pour T2.1)

- **Hôte** : Netlify ou Cloudflare Pages (dépôt d'un fichier statique unique). URL HTTPS.
- **URL non devinable** = la seule protection : déployer sous un chemin/sous-domaine **aléatoire et long** (ex. `e703-x7k9q2m4p8.netlify.app` ou un chemin `/x7k9q2m4p8/agencement.html`). Ne pas communiquer l'URL publiquement.
- **Anti-indexation** : ajouter `<meta name="robots" content="noindex,nofollow">` dans le HTML et un `robots.txt` `Disallow: /` pour éviter le référencement moteur.
- **Config** : injecter `SB_URL` + `SB_ANON` en clair dans le HTML (fichier unique, pas de build).
- Pas de *Redirect URL* Supabase à configurer (pas d'auth).

---

## 8. Migration des données existantes (cadrage pour T2.2)

1. Ouvrir la version **actuelle** (locale) de `agencement.html` dans le navigateur où vivent les données.
2. `Export ▾ → 💾 Backup complet (.json)` → JSON avec **images inlinées en dataURL**.
3. Ouvrir la version **en ligne**, puis `Import JSON` avec ce fichier.
4. `importBackup` réécrit l'état + ré-uploade chaque image via l'adaptateur (`dbSet('images',…)` → Storage). **Aucun code spécifique à écrire.**
5. Vérifier sur un 2e appareil que tout est présent (texte + images + plans).

---

## 9. Critères d'acceptation

- [ ] La page s'ouvre directement sur les données (aucun login), sur PC et téléphone.
- [ ] Une modif (texte, besoin, variante, mobilier, note, validation) faite sur l'appareil A apparaît sur l'appareil B après rechargement/focus.
- [ ] Ajout d'une image sur A → visible sur B ; suppression sur A → disparaît sur B.
- [ ] L'indicateur `#save-ind` passe saving → saved à chaque écriture, error en cas d'échec réseau.
- [ ] Avertissement affiché si l'état a été modifié sur un autre appareil entre-temps (pas d'écrasement silencieux).
- [ ] Export/Import JSON fonctionnent toujours.
- [ ] La page porte `noindex` et l'URL de déploiement est aléatoire/non listée.
- [ ] La modélisation `.skp` n'est pas concernée (reste locale).

---

## 10. Découpage des tâches

| ID | Tâche | Modèle | Dépend de |
|----|-------|--------|-----------|
| T0.1 | Cette SPEC | Opus 4.8 | — |
| T1.1 | Projet Supabase : table `app_state` (ligne unique + trigger + RLS rôle `anon`), bucket `e703-images` public-read + policies `anon` insert/delete | Sonnet 4.6 | T0.1 |
| T1.2 | Adaptateur (§4) + sync au focus + détection de conflit (§5) ; remplace les 4 fonctions, garde les signatures | Sonnet 4.6 | T1.1 |
| T1.3 | *(supprimée — plus d'écran de login)* | — | — |
| T1.4 | Vérifier compat `exportBackup`/`importBackup` avec l'adaptateur | Sonnet 4.6 | T1.2 |
| T2.1 | Déploiement statique (Netlify/CF Pages) sous URL aléatoire + `noindex`/`robots.txt` + config clés (§7) | Sonnet 4.6 | T1.2 |
| T2.2 | Migration des données existantes via backup JSON (§8) | Haiku 4.5 | T2.1 |
| T2.3 | Tests bout-en-bout 2 appareils (§9) | Sonnet 4.6 | T2.2 |
| T3.1 | MàJ `STATUS.md` / `PROJECT_MAP.md` / `CLAUDE.md` | Haiku 4.5 | T2.3 |
| T3.2 | Vérif indicateur `#save-ind` reflète l'état cloud | Haiku 4.5 | T2.3 |
