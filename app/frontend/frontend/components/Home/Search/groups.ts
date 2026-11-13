interface SearchGroupConfig {
  // What heads the group: the list's own name in the nav.
  labelKey: string;
  // Where the group lists everything, and the filter that narrows it by name.
  // Ships take the name filter over their wider header search because it is the
  // one their filter form shows. `view` opens the page on the view that filter
  // applies to.
  list: { name: string; filter?: string; view?: Record<string, string> };
  // The list pages this group leads on. An item's own page keeps the ranking.
  listPages: string[];
}

const group = (
  labelKey: string,
  name: string,
  filter: string | undefined,
  listPages: string[] = [name],
  view?: Record<string, string>,
): SearchGroupConfig => ({ labelKey, list: { name, filter, view }, listPages });

// An inventory page opens on its stock, which no filter narrows; only the log is.
const LEDGER_LOG = { tab: "log" };

export const SEARCH_GROUPS: Record<string, SearchGroupConfig> = {
  Model: group("nav.ships.index", "ships", "nameCont"),
  Component: group("nav.catalogue.components", "components", "searchNameCont"),
  Equipment: group("nav.catalogue.equipment", "equipment", "nameOrSlugCont"),
  Commodity: group("nav.catalogue.commodities", "commodities", "nameCont"),
  Blueprint: group("nav.catalogue.blueprints", "blueprints", "nameCont", [
    "blueprints",
    "hangar-blueprints",
  ]),
  GameMission: group("nav.catalogue.missions", "missions", "nameOrOrgNameCont"),
  Faction: group("nav.catalogue.factions", "factions", undefined),
  Location: group("nav.locations", "locations-places", "nameCont", [
    "locations",
    "locations-places",
  ]),

  HangarVehicle: group("nav.hangar.index", "hangar", "searchCont"),
  WishlistVehicle: group(
    "nav.hangar.wishlist",
    "hangar-wishlist",
    "searchCont",
  ),
  Friend: group("nav.settings.friends", "settings-friends", undefined),
  OwnedBlueprint: group(
    "nav.hangar.blueprints",
    "hangar-blueprints",
    "nameCont",
  ),
  InventoryItem: group(
    "nav.hangar.inventories",
    "hangar-inventories",
    "nameCont",
    ["hangar-inventories", "hangar-inventory"],
    LEDGER_LOG,
  ),
  Paint: group("nav.hangar.paints", "hangar-paints", "nameCont"),
  Flair: group("nav.hangar.flair", "hangar-flair", "nameCont"),
  PledgeEquipment: group(
    "nav.hangar.equipment",
    "hangar-equipment",
    "nameCont",
  ),
  PledgeComponent: group(
    "nav.hangar.shipComponents",
    "hangar-ship-components",
    "nameCont",
  ),
  Upgrade: group("nav.hangar.upgrades", "hangar-upgrades", "nameCont"),
  Buyback: group("nav.hangar.buybacks", "hangar-buybacks", "nameCont"),

  FleetMembership: group(
    "nav.fleets.members.index",
    "fleet-members",
    "searchCont",
  ),
  FleetShip: group("nav.fleets.ships", "fleet-ships", "modelOrSerialCont"),
  FleetBlueprint: group(
    "nav.fleets.blueprints",
    "fleet-blueprints",
    "nameCont",
  ),
  FleetEvent: group("nav.fleets.events.index", "fleet-events", "titleCont"),
  FleetContract: group(
    "nav.fleets.contracts.index",
    "fleet-contracts",
    "titleCont",
  ),
  FleetInventoryItem: group(
    "nav.fleets.logistics.index",
    "fleet-logistics",
    "nameCont",
    ["fleet-logistics"],
    LEDGER_LOG,
  ),
};
