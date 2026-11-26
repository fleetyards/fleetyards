import { type MaybeRefOrGetter, type Ref, toValue } from "vue";
import type {
  ModelLoadoutPreview,
  ModelLoadoutPreviewCargoGrid,
  ModelLoadoutPreviewDoor,
  ModelLoadoutPreviewPort,
} from "@/services/fyApi";
import { componentTabOf } from "@/frontend/composables/useComponentFitting";
import {
  builtInKind,
  categoryColor,
  type PreviewSlot,
} from "@/frontend/utils/loadoutPreview";
import { BOX_COLOR } from "@/shared/components/HoloViewer/boxes";
import { BUILT_IN_COLOR } from "@/shared/components/HoloViewer/builtIns";
import { DOOR_COLOR } from "@/shared/components/HoloViewer/doors";
import { CARGO_GRID_COLOR } from "@/shared/components/HoloViewer/cargo";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";
import { useI18n } from "@/shared/composables/useI18n";
import {
  servicingAreaLabel,
  servicingAreaSize,
} from "@/shared/utils/LandingServices";

export type HoloCardContent = {
  kicker?: string;
  color?: string;
  title: string;
  details: string[];
};

export type HoloCursor = {
  x: number;
  y: number;
  flipX: boolean;
  flipY: boolean;
  // Placed by a finger, which would cover a card beside it.
  docked: boolean;
};

type FittedHull = {
  ports: ModelLoadoutPreviewPort[];
  cargoGrids: ModelLoadoutPreviewCargoGrid[];
  doors: ModelLoadoutPreviewDoor[];
};

type Options = {
  preview: MaybeRefOrGetter<ModelLoadoutPreview | undefined>;
  slots: MaybeRefOrGetter<PreviewSlot[]>;
  hull: MaybeRefOrGetter<FittedHull | undefined>;
  // The doors drawn, and whether a click opens them.
  doors: MaybeRefOrGetter<ModelLoadoutPreviewDoor[]>;
  doorsAnimated: MaybeRefOrGetter<boolean>;
  doorsHighlighted: MaybeRefOrGetter<boolean>;
  isOpen: (id: string) => boolean;
  // What a click on a part does, where it does anything.
  partHint?: (slot: PreviewSlot, tapped: boolean) => string | undefined;
  // What a click, or a tap, on a built-in item does, where it does anything.
  builtInHint?: (tapped: boolean) => string;
  // The pointed part's path, where the caller marks that part itself.
  pointedPath?: Ref<string | undefined>;
};

const DOOR_KINDS: Record<string, string> = {
  door: "door",
  airlock: "airlock",
  elevator: "elevator",
  hatch: "hatch",
  side_door: "sideDoor",
  ramp: "ramp",
};

/**
 * The card a loadout holo shows beside the pointer: the part, built-in item,
 * door, cargo grid or servicing area under it, named with the figures the
 * ship's page gives it.
 */
