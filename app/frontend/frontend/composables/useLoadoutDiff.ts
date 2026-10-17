import { useI18n } from "@/shared/composables/useI18n";
import { UNINFORMATIVE } from "@/frontend/composables/useModuleContents";
import {
  type CompareDelta,
  deltasAgainst,
} from "@/frontend/components/Compare/delta";
import type { CompareDirection } from "@/frontend/components/Compare/highlights";
import {
  type ComponentTab,
  type FittedSlot,
  useComponentFitting,
} from "@/frontend/composables/useComponentFitting";
import {
  type FittingMeasure,
  type LoadoutMetric,
  type LoadoutMetricsCard,
  TAB_METRICS,
  useLoadoutMetrics,
} from "@/frontend/composables/useLoadoutMetrics";
import {
  type ComponentController,
  type Hardpoint,
  HardpointCategoryEnum,
  type ModelModule,
} from "@/services/fyApi";

// What a fitting adds up to on the ship, by metric.
export type FittingMetrics = Map<string, number>;

export type FittingRow = {
  key: string;
  label: string;
  before: number;
  after: number;
  value: string;
  delta?: CompareDelta;
  deltaLabel?: string;
};

export const CARGO = "cargo";
const RESPAWN_BEDS = "respawn_beds";
const MEDICAL_BEDS = "medical_beds_tier_";
const NAMED_MEDICAL_BEDS = "medical_beds_named_";

// Directions as the compare tool sets them: more cargo is better, and so are
// more beds to respawn at; how many hardpoints of a kind a module brings, or
// beds of a tier, is neither better nor worse.
const DIRECTIONS: Record<string, CompareDirection | undefined> = {
  [CARGO]: "higher",
  [RESPAWN_BEDS]: "higher",
};

const add = (totals: FittingMetrics, key: string, amount: number) =>
  totals.set(key, (totals.get(key) || 0) + amount);

// A whole fitting as the ship carries it: the modules, and the component tree
// grafted onto the ship's own hardpoints.
export interface LoadoutFitting {
  hullCargo: number;
  modules: ModelModule[];
  // The ship's hardpoints, before the fitting is grafted onto them.
  hardpoints: Hardpoint[];
  tree: FittedSlot[];
  weaponPoolSize?: number;
}

// One fitting, measured once, so two can be compared card by card without
// measuring either again.
export interface LoadoutMeasure {
  modules: FittingMetrics;
  ship?: FittingMeasure;
  tree: FittedSlot[];
}

// What a fitting changed against another: the modules' figures, each metrics
// card's, each tab's own, and every figure that moved.
export interface LoadoutDiff {
  modules: LoadoutMetric[];
  cards: Partial<Record<LoadoutMetricsCard, LoadoutMetric[]>>;
  tabs: Record<string, LoadoutMetric[]>;
  changed: LoadoutMetric[];
}

const CARDS = [...new Set(Object.values(TAB_METRICS))];

// The tabs whose parts' own figure no card leads with -- a radar's assist
// range, a drive's speed -- which their tab shows ahead of the card's.
const OWN_FIGURE_TABS = ["radar", "coolers", "lifeSupport", "quantumDrives"];

// Draw and signatures are the power card's to show, summed for the whole ship.
const CARD_FIGURES = new Set([
  "powerConsumption",
  "signatureEm",
  "signatureIr",
]);

/**
 * The ship's figures under a fitting and the change from one fitting to
 * another, read the way the compare tool reads two ships: a value, a signed
 * difference and whether that is better or worse. Cargo is the hull's hold
 * plus what the modules carry; hardpoints are what the modules bring.
 * Components are measured by the ship page's own stats -- power, cooling,
 * shields, damage, speed -- so every view of a loadout reads what the ship
 * page would.
 *
 * `fitting` is the caller's, whose trees these are.
 */
