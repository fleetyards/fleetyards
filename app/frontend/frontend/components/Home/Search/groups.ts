type SearchGroupConfig = {
  // What heads the group: the list's own name in the nav.
  labelKey: string;
  // Where the group lists everything, and the filter that narrows it by name.
  // Ships take the name filter over their wider header search because it is the
  // one their filter form shows.
  list: { name: string; filter: string };
  // The list pages this group leads on. An item's own page keeps the ranking.
  listPages: string[];
};

const group = (
  labelKey: string,
  name: string,
  filter: string,
  listPages: string[] = [name],
): SearchGroupConfig => ({ labelKey, list: { name, filter }, listPages });

export const SEARCH_GROUPS: Record<string, SearchGroupConfig> = {
  Model: group("nav.ships.index", "ships", "nameCont"),
  Component: group("nav.catalogue.components", "components", "searchNameCont"),
  Equipment: group("nav.catalogue.equipment", "equipment", "nameOrSlugCont"),
  Commodity: group("nav.catalogue.commodities", "commodities", "nameCont"),
  Blueprint: group("nav.catalogue.blueprints", "blueprints", "nameCont", [
    "blueprints",
    "hangar-blueprints",
  ]),
  GameMission: group("nav.catalogue.missions", "missions", "nameCont"),
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
  ),
};
