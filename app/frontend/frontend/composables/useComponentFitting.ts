import type {
  LoadoutSocketGroup,
  LoadoutSocketSlot,
} from "@/frontend/components/Loadout/Socket/types";
import type {
  LoadoutPickerFacet,
  LoadoutPickerOption,
  LoadoutPickerSort,
} from "@/frontend/components/Loadout/Picker/types";
import type { CompareDeltaTone } from "@/frontend/components/Compare/delta";
import {
  type HardpointStat,
  useHardpointStatsFor,
} from "@/frontend/composables/useHardpointStats";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type Component,
  type Hardpoint,
  type ModelModule,
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

// A slot whose stock part the loadout took out, in a fitting keyed by path.
export const EMPTIED = "";

// Marks a stacked row's id, which is otherwise its first slot's path.
export const GROUP_SUFFIX = "#stack";

// The kinds of part a loadout fits. A port for anything else -- a cargo rack,
// a battery, a door -- is the shipwright's, and only shows where a part a
// loadout fits sits below it.
const FITTED_TYPES = new Set([
  "WeaponGun",
  "WeaponMining",
  "Turret",
  "TurretBase",
  "UtilityTurret",
  "MissileLauncher",
  "BombLauncher",
  "Missile",
  "Bomb",
  "Shield",
  "PowerPlant",
  "Cooler",
  "QuantumDrive",
  "JumpDrive",
  "Radar",
  "LifeSupportGenerator",
  "FlightController",
  "Module",
  "EMP",
  "QuantumInterdictionGenerator",
  "TractorBeam",
]);

const FITTED_CATEGORIES = new Set<string>([
  HardpointCategoryEnum.RADAR,
  HardpointCategoryEnum.COOLER,
  HardpointCategoryEnum.LIFESUPPORT,
  HardpointCategoryEnum.POWERPLANT,
  HardpointCategoryEnum.SHIELDGENERATOR,
  HardpointCategoryEnum.QUANTUMDRIVE,
  HardpointCategoryEnum.JUMPDRIVE,
  HardpointCategoryEnum.CONTROLLER,
  HardpointCategoryEnum.WEAPONS,
  HardpointCategoryEnum.WEAPON_MOUNTS,
  HardpointCategoryEnum.TURRET,
  HardpointCategoryEnum.MISSILE_RACKS,
  HardpointCategoryEnum.MODULE,
]);

// A port whose types name none of those, or, naming no types at all, whose
// category is none of the loadout's.
const takesAPart = (slot: LoadoutSlot) => {
  const types = slot.types.filter(Boolean);

  return types.length
    ? types.some((type) => FITTED_TYPES.has(type))
    : !!slot.category && FITTED_CATEGORIES.has(slot.category);
};