export const useLoadoutDiff = (fitting = useComponentFitting()) => {
  const { t, toNumber } = useI18n();

  const { measure: measureShip, metrics: cardMetrics } = useLoadoutMetrics();

  const metrics = (hullCargo: number, modules: ModelModule[]) => {
    const totals: FittingMetrics = new Map([[CARGO, hullCargo]]);

    modules.forEach((mod) => {
      totals.set(CARGO, (totals.get(CARGO) || 0) + (mod.metrics?.cargo || 0));

      (mod.hardpoints || []).forEach((hardpoint) => {
        const category = hardpoint.category;
        if (!category || UNINFORMATIVE.includes(category)) {
          return;
        }

        add(totals, category, 1);
      });

      // A tier the game names but does not rank is kept apart by its name.
      const medicalBeds = mod.metrics?.medicalBeds;
      if (medicalBeds) {
        medicalBeds.tiers.forEach((tier) => {
          const key =
            tier.tier === null
              ? `${NAMED_MEDICAL_BEDS}${tier.name}`
              : `${MEDICAL_BEDS}${tier.tier}`;
          add(totals, key, tier.beds);
        });
        add(totals, RESPAWN_BEDS, medicalBeds.respawnBeds);
      }
    });

    return totals;
  };

  const labelFor = (key: string) => {
    if (key === CARGO) return t("labels.model.cargo");
    if (key === RESPAWN_BEDS) return t("labels.model.respawnBeds");
    if (key.startsWith(MEDICAL_BEDS)) {
      return t("labels.model.medicalBedsTier", {
        tier: key.slice(MEDICAL_BEDS.length),
      });
    }
    if (key.startsWith(NAMED_MEDICAL_BEDS)) {
      return t("labels.model.medicalBedsNamed", {
        name: key.slice(NAMED_MEDICAL_BEDS.length),
      });
    }

    return t(`labels.hardpoint.categories.${key}`);
  };

  const format = (key: string, amount: number) =>
    key === CARGO ? String(toNumber(amount, "cargo")) : String(amount);

  const signed = (key: string, difference: number) =>
    `${difference > 0 ? "+" : "−"}${format(key, Math.abs(difference))}`;

  // Every metric either fitting has, cargo first; a metric neither touches
  // is left out rather than listed as "no change".
  const rows = (before: FittingMetrics, after: FittingMetrics): FittingRow[] =>
    [...new Set([...before.keys(), ...after.keys()])]
      .filter((key) =>
        key === CARGO ? before.get(key) || 0 || after.get(key) || 0 : true,
      )
      .sort((a, b) => (a === CARGO ? -1 : b === CARGO ? 1 : a.localeCompare(b)))
      .map((key) => {
        const from = before.get(key) || 0;
        const to = after.get(key) || 0;
        const [, delta] = deltasAgainst([from, to], 0, DIRECTIONS[key], true);

        return {
          key,
          label: labelFor(key),
          before: from,
          after: to,
          value: format(key, to),
          delta,
          deltaLabel: delta?.difference
            ? signed(key, delta.difference)
            : undefined,
        };
      });

  // The flight blade a tree holds, whose speeds the flight figures read.
  const bladeIn = (tree: FittedSlot[]) =>
    tree.find(
      (entry) => entry.slot.category === HardpointCategoryEnum.CONTROLLER,
    )?.content?.typeData as ComponentController | undefined;

  const measure = (loadout: LoadoutFitting): LoadoutMeasure => ({
    modules: metrics(loadout.hullCargo, loadout.modules),
    ship: loadout.hardpoints.length
      ? measureShip(
          {
            hardpoints: fitting.graft(loadout.hardpoints, loadout.tree),
            blade: bladeIn(loadout.tree),
          },
          loadout.weaponPoolSize,
        )
      : undefined,
    tree: loadout.tree,
  });

  const asMetric = ({
    key,
    label,
    value,
    deltaLabel,
    tone,
  }: LoadoutMetric): LoadoutMetric => ({ key, label, value, deltaLabel, tone });

  const diff = (
    before: LoadoutMeasure,
    after: LoadoutMeasure,
    tabs: ComponentTab[],
  ): LoadoutDiff => {
    const modules = rows(before.modules, after.modules).map((row) =>
      asMetric({ ...row, tone: row.delta?.tone }),
    );

    const cards = Object.fromEntries(
      CARDS.map((card) => [
        card,
        after.ship && before.ship
          ? cardMetrics(card, after.ship, before.ship)
          : [],
      ]),
    ) as Partial<Record<LoadoutMetricsCard, LoadoutMetric[]>>;

    const own = (tab: ComponentTab) =>
      OWN_FIGURE_TABS.includes(tab.id)
        ? fitting
            .tabFigures(after.tree, before.tree, tab)
            .filter((figure) => !CARD_FIGURES.has(figure.key))
            .map(asMetric)
        : [];

    const tabFigures = Object.fromEntries(
      tabs.map((tab) => [
        tab.id,
        [...own(tab), ...(cards[TAB_METRICS[tab.id]] ?? [])],
      ]),
    );

    const all = [
      ...modules,
      ...CARDS.flatMap((card) => cards[card] ?? []),
      ...tabs.flatMap(own),
    ].filter((figure) => figure.deltaLabel);

    return {
      modules,
      cards,
      tabs: tabFigures,
      changed: all.filter(
        (figure, index) =>
          all.findIndex((other) => other.key === figure.key) === index,
      ),
    };
  };

  return { metrics, rows, measure, diff };
};
