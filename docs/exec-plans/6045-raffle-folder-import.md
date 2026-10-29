# Import a raffle's texts and images from one folder

Working plan for #6045. Decisions live in the issue body. Deleted before the PR merges.

## Goal

The admin raffle form fills every language and the gallery from one picked folder.

## What changed

### Phase 1 — Parse the folder
1. `Raffles/Form/folderImport.ts`: split the picked files into one text per locale (front matter `title` / `prize`, body as description), images in file-name order, and the files it skipped.

### Phase 2 — Fill the form
1. Gallery exposes `addFiles`, which direct-uploads and appends.
2. Form gets an Import folder button with a hidden `webkitdirectory` input; it sets the fields, hands images to the gallery and reports what it took.
3. Labels and messages in all seven locales.

### Phase 3 — Tests
1. Parser spec; form spec for the filled fields.

## Intent Verification

- [ ] Picking the Centaurus folder fills title, prize, description and six tabs, and adds the images with the first as cover
- [ ] Nothing is saved until the admin saves

## Key files

| File | Role |
|------|------|
| `app/frontend/admin/components/Raffles/Form/index.vue` | Import button, fills fields |
| `app/frontend/admin/components/Raffles/Form/folderImport.ts` | Folder parser |
| `app/frontend/admin/components/Raffles/Gallery/index.vue` | Uploads imported images |
| `app/frontend/translations/*/raffles.json` | Labels |

## Discovery Log

- **2026-10-29** The form and gallery already cover every field; the import needs no API change.

## Progress
- [ ] Phase 1
- [ ] Phase 2
- [ ] Phase 3
