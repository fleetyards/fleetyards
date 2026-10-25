# Make the equipment filters usable

Decisions and acceptance criteria: https://github.com/fleetyards/fleetyards/issues/5967

## Phases

1. [x] Parser: worn item types from the garment / armour weight segment; `gren`, weapon mount prefix; drop the retired labels.
2. [ ] Parser: personal gadgets (`WeaponPersonal` + SubType `Gadget`, the ParaMed) become equipment type `tool`.
3. [ ] Inventory categories armor, clothing, tool, container: enum, units, backend equipment-type mapping, hangar pledge deposits, schema regen, labels in seven locales.
4. [ ] Frontend: `INVENTORY_EQUIPMENT_TYPES` slices, picker Slot select.
5. [ ] Filter endpoints: slot, weapon class, sub type narrowed by `equipment_type_in`; equipment page passes the types and prunes.
6. [ ] Lint, targeted tests, PR, review.

## Key files

- `app/lib/sc_data/parser/equipment_parser.rb`
- `app/models/concerns/inventory_ledger_entry.rb`, `app/models/hangar_pledge_item.rb`
- `app/models/equipment.rb`, `app/controllers/api/v1/filters/equipment_controller.rb`
- `app/frontend/frontend/composables/useInventoryOptions.ts`
- `app/frontend/frontend/components/Logistics/ItemPicker/index.vue`
- `app/frontend/frontend/components/Equipment/FilterForm/index.vue`

## Discovery log

- Raw 4.10.2 parse after phase 1: every clothing record gets a garment; only the two mannequin display props stay untyped.
- Inventory positions carry `name--category--unit` as a published slug, which is why existing entries are not re-filed.
- The hangar "add to inventory" action is keyed by the pledge item, so a changed category never re-deposits.
- The parser change needs a re-parse before production sees it.