// Shown under a module: a port a loadout fits, or one that holds such ports.
const shown = (slot: LoadoutSlot): boolean =>
  takesAPart(slot) || slot.slots.some(shown);

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
    const percent = before
      ? Math.round(Math.abs(difference / before) * 100)
      : 0;
    // A move too small to read as one is no move: "+0%" says nothing.
    if (before && percent === 0) return {};

    const better = lowerIsBetter(key) ? difference < 0 : difference > 0;
    const deltaLabel = before
      ? `${difference > 0 ? "+" : "−"}${percent}%`
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

      const partId = slot.emptied
        ? undefined
        : (slot.fitted?.id ?? slot.stock?.id);
      if (partId) learnBelow(path, partId, slot.slots);

      learn(slot.slots, path);
    });
  };

  // A module's ports, from the module list the editor already holds: the
  // hull's tree only knows a module's slots once a loadout has saved it there.
  const toSlot = (hardpoint: Hardpoint): LoadoutSlot => {
    const stock = hardpoint.component as LoadoutComponentRef | undefined;
    remember(stock);

    return {
      name: hardpoint.name,
      hardpointId: hardpoint.id,
      category: hardpoint.category,
      minSize: hardpoint.minSize,
      maxSize: hardpoint.maxSize,
      types: hardpoint.types ?? [],
      editable: true,
      stock,
      // A port inside a module names what sits in it through the part's own
      // ports, as a ship page's hardpoint row reads them: a missile rack's
      // missile slots are the rack's, not the module's.
      slots: (hardpoint.hardpoints?.length
        ? hardpoint.hardpoints
        : (hardpoint.component?.hardpoints ?? [])
      ).map(toSlot),
    };
  };

  const learnModules = (modules: ModelModule[]) =>
    modules.forEach((mod) => {
      if (mod.slot)
        learnBelow(mod.slot, mod.id, (mod.hardpoints ?? []).map(toSlot));
    });

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
      // A path the loadout emptied holds EMPTIED, which reads as no part.
      const partId =
        path in fitted ? fitted[path] || undefined : slot.stock?.id;

      return {
        path,
        slot,
        content: partId ? components.value[partId] : undefined,
        children: partId
          ? resolve(below.value[path]?.[partId] ?? [], fitted, path)
          : [],
      };
    });

  // The slots a tab lists: the hull's own of its categories, and those inside
  // a fitted module -- a combat module's shield is the shields tab's.
  const roots = (tree: FittedSlot[], tab: ComponentTab): FittedSlot[] =>
    tree.flatMap((entry) => {
      if (entry.slot.category === HardpointCategoryEnum.MODULE) {
        return roots(entry.children, tab);
      }

      return entry.slot.category && tab.categories.includes(entry.slot.category)
        ? [entry]
        : [];
    });

  // Whether a slot or anything below it can be changed, so a locked mount
  // still shows the guns inside it.
  // Every slot for a part a loadout fits, locked or not -- a slot nothing
  // else fits is shown and disabled rather than left out -- and any slot such
  // a slot sits in.
  const changeable = (entry: FittedSlot): boolean =>
    takesAPart(entry.slot) || entry.children.some(changeable);

  const find = (tree: FittedSlot[], path: string): FittedSlot | undefined => {
    for (const entry of tree) {
      if (entry.path === path) return entry;
      if (path.startsWith(`${entry.path}/`)) return find(entry.children, path);
    }

    return undefined;
  };

  const glyphCategory = (
    category: HardpointCategoryEnum | undefined,
    part: LoadoutComponentRef,
  ) =>
    category && category !== HardpointCategoryEnum.UNKNOWN
      ? category
      : ((part.category as HardpointCategoryEnum | undefined) ?? category);

  // The figures a ship page's hardpoint row shows beside its gold headline.
  const rowStats = (
    component: LoadoutComponentRef,
    category?: HardpointCategoryEnum,
  ) => stats(component, category).filter((stat) => !stat.primary);

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
      maxSize: entry.slot.maxSize,
      // Shown for what sits inside it, but nothing else fits it: the game locks
      // it, or the part it came with is the only one made for it.
      locked: !entry.slot.editable || entry.slot.swappable === false,
      lockedBy: !entry.slot.editable
        ? "ship"
        : entry.slot.swappable === false
          ? "noAlternatives"
          : undefined,
      changed:
        !!saved && find(saved, entry.path)?.content?.id !== entry.content?.id,
      item: entry.content
        ? {
            id: entry.content.id,
            name: entry.content.name,
            figure: componentFigure(entry.content),
            // A port inside a part often names no category of its own; the part
            // in it does.
            category: glyphCategory(entry.slot.category, entry.content),
            headline: headlineOf(entry.content, entry.slot.category),
            stats: rowStats(entry.content, entry.slot.category),
          }
        : undefined,
      children,
      members: [entry.path],
    };
  };

  // What makes two sibling slots the same row: the part in them, the room they
  // offer, and the same again all the way down, under the same names -- a pick
  // on the stack reaches each member's slots by the first member's paths.
  const signature = (slot: LoadoutSocketSlot): string =>
    JSON.stringify([
      slot.item?.id,
      slot.size,
      slot.locked,
      (slot.children ?? []).map((child) => [
        child.id.slice(child.id.lastIndexOf("/") + 1),
        signature(child),
      ]),
    ]);

  /**
   * Identical siblings as one row with a count, the way a ship page stacks
   * identical mounts: a pick on it fills every one -- four shield generators
   * in one go -- and the slots stay one by one in its stack for fitting each
   * alone.
   *
   * Worked top down, so a row under a stack stands for its slot under every
   * member of that stack: `parents` are the paths the row above stands for,
   * and `from` the path of the one this row was built under.
   */
  const stacked = (
    slots: LoadoutSocketSlot[],
    parents: string[] = [""],
    from = "",
  ): LoadoutSocketSlot[] => {
    const bySignature = new Map<string, LoadoutSocketSlot[]>();
    slots.forEach((slot) => {
      const key = signature(slot);
      bySignature.set(key, [...(bySignature.get(key) ?? []), slot]);
    });

    const membersOf = (same: LoadoutSocketSlot[]) =>
      parents.flatMap((parent) =>
        same.map((slot) => `${parent}${slot.id.slice(from.length)}`),
      );

    const alone = (slot: LoadoutSocketSlot): LoadoutSocketSlot => {
      const members = membersOf([slot]);

      return {
        ...slot,
        members,
        children: stacked(slot.children ?? [], members, slot.id),
      };
    };

    return [...bySignature.values()].flatMap((same) => {
      const [first] = same;
      const members = membersOf(same);
      if (same.length < 2) return same.map(alone);

      return [
        {
          ...first,
          // Its own id: the first slot's path is also the first row of its
          // stack, and the two have to be told apart while one of them is open.
          id: `${first.id}${GROUP_SUFFIX}`,
          members,
          changed: same.some((slot) => slot.changed),
          children: stacked(first.children ?? [], members, first.id),
          stack: same.map(alone),
        },
      ];
    });
  };

  // One group per tab, holding its hull slots and what sits inside them,
  // nested the way the ship page nests a turret's guns under the turret, and
  // identical slots stacked with a count.
  const groups = (
    tree: FittedSlot[],
    tab: ComponentTab,
    {
      fittedOnly = false,
      saved,
    }: { fittedOnly?: boolean; saved?: FittedSlot[] } = {},
  ): LoadoutSocketGroup[] => {
    const sockets = roots(tree, tab)
      .filter(changeable)
      .map((root) => socket(root, fittedOnly, saved))
      .filter((slot): slot is LoadoutSocketSlot => !!slot);

    const slots = stacked(sockets);

    return slots.length ? [{ key: tab.id, slots }] : [];
  };

  /**
   * What a module brings, as rows under it on the modules tab: its own slots
   * and the parts it comes with, read the way the ship page reads them.
   */
  const moduleContents = (mod: ModelModule): LoadoutSocketSlot[] =>
    stacked(
      (mod.hardpoints ?? [])
        .map(toSlot)
        .filter(shown)
        .map((slot) => {
          const toRow = (
            port: LoadoutSlot,
            path: string,
          ): LoadoutSocketSlot => ({
            id: path,
            label: slotName(port.name),
            size: sizeLabel(port),
            maxSize: port.maxSize,
            locked: true,
            item: port.stock
              ? {
                  id: port.stock.id,
                  name: port.stock.name,
                  figure: componentFigure(port.stock),
                  category: glyphCategory(port.category, port.stock),
                  headline: headlineOf(port.stock, port.category),
                  stats: rowStats(port.stock, port.category),
                }
              : undefined,
            children: port.slots
              .filter(shown)
              .map((child) => toRow(child, `${path}/${child.name}`)),
            members: [path],
          });

          return toRow(slot, `${mod.slot}/${slot.name}`);
        }),
    );

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
        // A port inside a part names no category of its own; the ship's copy
        // does, and failing that the part in it, which is what the figures
        // read a gun or a shield by.
        category:
          entry.slot.category &&
          entry.slot.category !== HardpointCategoryEnum.UNKNOWN
            ? entry.slot.category
            : (original?.category ??
              (entry.content?.category as HardpointCategoryEnum | undefined)),
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
        facets: facetValues(component),
      };
    });

  const spaced = (value?: unknown) =>
    typeof value === "string"
      ? value.replace(/([a-z])([A-Z])/g, "$1 $2")
      : undefined;

  // A gun by its class -- laser repeater, ballistic cannon -- where its data
  // names one, any other part by its type; a missile by what it tracks.
  const facetValues = (component: LoadoutComponentRef) => {
    const data = (component.typeData ?? {}) as Record<string, unknown>;

    return {
      type: spaced(data.weaponClass) ?? typeName(component),
      tracking: spaced(data.trackingSignal),
      grade: component.gradeLabel,
      class: component.itemClassLabel,
    };
  };

  // The filters a slot's parts offer; the picker leaves out any its parts do
  // not differ on.
  const facets = (): LoadoutPickerFacet[] => [
    { key: "type", label: t("labels.loadoutPicker.type") },
    { key: "tracking", label: t("labels.hardpoint.missiles.trackingSignal") },
    { key: "grade", label: t("labels.component.grade") },
    { key: "class", label: t("labels.component.itemClass") },
  ];

  const GRADE_SORT = "grade";

  // Every figure a part is ranked on, then its grade; a grade sorts A
  // first, as the letter reads.
  const sortValues = (
    component: LoadoutComponentRef,
    category?: HardpointCategoryEnum,
  ) => {
    const values: Record<string, number> = Object.fromEntries(
      stats(component, category).map((stat) => [stat.key, stat.raw as number]),
    );
    if (component.gradeLabel) {
      values[GRADE_SORT] = component.gradeLabel.charCodeAt(0);
    }

    return values;
  };

  /**
   * The sorts a slot's parts offer: the headline the ship page ranks that kind
   * of part on, so the list opens best first, the two figures its row shows
   * next, and grade. A figure that reads better smaller sorts smallest first.
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
      ...[...figures].slice(0, 3).map(([key, label]) => ({
        key,
        label,
        ascending: lowerIsBetter(key),
      })),
      { key: GRADE_SORT, label: t("labels.component.grade"), ascending: true },
    ];
  };

  /**
   * The fitting after a pick: the stock part goes back to being the slot's own,
   * nothing takes the stock part out; and
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
    } else if (!componentId && entry.slot.stock) {
      next[entry.path] = EMPTIED;
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
    learnModules,
    moduleContents,
    learnOption,
    resolve,
    groups,
    hasSlots,
    find,
    options,
    sorts,
    facets,
    pick,
    reachable,
    components,
    compare,
    componentFigure,
    stats,
    tabFigures,
    graft,
  };
};
