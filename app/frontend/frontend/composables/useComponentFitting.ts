import type {
  LoadoutSocketGroup,
  LoadoutSocketSlot,
} from "@/frontend/components/Loadout/Socket/types";
import type {
  LoadoutPickerOption,
  LoadoutPickerSort,
} from "@/frontend/components/Loadout/Picker/types";
import type { CompareDeltaTone } from "@/frontend/components/Compare/delta";
import {
  type HardpointStat,
  useHardpointStatsFor,
} from "@/frontend/composables/useHardpointStats";
import type { LoadoutSimResult } from "@/frontend/composables/useLoadoutSim";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Component,
  type Hardpoint,
  HardpointCategoryEnum,
  type LoadoutComponentRef,
  type LoadoutOption,
  type LoadoutSlot,
} from "@/services/fyApi";

export interface ComponentTab {
  id: string;
  // The hull slots the tab lists, by category; everything below them follows.
  categories: HardpointCategoryEnum[];
}

export const COMPONENT_TABS: ComponentTab[] = [
  { id: "radar", categories: [HardpointCategoryEnum.RADAR] },
  { id: "coolers", categories: [HardpointCategoryEnum.COOLER] },
  { id: "lifeSupport", categories: [HardpointCategoryEnum.LIFESUPPORT] },
  { id: "powerPlants", categories: [HardpointCategoryEnum.POWERPLANT] },
  { id: "shields", categories: [HardpointCategoryEnum.SHIELDGENERATOR] },
  { id: "quantumDrives", categories: [HardpointCategoryEnum.QUANTUMDRIVE] },
  { id: "flightBlades", categories: [HardpointCategoryEnum.CONTROLLER] },
  { id: "missiles", categories: [HardpointCategoryEnum.MISSILE_RACKS] },
  {
    id: "weapons",
    categories: [
      HardpointCategoryEnum.WEAPONS,
      HardpointCategoryEnum.WEAPON_MOUNTS,
      HardpointCategoryEnum.TURRET,
    ],
  },
];

// A slot of the fitting as it stands in the form: the slot, what sits in it,
// and the slots that part brings.
export interface FittedSlot {
  path: string;
  slot: LoadoutSlot;
  content?: LoadoutComponentRef;
  children: FittedSlot[];
}

export const slotName = (name: string) =>
  name
    .replace(/^hardpoint_/, "")
    .replace(/_/g, " ")
    .trim()
    .replace(/\b\w/g, (char) => char.toUpperCase());

// The game's own words for what a part is, `QuantumDrive` read as "Quantum
// Drive"; the sub type where it says more than "UNDEFINED".
const typeName = (component: LoadoutComponentRef) => {
  const name =
    component.subType && component.subType !== "UNDEFINED"
      ? component.subType
      : component.type;

  return name?.replace(/([a-z])([A-Z])/g, "$1 $2");
};

// A figure a part is ranked on, with what it reads before and after a swap.
export interface FigureChange {
  key: string;
  label: string;
  value: string;
  before?: number;
  after?: number;
  deltaLabel?: string;
  tone?: CompareDeltaTone;
}

// Times, delays, draws, signatures and fuel read better smaller; everything
// else a part is ranked on reads better larger.
const LOWER_IS_BETTER = /(time|delay|consumption|signature|spread|heat|cost)$/i;

const lowerIsBetter = (key: string) => LOWER_IS_BETTER.test(key);

// What the ship has of it across every slot, as opposed to a speed or a time,
// which a second part does not add to.
const ADDITIVE = new Set([
  "shields.hp",
  "shields.regen",
  "powerPlants.output",
  "coolers.coolingRate",
  "lifeSupport.output",
  "weapons.burstDps",
  "weapons.sustainedDps",
  "weapons.dps",
  "missiles.damage",
  "powerConsumption",
  "signatureEm",
  "signatureIr",
]);

const sizeLabel = (slot: LoadoutSlot) => {
  if (slot.maxSize === undefined) return undefined;

  return slot.minSize !== undefined && slot.minSize !== slot.maxSize
    ? `S${slot.minSize}–${slot.maxSize}`
    : `S${slot.maxSize}`;
};

