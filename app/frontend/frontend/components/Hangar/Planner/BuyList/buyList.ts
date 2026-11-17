import {
  type HangarPlanModel,
  type HangarPlanSlot,
  HangarPlanSlotStateEnum,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
} from "@/services/fyApi";

export const buyListSections = ["ccus", "buybacks", "ships", "ingame"] as const;

export type BuyListSection = (typeof buyListSections)[number];

export interface BuyListEntry {
  key: string;
  section: BuyListSection;
  // Set on an upgrade: the ship it leads from.
  fromModel?: HangarPlanModel;
  model: HangarPlanModel;
  // Per unit, in USD; null when unknown.
  price: number | null;
  quantity: number;
  slotLabels: string[];
  notOnSale: boolean;
  usesBuybackToken: boolean;
}

export interface BuyListGroup {
  section: BuyListSection;
  entries: BuyListEntry[];
  total: number;
  hasUnknownPrice: boolean;
}

type Purchase = Omit<BuyListEntry, "key" | "quantity" | "slotLabels">;

const startSections: Partial<Record<string, BuyListSection>> = {
  [HangarPlanStartKindEnum.STORE]: "ships",
  [HangarPlanStartKindEnum.BUYBACK]: "buybacks",
  [HangarPlanStartKindEnum.MELTED]: "buybacks",
  [HangarPlanStartKindEnum.INGAME]: "ingame",
};

const stepSections: Partial<Record<string, BuyListSection>> = {
  [HangarPlanUpgradeSourceEnum.STORE]: "ccus",
  [HangarPlanUpgradeSourceEnum.BUYBACK]: "buybacks",
};

// What a decided slot's route still has to buy. Only finished routes count, as
// in the plan's costs: a route still being planned has no settled purchases.
// Ships kept from the hangar, upgrades already held and ships bundled with a
// buy-back cost nothing more.
const purchasesOf = (slot: HangarPlanSlot): Purchase[] => {
  if (slot.state !== HangarPlanSlotStateEnum.DECIDED) return [];

  const acquisition = slot.candidates[0]?.acquisitions[0];
  if (!acquisition?.routeComplete) return [];

  const purchases: Purchase[] = [];

  const startSection = startSections[acquisition.startKind];
  if (startSection) {
    purchases.push({
      section: startSection,
      model: acquisition.startModel,
      price: acquisition.price ?? null,
      notOnSale: startSection === "ships" && !acquisition.startModel.onSale,
      usesBuybackToken: acquisition.usesBuybackToken,
    });
  }

  acquisition.steps.forEach((step) => {
    const section = stepSections[step.sourceKind];
    if (!section) return;

    purchases.push({
      section,
      fromModel: step.fromModel,
      model: step.toModel,
      price: step.price ?? null,
      notOnSale: section === "ccus" && !step.toModel.onSale,
      usesBuybackToken: step.usesBuybackToken,
    });
  });

  return purchases;
};

const keyOf = (purchase: Purchase) =>
  [
    purchase.section,
    purchase.fromModel?.id ?? "",
    purchase.model.id,
    purchase.price ?? "unknown",
    purchase.usesBuybackToken,
  ].join(":");

// The same purchase made for several slots is one line bought several times.
export const buildBuyList = (slots: HangarPlanSlot[]): BuyListGroup[] => {
  const entries = new Map<string, BuyListEntry>();

  slots.forEach((slot) => {
    purchasesOf(slot).forEach((purchase) => {
      const key = keyOf(purchase);
      const entry = entries.get(key);

      if (entry) {
        entry.quantity += 1;
        if (!entry.slotLabels.includes(slot.label)) {
          entry.slotLabels.push(slot.label);
        }
      } else {
        entries.set(key, {
          ...purchase,
          key,
          quantity: 1,
          slotLabels: [slot.label],
        });
      }
    });
  });

  return buyListSections
    .map((section) => {
      const sectionEntries = [...entries.values()].filter(
        (entry) => entry.section === section,
      );

      return {
        section,
        entries: sectionEntries,
        total: sectionEntries.reduce(
          (sum, entry) => sum + (entry.price ?? 0) * entry.quantity,
          0,
        ),
        hasUnknownPrice: sectionEntries.some((entry) => entry.price === null),
      };
    })
    .filter((group) => group.entries.length > 0);
};
