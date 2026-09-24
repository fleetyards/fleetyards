# Contract authors choose the delivery inventory, including their own hangar

## Goal

The author of a fleet contract picks where its goods are delivered. That is either a fleet inventory
they may write to, or one of their own hangar inventories. Contractors deliver into a hangar
destination with a transfer addressed to the author, and the author accepts it themselves. Progress and
fulfilment work the same for both kinds of destination.

## Context

Resolves #5194.

`FleetContract` requires a `destination_fleet_inventory`. A delivery by a contractor without
inventory-write rights becomes a pending transfer addressed to the fleet. Accepting it needs
`fleet:manage`, `fleet:inventories:manage` or `fleet:inventories:update`
(`Inventories::TransferAuthorizer#may_answer_for?`). Creating a contract only needs
`fleet:contracts:create`, so an author without inventory rights cannot accept deliveries against their
own contract.

The relevant pieces:
- `Contracts::TransferLink` decides whether a transfer may be filed under a contract.
- `Contracts::Progress` sums the deposits the linked transfers wrote into the destination. Today it
  reads only `FleetInventoryItem`.
- `Inventories::TransferBuilder` turns a request into an immediate transfer, or into a pending one
  addressed to a party.

## Decisions

The decisions are recorded in the issue body (#5194, "Decisions"). They are not restated here:

- D1: schema, a second nullable FK `destination_inventory_id`
- D2: who may pick which destination, including authors with rights picking their own hangar
- D3: how the rule is enforced
- D4: delivering into a hangar destination
- D5: the transfer gate
- D6: API shape

## What changed

### Phase 1: Schema and model
- Migration: `fleet_contracts.destination_inventory_id` (uuid, FK `inventories`, ON DELETE SET NULL,
  indexed), plus a check constraint allowing at most one destination.
- `FleetContract` changes:
  - `belongs_to :destination_inventory`, with `#destination` and `#destination_party` readers;
  - exactly-one validation, and a hangar destination must be held by `created_by`;
  - `destination_chosen_by`: the editor whose fleet-inventory rights are checked when the destination
    changes;
  - `same_as_source`, `tracked_inventory_ids`, `ready_to_publish?` and the ransack associations updated.
- `Contracts::DestinationOptions`: which fleet inventories and hangar inventories an editor may pick.

### Phase 2: Progress, link and transfer authorization
- `Contracts::Progress` rolls up whichever ledger the destination keeps (`InventoryItem` or
  `FleetInventoryItem`), both per contract and batched for a page.
- `Contracts::TransferLink#touches_contract?` accepts a transfer addressed to the author of a
  hangar-destination contract, but only from an accepted contractor.
- `InventoryTransferActions#find_destination` resolves the contract's hangar destination when the
  request names that contract.
- `TransferBuilder` addresses such a delivery to the author, and waives the gate's policy stance for it.

### Phase 3: API and schema
- The jbuilder `destination` handles either kind and gains `holder`. The transfer's `contract` ref gains
  `destinationInventoryId`.
- `FleetContractInput` gains `destinationInventoryId`, and `destinationFleetInventoryId` becomes
  nullable.
- New endpoints:
  - `GET /fleets/{fleetSlug}/contract-destinations`: the destinations the caller may pick.
  - `GET /hangar/contract-destinations`: the contract destinations the caller can deliver to.
- Components, integration tests, regenerated swagger.

### Phase 4: Contract form and display
- `ContractForm`: one destination picker over the options endpoint. The value is prefixed by holder, and
  submit maps it to the right id field.
- Panel, table and detail page mark a hangar destination.

### Phase 5: Transfer form
- `useTransferTargets` gains a `contract` kind when sending as oneself. It is read from
  `/hangar/contract-destinations`, and its payload carries `contractId`.
- The accept modal preselects the contract's hangar destination.

## Intent Verification

- An author without inventory rights creates a contract targeting their hangar inventory. A contractor
  claims it and delivers. The author accepts, progress counts the delivery, and the contract fulfils.
- A non-contractor cannot target that inventory.
- An author cannot pick a fleet inventory without rights, or someone else's hangar inventory.
- The contractor gains no read access to the author's inventory.

## Key files

- `app/models/fleet_contract.rb`, `app/lib/contracts/{progress,transfer_link,destination_options}.rb`
- `app/services/inventories/{transfer_builder,transfer_gate}.rb`,
  `app/controllers/concerns/inventory_transfer_actions.rb`
- `app/controllers/api/v1/fleet_contracts_controller.rb`, the new destinations controllers
- `app/views/api/v1/fleet_contracts/*`, `app/views/api/v1/shared/_inventory_transfer.jbuilder`
- `app/api_components/v1/schemas/{contracts,inputs,enums}/*`
- `app/frontend/frontend/components/Fleets/Contracts/*`,
  `app/frontend/frontend/components/Logistics/*`, `app/frontend/frontend/composables/useTransferTargets.ts`

## Not in scope

- A transport contract's `source_fleet_inventory` stays as it is. Only the destination can be a hangar
  inventory.
- Moving fleet inventories onto the unified `inventories` table (planned separately). D1 is chosen so
  that refactor can migrate this column the same way it migrates `inventory_transfers`.
- Forcing an accepted delivery into the contract's destination. As with fleet destinations, goods
  accepted elsewhere simply do not count.

## Discovery Log

- `InventoryTransfer` already has the typed FK pair (`destination_inventory_id` /
  `destination_fleet_inventory_id`), which is the precedent for D1.
- A pending transfer never carries a destination. The resolver sets it on acceptance and checks that
  it belongs to the recipient party. So addressing the author and not storing the inventory keeps the
  contractor out of it.
- The response already models the destination as a nullable `FleetContractEndpoint`, so no response
  property has to become nullable.
- A disabled vue-query query still returns data an earlier query cached. The transfer form's contract
  targets and its contract picker both guard on their own condition, not only on `enabled`.
- `publish?` needs `fleet:contracts:update`, so an author holding only `fleet:contracts:create` can
  write a draft but not publish it. That is how things already were, and it is left alone. The flow test
  gives its author both privileges and no inventory rights.
- The contract jbuilder cache key moved to `v3`, because entries cached before the change have no
  `holder`.

## Progress

- [x] Phase 1: Schema and model
- [x] Phase 2: Progress, link and transfer authorization
- [x] Phase 3: API and schema
- [x] Phase 4: Contract form and display
- [x] Phase 5: Transfer form
