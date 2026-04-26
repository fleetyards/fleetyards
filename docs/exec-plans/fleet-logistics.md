# Fleet Logistics

Resolves #3788

Fleet logistics adds a multi-inventory management system to fleets. Logistics officers manage named inventories with deposit/withdrawal ledger tracking. Each inventory entry is immutable — deposits add stock, withdrawals subtract, and the current stock is computed by aggregation.

## Current State (Iteration 1)

### Backend
- `FleetInventory` — named inventory with location, description, visibility, managed_by (single user)
- `FleetInventoryItem` — immutable ledger entries with entry_type (deposit/withdrawal), quantity, category, unit, member (who handled items), added_by (who logged it)
- Stock aggregation endpoints: per-inventory and fleet-wide (SQL SUM with CASE on entry_type)
- Withdrawal validation: rejects if quantity exceeds current net stock
- CSV import for bulk deposits
- Notification on new inventory item creation
- Privilege system: `fleet:inventories:read/create/update/delete/manage`
- Rake task for adding inventory privileges to existing roles

### Frontend
- Logistics nav tab with fleet route check integration
- Main logistics page: stock/log tab toggle (BtnGroup), BaseTable with sortable columns
- Inventories list: ListGroup with clickable rows showing name, location, item count, manager
- Inventory detail: stock/log tabs, deposit/withdraw/CSV import/edit buttons in page-actions
- InventoryModal: create + edit mode with name, description, location, visibility, managed_by (member search)
- InventoryItemModal: deposit/withdrawal toggle, stock item picker for withdrawals (auto-fills name/category/unit), member search, quantity with unit suffix select
- InventoryItemFilterForm: search teleported to header, category FilterGroup
- Translations for all 7 locales

## Next Iteration — Planned Features

### 1. Custom Inventory Panels with Image Uploads
- Build inventory panels similar to the model/vehicle panels
- Display inventories in a grid layout like the ships page
- Add image upload support (logo/cover image) to FleetInventory using ActiveStorage
- Panel shows inventory name, location, image, item count, manager

### 2. Filter Forms for All Pages
- Add InventoryItemFilterForm (with header search) to the main logistics page
- Add InventoryItemFilterForm to the inventory detail page
- Filter by category, entry_type, name search
- Ransack-based server-side filtering via route query params

### 3. Deposit/Withdrawal Request Workflow
Members can request a deposit or withdrawal, which creates a request entry that goes through approval:

**Flow:**
1. Member creates a deposit or withdrawal request (selects item, quantity, notes)
2. Request notification sent to inventory manager / logistics officers
3. Logistics officer reviews: **accept** or **deny**
   - **Deny**: Request closed, member notified
   - **Accept**: Creates a pending inventory item (deposit or withdrawal)
4. Pending item needs **confirmation** once the in-game transaction is complete
5. On confirmation: inventory item becomes active, stock updates

**Model: `FleetInventoryRequest`**
- fleet_inventory_id, requester_id, entry_type (deposit/withdrawal)
- item name, category, quantity, unit, notes
- AASM states: pending → accepted/denied → confirmed/cancelled
- accepted_by, confirmed_by, denied_by (user references)

**Notifications:**
- New request → inventory manager + logistics officers
- Request accepted/denied → requester
- Request confirmed → inventory manager

This gives logistics officers control over what enters/leaves inventory while letting members initiate the process.

## Discovery Log

- **2025-04-25** Initial exec plan with full request/comment system
- **2025-04-26** Stripped to inventory-only for iteration 1
- **2025-04-26** Added deposit/withdrawal ledger with stock aggregation
- **2025-04-26** Added member field, location field, edit inventories, stock/log tabs
- **2025-04-26** Documented next iteration: panels, filters, request workflow