/**
 * The component slots of a fitting, resolved in the browser from what the
 * server has already said: the hull's tree with its stock parts, the saved
 * loadout's tree, and the ports each picked option brings. A slot's children
 * depend only on its path and the part in it, so each answer is kept by both,
 * and swapping a mount back and forth needs no request.
 *
 * A slot nothing is fitted to keeps its stock part, as the server reads it.
 */
export const useComponentFitting = () => {
  const { t, toNumber } = useI18n();

  const statsFor = useHardpointStatsFor();

  // A part read the way the ship page reads it in its slot: the headline
  // first, then the figures its row shows, each with the number behind it.
  const stats = (
    component: LoadoutComponentRef | undefined,
    category?: HardpointCategoryEnum,
  ): HardpointStat[] => {
    if (!component?.typeData) return [];

    const all = statsFor({
      category: (component.category as HardpointCategoryEnum) || category,
      component,
      hardpoints: [],
    } as unknown as Hardpoint).filter((stat) => typeof stat.raw === "number");

    const primary = all.find((stat) => stat.primary);
    const rows = all
      .filter((stat) => stat !== primary && typeof stat.row === "number")
      .sort((a, b) => (a.row ?? 0) - (b.row ?? 0));

    return primary ? [primary, ...rows] : rows;
  };

  const change = (
    key: string,
    before?: number,
    after?: number,
  ): Pick<FigureChange, "deltaLabel" | "tone"> => {
    if (before === undefined || after === undefined || before === after) {
      return {};
    }

    const difference = after - before;
    const better = lowerIsBetter(key) ? difference < 0 : difference > 0;
    const deltaLabel = before
      ? `${difference > 0 ? "+" : "−"}${Math.round(Math.abs(difference / before) * 100)}%`
      : `${difference > 0 ? "+" : "−"}${String(toNumber(Math.abs(difference)))}`;

    return { deltaLabel, tone: better ? "better" : "worse" };
  };

  // Every figure either part is ranked on, from what the slot holds to what it
  // would hold.
  const compare = (
    from: LoadoutComponentRef | undefined,
    to: LoadoutComponentRef | undefined,
    category?: HardpointCategoryEnum,
  ): FigureChange[] => {
    const before = stats(from, category);
    const after = stats(to, category);
    const keys = [
      ...new Set([...after, ...before].map((stat) => stat.key ?? "")),
    ].filter(Boolean);

    return keys.map((key) => {
      const was = before.find((stat) => stat.key === key);
      const now = after.find((stat) => stat.key === key);

      return {
        key,
        label: (now || was)?.label ?? key,
        value: now?.value ?? "–",
        before: was?.raw,
        after: now?.raw,
        ...change(key, was?.raw, now?.raw),
      };
    });
  };

  // What a part brings, in a word: its headline figure.
  const headline = (
    component: LoadoutComponentRef | undefined,
    category?: HardpointCategoryEnum,
  ) => {
    const primary = stats(component, category)[0];

    return primary ? `${primary.value} ${primary.label}` : undefined;
  };

  const headlineOf = (
    component: LoadoutComponentRef,
    category?: HardpointCategoryEnum,
  ) => {
    const primary = stats(component, category).find((stat) => stat.primary);

    return primary ? { value: primary.value, label: primary.label } : undefined;
  };

  const componentFigure = (component?: LoadoutComponentRef) => {
    if (!component) return undefined;

    const grade = component.gradeLabel
      ? `${t("labels.component.grade")} ${component.gradeLabel}`
      : undefined;
    const quality = [component.itemClassLabel, grade].filter(Boolean).join(" ");

    return (
      [component.size ? `S${component.size}` : undefined, quality]
        .filter(Boolean)
        .join(" · ") || undefined
    );
  };

  // path -> part id -> the slots that part brings there
  const below = ref<Record<string, Record<string, LoadoutSlot[]>>>({});

  const components = ref<Record<string, LoadoutComponentRef>>({});

  const remember = (component?: LoadoutComponentRef) => {
    if (component) components.value[component.id] = component;
  };

  const learnBelow = (path: string, partId: string, slots: LoadoutSlot[]) => {
    below.value[path] = { ...below.value[path], [partId]: slots };
  };

  const learn = (slots: LoadoutSlot[] = [], parentPath?: string) => {
    slots.forEach((slot) => {
      const path = parentPath ? `${parentPath}/${slot.name}` : slot.name;
      remember(slot.stock);
      remember(slot.fitted);

      const partId = slot.fitted?.id ?? slot.stock?.id;
      if (partId) learnBelow(path, partId, slot.slots);

      learn(slot.slots, path);
    });
  };

  const learnOption = (path: string, option: LoadoutOption) => {
    remember(option.component);
    option.slots.forEach((slot) => remember(slot.stock));
    learnBelow(path, option.component.id, option.slots);
  };

  const resolve = (
    slots: LoadoutSlot[],
    fitted: Record<string, string>,
    parentPath?: string,
  ): FittedSlot[] =>
    slots.map((slot) => {
      const path = parentPath ? `${parentPath}/${slot.name}` : slot.name;
      const partId = fitted[path] ?? slot.stock?.id;

      return {
        path,
        slot,
        content: partId ? components.value[partId] : undefined,
        children: partId
          ? resolve(below.value[path]?.[partId] ?? [], fitted, path)
          : [],
      };
    });

  const roots = (tree: FittedSlot[], tab: ComponentTab) =>
    tree.filter(
      (entry) =>
        entry.slot.category && tab.categories.includes(entry.slot.category),
    );

  // Whether a slot or anything below it can be changed, so a locked mount
  // still shows the guns inside it.
  const changeable = (entry: FittedSlot): boolean =>
    entry.slot.editable || entry.children.some(changeable);

  const find = (tree: FittedSlot[], path: string): FittedSlot | undefined => {
    for (const entry of tree) {
      if (entry.path === path) return entry;
      if (path.startsWith(`${entry.path}/`)) return find(entry.children, path);
    }

    return undefined;
  };

  const socket = (
    entry: FittedSlot,
    fittedOnly: boolean,
    saved?: FittedSlot[],
  ): LoadoutSocketSlot | undefined => {
    const children = entry.children
      .filter(changeable)
      .map((child) => socket(child, fittedOnly, saved))
      .filter((child): child is LoadoutSocketSlot => !!child);

    if (fittedOnly && !entry.content && !children.length) return undefined;

    return {
      id: entry.path,
      label: slotName(entry.slot.name),
      size: sizeLabel(entry.slot),
      // Shown for what sits inside it, but nothing else fits it: the game locks
      // it, or the part it came with is the only one made for it.
      locked: !entry.slot.editable || entry.slot.swappable === false,
      changed:
        !!saved && find(saved, entry.path)?.content?.id !== entry.content?.id,
      item: entry.content
        ? {
            id: entry.content.id,
            name: entry.content.name,
            figure: componentFigure(entry.content),
            category: entry.slot.category,
            headline: headlineOf(entry.content, entry.slot.category),
          }
        : undefined,
      children,
    };
  };

  // One group per hull slot, holding it and what sits inside it, nested the
  // way the ship page nests a turret's guns under the turret.
  const groups = (
    tree: FittedSlot[],
    tab: ComponentTab,
    {
      fittedOnly = false,
      saved,
    }: { fittedOnly?: boolean; saved?: FittedSlot[] } = {},
  ): LoadoutSocketGroup[] =>
    roots(tree, tab)
      .filter(changeable)
      .map((root) => socket(root, fittedOnly, saved))
      .filter((slot): slot is LoadoutSocketSlot => !!slot)
      .map((slot) => ({ key: slot.id, slots: [slot] }));

  const hasSlots = (tree: FittedSlot[], tab: ComponentTab) =>
    roots(tree, tab).some(changeable);

  // Every part a tab's slots hold, below locked mounts included.
  const parts = (entries: FittedSlot[]): FittedSlot[] =>
    entries.flatMap((entry) => [
      ...(entry.content ? [entry] : []),
      ...parts(entry.children),
    ]);

  /**
   * The ship's figures for one tab: what its parts add up to, against the
   * fitting as saved. A figure a second part does not add to -- a drive's
   * speed, a missile's lock time -- is shown only where one part sets it.
   */
  const tabFigures = (
    tree: FittedSlot[],
    saved: FittedSlot[],
    tab: ComponentTab,
  ): FigureChange[] => {
    const totals = (entries: FittedSlot[]) => {
      const sums = new Map<string, { label: string; values: number[] }>();
      parts(roots(entries, tab)).forEach((entry) =>
        stats(entry.content, entry.slot.category).forEach((stat) => {
          const key = stat.key ?? "";
          const total = sums.get(key) ?? { label: stat.label, values: [] };
          total.values.push(stat.raw as number);
          sums.set(key, total);
        }),
      );

      return new Map(
        [...sums]
          .filter(
            ([key, total]) => ADDITIVE.has(key) || total.values.length === 1,
          )
          .map(([key, total]) => [
            key,
            {
              label: total.label,
              value: total.values.reduce((sum, value) => sum + value, 0),
            },
          ]),
      );
    };

    const now = totals(tree);
    const was = totals(saved);

    return [...now].map(([key, total]) => ({
      key,
      label: total.label,
      value: String(toNumber(Math.round(total.value * 100) / 100)),
      before: was.get(key)?.value,
      after: total.value,
      ...change(key, was.get(key)?.value, total.value),
    }));
  };

  /**
   * The ship's hardpoints with the fitting in them, for the figures the ship
   * page works out from a whole ship -- power, cooling, signatures. A slot the
   * loadout covers is rebuilt from the fitting; everything else, thrusters and
   * armor included, stays as the ship has it.
   */
  const graft = (hardpoints: Hardpoint[], tree: FittedSlot[]): Hardpoint[] => {
    const toHardpoint = (entry: FittedSlot, original?: Hardpoint): Hardpoint =>
      ({
        ...original,
        id: original?.id ?? entry.slot.hardpointId,
        name: entry.slot.name,
        category: entry.slot.category ?? original?.category,
        minSize: entry.slot.minSize,
        maxSize: entry.slot.maxSize,
        component: entry.content as Component | undefined,
        hardpoints: entry.children.map((child) =>
          toHardpoint(
            child,
            original?.hardpoints?.find((hp) => hp.name === child.slot.name),
          ),
        ),
      }) as Hardpoint;

    return hardpoints.map((hardpoint) => {
      const entry = tree.find((root) => root.slot.name === hardpoint.name);

      return entry ? toHardpoint(entry, hardpoint) : hardpoint;
    });
  };

  // The whole-ship figures each tab moves, power-plant figures on the power
  // plants' tab and so on; every tab shows what its parts draw.
  const SHIP_FIGURES: Record<string, string[]> = {
    powerPlants: ["pips", "power", "cooling", "em", "ir"],
    coolers: ["cooling", "ir", "power"],
    radar: ["aimAssist", "power", "em"],
  };

  const shipFigures = (
    now: LoadoutSimResult,
    saved: LoadoutSimResult,
    tabId: string,
  ): FigureChange[] => {
    const used = (sim: LoadoutSimResult) => sim.totalSegments - sim.remaining;
    const compact = (value: number) =>
      value >= 1000
        ? `${String(toNumber(Math.round(value / 100) / 10))}k`
        : String(toNumber(Math.round(value)));

    const figures: Record<string, () => FigureChange> = {
      pips: () => ({
        key: "pips",
        label: t("labels.hardpoint.powerPlants.pips"),
        value: String(now.totalSegments),
        ...change("pips", saved.totalSegments, now.totalSegments),
      }),
      power: () => ({
        key: "powerConsumption",
        label: t("labels.hardpoint.powerConsumption"),
        value: `${used(now)} / ${now.totalSegments}`,
        ...change("powerConsumption", used(saved), used(now)),
      }),
      cooling: () => ({
        key: "coolingLoad",
        label: t("labels.power.cooling"),
        value: `${Math.round(now.coolingRatio * 100)}%`,
        ...change("signature", saved.coolingRatio, now.coolingRatio),
      }),
      em: () => ({
        key: "signatureEm",
        label: t("labels.hardpoint.signatureEm"),
        value: compact(now.emittedEm),
        ...change("signatureEm", saved.emittedEm, now.emittedEm),
      }),
      ir: () => ({
        key: "signatureIr",
        label: t("labels.hardpoint.signatureIr"),
        value: compact(now.emittedIr),
        ...change("signatureIr", saved.emittedIr, now.emittedIr),
      }),
      aimAssist: () => ({
        key: "aimAssist",
        label: t("labels.power.aimAssist"),
        value: `${String(toNumber(Math.round(now.aimAssist)))} m`,
        ...change("aimAssist", saved.aimAssist, now.aimAssist),
      }),
    };

    return (SHIP_FIGURES[tabId] ?? ["power"]).map((key) => figures[key]());
  };

  // The parts a slot takes, each with its headline figure and how far that
  // moves from what the slot holds now.
  const options = (
    candidates: LoadoutOption[],
    slot: LoadoutSlot,
    fitted?: LoadoutComponentRef,
  ): LoadoutPickerOption[] =>
    candidates.map(({ component }) => {
      const primary = compare(fitted, component, slot.category)[0];

      return {
        id: component.id,
        name: component.name,
        description: [typeName(component), componentFigure(component)]
          .filter(Boolean)
          .join(" · "),
        stock: component.id === slot.stock?.id,
        figure: headline(component, slot.category),
        delta:
          component.id !== fitted?.id && primary?.deltaLabel && primary.tone
            ? { label: primary.deltaLabel, tone: primary.tone }
            : undefined,
        sortValues: sortValues(component, slot.category),
      };
    });

  const SIZE_SORT = "size";
  const GRADE_SORT = "grade";

  // Every figure a part is ranked on, then its size and grade; a grade sorts A
  // first, as the letter reads.
  const sortValues = (
    component: LoadoutComponentRef,
    category?: HardpointCategoryEnum,
  ) => {
    const values: Record<string, number> = Object.fromEntries(
      stats(component, category).map((stat) => [stat.key, stat.raw as number]),
    );
    const size = Number(component.size);
    if (Number.isFinite(size)) values[SIZE_SORT] = size;
    if (component.gradeLabel) {
      values[GRADE_SORT] = component.gradeLabel.charCodeAt(0);
    }

    return values;
  };

  /**
   * The sorts a slot's parts offer: the figures the ship page ranks that kind
   * of part on, its headline first so the list opens best first, then size and
   * grade. A figure that reads better smaller sorts smallest first.
   */
  const sorts = (
    candidates: LoadoutOption[],
    slot: LoadoutSlot,
  ): LoadoutPickerSort[] => {
    const figures = new Map<string, string>();
    candidates.forEach(({ component }) =>
      stats(component, slot.category).forEach((stat) => {
        if (stat.key && !figures.has(stat.key)) {
          figures.set(stat.key, stat.label);
        }
      }),
    );

    return [
      ...[...figures].map(([key, label]) => ({
        key,
        label,
        ascending: lowerIsBetter(key),
      })),
      { key: SIZE_SORT, label: t("labels.hardpoint.size") },
      { key: GRADE_SORT, label: t("labels.component.grade"), ascending: true },
    ];
  };

  /**
   * The fitting after a pick: the stock part, or nothing, clears the slot; and
   * whatever sat below the slot goes, since the slots below belong to the part
   * that was there.
   */
  const pick = (
    fitted: Record<string, string>,
    entry: FittedSlot,
    componentId: string | null,
  ) => {
    const next = Object.fromEntries(
      Object.entries(fitted).filter(
        ([path]) => !path.startsWith(`${entry.path}/`),
      ),
    );

    if (componentId && componentId !== entry.slot.stock?.id) {
      next[entry.path] = componentId;
    } else {
      delete next[entry.path];
    }

    return next;
  };

  // A fitting the tree no longer reaches -- below a part swapped out -- is not
  // saved, as the server would refuse it.
  const reachable = (tree: FittedSlot[], fitted: Record<string, string>) =>
    Object.fromEntries(
      Object.entries(fitted).filter(([path]) => !!find(tree, path)),
    );

  return {
    learn,
    learnOption,
    resolve,
    groups,
    hasSlots,
    find,
    options,
    sorts,
    pick,
    reachable,
    components,
    compare,
    componentFigure,
    stats,
    tabFigures,
    graft,
    shipFigures,
  };
};