export const useLoadoutHoloCard = (options: Options) => {
  const { t, toNumber } = useI18n();

  const pointedPath = options.pointedPath ?? ref<string>();
  const pointedArea = ref<string>();
  const pointedBuiltIn = ref<string>();
  const pointedDoor = ref<string>();
  const pointedCargoGrid = ref<string>();

  const cursor = ref<HoloCursor>({
    x: 0,
    y: 0,
    flipX: false,
    flipY: false,
    docked: false,
  });

  // Only the canvas places the card: a press on a button over it is not a
  // look at the holo.
  const trackPointer = (event: PointerEvent) => {
    if (!(event.target instanceof HTMLCanvasElement)) return;

    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const x = event.clientX - rect.left;
    const y = event.clientY - rect.top;

    cursor.value = {
      x,
      y,
      flipX: x > rect.width - 260,
      flipY: y > rect.height - 120,
      docked: event.pointerType === "touch",
    };
  };

  const doorHint = (open: boolean, tapped: boolean) => {
    if (open) {
      return tapped
        ? t("actions.holoViewer.door.closeTap")
        : t("actions.holoViewer.door.close");
    }

    return tapped
      ? t("actions.holoViewer.door.openTap")
      : t("actions.holoViewer.door.open");
  };

  // Every slot by the path its part on the holo is named by.
  const slotsByPath = computed(() => {
    const byPath = new Map<string, PreviewSlot>();

    const walk = (slots: PreviewSlot[], prefix: string) => {
      for (const slot of slots) {
        const path = slot.path ?? `${prefix}${slot.name}`;
        byPath.set(path, slot);
        walk(slot.slots, `${path}/`);
      }
    };

    walk(toValue(options.slots), "");

    return byPath;
  });

  // A built-in item by its port: the part its slot holds. A nested port is
  // found through its parents, as the slots are pathed.
  const builtInPart = (id: string) => {
    const ports = toValue(options.hull)?.ports ?? [];
    const port = ports.find((candidate) => candidate.name === id);

    const names: string[] = [];
    for (
      let current = port;
      current;
      current = current.parent
        ? ports.find((candidate) => candidate.name === current?.parent)
        : undefined
    ) {
      names.unshift(current.name.toLowerCase());
      if (names.length > ports.length) break;
    }

    const path = names.join("/");
    const part = [...slotsByPath.value].find(
      ([candidate]) => candidate.toLowerCase() === path,
    )?.[1].part;

    if (part?.name || !port?.defaultItemName) {
      return { port, part: part?.name ? part : undefined };
    }

    // Kept in the hull with no slot of its own, a stowed mining bag: named
    // from the catalogue.
    return {
      port,
      part: {
        name: port.defaultItemName,
        slug: port.defaultItemSlug ?? undefined,
        size: undefined,
      },
    };
  };

  const partCard = (slot: PreviewSlot): HoloCardContent | undefined => {
    const { part } = slot;
    if (!part?.name) return undefined;

    const tab = componentTabOf(slot.category);

    return {
      kicker: tab ? t(`labels.vehicleLoadout.tabs.${tab.id}`) : undefined,
      color: categoryColor(slot.category),
      title: part.name,
      details: [
        part.size ? `S${part.size}` : undefined,
        part.itemClassLabel,
        part.gradeLabel
          ? `${t("labels.component.grade")} ${part.gradeLabel}`
          : undefined,
        options.partHint?.(slot, cursor.value.docked),
      ].filter((detail): detail is string => !!detail),
    };
  };

  const card = computed((): HoloCardContent | undefined => {
    const slot = pointedPath.value
      ? slotsByPath.value.get(pointedPath.value)
      : undefined;
    if (slot) return partCard(slot);

    if (pointedBuiltIn.value) {
      const { port, part } = builtInPart(pointedBuiltIn.value);
      const kind =
        (port && builtInKind(port, toValue(options.hull)?.ports)) ?? "weapon";

      return {
        kicker: t(`labels.loadoutHoloBuiltInKinds.${kind}`),
        color: BUILT_IN_COLOR,
        title: part?.name ?? port?.defaultItem ?? pointedBuiltIn.value,
        details: [
          part?.size ? `S${part.size}` : undefined,
          t("labels.loadoutHoloBuiltIn"),
          part?.slug ? options.builtInHint?.(cursor.value.docked) : undefined,
        ].filter((detail): detail is string => !!detail),
      };
    }

    const door = toValue(options.doorsHighlighted)
      ? toValue(options.doors).find(
          (candidate) => candidate.id === pointedDoor.value,
        )
      : undefined;

    if (door) {
      const kind = DOOR_KINDS[door.kind ?? ""] ?? "door";

      return {
        kicker: t("labels.loadoutHoloDoor"),
        color: DOOR_COLOR,
        title: t(`labels.loadoutHoloDoorKinds.${kind}`),
        details: toValue(options.doorsAnimated)
          ? [doorHint(options.isOpen(door.id), cursor.value.docked)]
          : [],
      };
    }

    const grid = toValue(options.hull)?.cargoGrids.find(
      (candidate) => candidate.name === pointedCargoGrid.value,
    );

    if (grid) {
      const [width, height, length] = grid.size;

      return {
        kicker: t("labels.loadoutHoloCargoGrid"),
        color: CARGO_GRID_COLOR,
        title: humanizeHoldName(grid.name),
        details: [
          grid.capacity ? `${toNumber(grid.capacity)} SCU` : undefined,
          `${toNumber(length)} × ${toNumber(width)} × ${toNumber(height)} m`,
        ].filter((detail): detail is string => !!detail),
      };
    }

    const area = toValue(options.preview)?.servicingAreas.find(
      (candidate) => candidate.key === pointedArea.value,
    );

    if (!area) return undefined;

    return {
      kicker: t("labels.loadoutHoloServicingArea"),
      color: BOX_COLOR,
      title: servicingAreaLabel(area, area.index, { t }),
      details: [servicingAreaSize(area, { toNumber })],
    };
  });

  const reset = () => {
    pointedPath.value = undefined;
    pointedArea.value = undefined;
    pointedBuiltIn.value = undefined;
    pointedDoor.value = undefined;
    pointedCargoGrid.value = undefined;
  };

  return {
    pointedPath,
    pointedArea,
    pointedBuiltIn,
    pointedDoor,
    pointedCargoGrid,
    cursor,
    trackPointer,
    builtInPart,
    card,
    reset,
  };
};
