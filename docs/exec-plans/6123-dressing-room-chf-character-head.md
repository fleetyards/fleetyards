# Dressing room: the player's own character head from an uploaded .chf, built in the browser

Working plan for #6123. Decisions live in the issue body. Deleted before the PR merges.

## Goal
A signed-in player uploads a `.chf`, and the dressing room body shows that character's head: face, hair, brows, beard, piercings, skin and eyes. Worn headwear hides or swaps the hair. Saved outfits and share links carry it, and the exact file can be downloaded again.

## Source data (sc_data bucket, `characters/`)
- `index.json` `bodies.<body>`:
  - `faces` gives the library id, file md5s and `library_revision`;
  - `skin.tone` is the tone `body_textured.glb` is baked at;
  - `chf` gives the per-body index and catalogue paths and their md5s.
- `<body>/faces/{index.json,library.bin,normals.bin}`: the face library. Spec in `faces/README.md`.
- `chf/catalog.json` (2.1 MB raw):
  - items, skins, textures, eye, ports, hidden_parts;
  - `headwear_items[sc_key]` (897 items) and `headwear_rule`.
- `<body>/chf/index.json`: geometry paths with byte sizes, but no md5s. The skin sets and textures aren't listed with md5s either, so the import compares ETags.
- `<body>/chf/geometry/*.glb` (281 / 276), `<body>/chf/skin/*.webp` (141 / 132), `chf/textures/**.webp` (246).
- Test vectors:
  - `chf/tests/<name>.{chf,character.json,samples.json}`, 20 cases; `__<sc_key>` cases carry worn headwear;
  - `<body>/faces/tests/*.expected.{bin,json}`.
- A local copy for development is in the session scratchpad (`chf/characters/`). Test fixtures get vendored from it.

## Shape
- **Ruby resolves, the browser renders.** The server parses the `.chf` and resolves it against the catalogue into the reference `spec()` shape: face weights, skin, eyes, meshes with three.js material parameters, and each hair or beard item's headwear variants with their materials. Asset paths become blob URLs. The browser does the face blend, the head binding, the head composite and the headwear rule, because worn items change in the browser.
- **Assets** are imported into ActiveStorage like the bodies, one `CharacterAsset` per bucket path, so the browser never reads the bucket.

## PR stack
Branches: `feat/6123-character-import` (PR 1) ← `feat/6123-character-upload` (PR 2) ← `feat/6123-dressing-room-chf-character-head` (PRs 3–5, carries this plan).

1. **Import**:
   - Face library files on `CharacterBody` (`face_index`, `face_positions`, `face_normals`), plus the `face_library` id and `skin_tone` columns, through `CharacterBodiesImportJob`.
   - `CharacterAsset` (path, etag, file) and `CharacterAssetsImportJob` for `characters/chf/**` (catalogue and textures; no tests, README or .py) and `characters/<body>/chf/**`.
   - `GET /character-bodies` returns the face library URLs and the skin tone.
2. **Upload and resolve:**
   - the `zstd-ruby` gem; a `Chf::Reader` (container, face block, ports, materials) and `Chf::Resolver` (catalogue → spec, materials per section 4);
   - both checked against every `character.json`;
   - `CharacterFace` model (raw file, stamp, gender hash, format version, game version, body, token, resolved spec);
   - CRUD API, raw download, public read by token, `Outfit#character_face`;
   - headwear data per equipment from `catalog.headwear_items`.
3. **Face blend in the browser:** decode the library, apply it to body.glb meshes 1–3 and the head normals; vitest against `faces/tests` within 1e-5 m.
4. **Accessories and materials:**
   - head binding (`_head_idx` / `_head_w`), materials from the spec, strand variation;
   - skin tone on head and body; the eye shader;
   - head composite in a canvas;
   - the headwear rule and the face_wrap hat fit;
   - vitest against `samples.json`.
5. **UI:** face picker (upload, rename, delete, download), outfit and share link `face=<token>`, every locale.

## Intent Verification

- [ ] **Upload stores the raw file plus metadata** — byte-identical download; stamp, gender hash, version and game version saved
- [ ] **Shared outfit shows the face** — an anonymous visitor to the share link sees the head and can download the `.chf`
- [ ] **Blend matches test vectors** — within 1e-5 m on every face vector, eyes and teeth included
- [ ] **Accessories and materials match** — `samples.json`: positions within 1e-5 m, colours within 1/255, composite within 2/255
- [ ] **Headwear** — the helmet, hat, bandana and mask vectors resolve to the same hidden ports and variants
- [ ] **Edge cases** — v7 neck, absent ids, material-only preset, other body or broken file refused

## Key files

| File | Role |
|------|------|
| `app/lib/sc_data/character_store.rb` | reads `characters/index.json` |
| `app/jobs/sc_data/character_bodies_import_job.rb` | attaches body files to `CharacterBody` |
| `app/lib/sc_data/render_import.rb` | MD5-checked fetch and attach |
| `app/lib/sc_data/object_store.rb` | `remote_objects` (etag listing) |
| `app/models/character_body.rb`, `app/models/outfit.rb` | body and saved-outfit models |
| `app/controllers/api/v1/character_bodies_controller.rb`, `outfits_controller.rb` | APIs |
| `app/api_components/v1/schemas/dressing_room/` | OpenAPI schemas |
| `app/controllers/active_storage/base_controller.rb` | direct-upload content types (`.chf` is octet-stream) |
| `app/frontend/frontend/pages/tools/dressing-room.vue` | page, URL state, share link |
| `app/frontend/frontend/utils/dressingRoom.ts` | `riggedOutfitModel`, `bodyHolo` |
| `app/frontend/shared/components/HoloViewer/rig.ts`, `Model/index.vue` | grafting, posing, rig loading |

## Not in scope (deferred)
- none

## Discovery Log

- **2026-11-08** Initial research:
  - nothing for `.chf` or faces exists;
  - bodies and rigs come in through the sc_data import into ActiveStorage;
  - share links are URL-only;
  - the spec is not in the sc-tools repo, only in the bucket.
- **2026-11-08** Parity, measured locally against the full published vectors:
  - Ruby reader and resolver: all 20 `character.json` vectors, worn headwear included;
  - face blend: all 8 face vectors, at most 1.2e-7 m on positions and 1.3e-6 on normals;
  - head composite: all 12 vectors within 1/255;
  - headwear rule: all 7 worn cases.
  CI checks sampled fixtures: every 89th head vertex re-encoded as a small library, the composite's input texels at the reference's sample points, and the resolver vectors with a trimmed catalogue.
- **2026-11-08** The request-validation middleware cannot see a multipart body Rack already parsed, so the upload's request body is declared optional and the controller requires the file.
- **2026-11-08** Spec v2 read:
  - headwear variants and the face_wrap hat fit are already published;
  - `character.json` is the full resolved character, so the Ruby resolver has an exact target;
  - accessory, skin and texture files have no md5 listing, so ETags decide.

## Progress
- [x] PR 1 Import
- [x] PR 2 Upload and resolve
- [x] PR 3 Face blend
- [x] PR 4 Accessories and materials
- [x] PR 5 UI
- [x] Local end-to-end check with the imported export (all 13 game files resolve against the live export, every asset served)
- [x] Review (two local rounds)
- [ ] Visual check on a running dev server
