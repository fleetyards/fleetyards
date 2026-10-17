import { useI18n } from "@/shared/composables/useI18n";
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import {
  CARGO,
  type FittingRow,
  useLoadoutDiff,
} from "@/frontend/composables/useLoadoutDiff";
import { moduleSlots } from "@/frontend/components/Vehicles/LoadoutModal/moduleSlots";
import type {
  LoadoutSocketGroup,
  LoadoutSocketSlot,
} from "@/frontend/components/Loadout/Socket/types";
import type {
  LoadoutPickerOption,
  LoadoutPickerSort,
} from "@/frontend/components/Loadout/Picker/types";
import type { ModelModule } from "@/services/fyApi";

/**
 * A hull's modules in the shape the loadout sockets and picker take: the slots
 * as sockets holding what is fitted, and each slot's modules as picker options
 * with what fitting them changes against what the slot holds.
 */
export const useModuleSockets = () => {
  const { t } = useI18n();

  const { contents } = useModuleContents();

  const { slotLabel } = useLoadoutSlotLabel();

  const { metrics, rows } = useLoadoutDiff();

  // Only what the module itself brings: the hull's own cargo would make every
  // module read the same.
  const figuresOf = (mod?: ModelModule) => metrics(0, mod ? [mod] : []);

  const describe = (row: FittingRow, amount: string) =>
    row.key === CARGO ? amount : `${amount} ${row.label}`;

  // The first thing the module brings, cargo before anything else.
  const figure = (mod: ModelModule) => {
    const row = rows(figuresOf(), figuresOf(mod)).find((entry) => entry.after);

    return row ? describe(row, row.value) : undefined;
  };

  const delta = (
    mod: ModelModule,
    fitted?: ModelModule,
  ): LoadoutPickerOption["delta"] => {
    if (mod.id === fitted?.id) return undefined;

    const row = rows(figuresOf(fitted), figuresOf(mod)).find(
      (entry) => entry.delta && entry.deltaLabel,
    );
    if (!row?.delta || !row.deltaLabel) return undefined;

    return { label: describe(row, row.deltaLabel), tone: row.delta.tone };
  };

  const groups = (
    modules: ModelModule[],
    fitted: Record<string, string>,
    {
      fittedOnly = false,
      saved,
      contents,
    }: {
      fittedOnly?: boolean;
      saved?: Record<string, string>;
      // What a module brings, shown under it: its slots and the parts in them.
      contents?: (mod: ModelModule) => LoadoutSocketSlot[];
    } = {},
  ): LoadoutSocketGroup[] => {
    const slots = moduleSlots(modules)
      .filter((slot) => !fittedOnly || !!fitted[slot])
      .map((slot) => {
        const fittedId = fitted[slot];
        const mod = modules.find((entry) => entry.id === fittedId);
        const changed = !!saved && (saved[slot] ?? null) !== (fittedId ?? null);

        if (!fittedId) {
          return { id: slot, label: slotLabel(slot), changed };
        }

        // Fitted, but gone from the hull's modules, as a module retired from
        // the catalogue is: still saved with the loadout, so not shown as empty.
        if (!mod) {
          return {
            id: slot,
            label: slotLabel(slot),
            changed,
            item: {
              id: fittedId,
              name: t("labels.vehicleLoadout.unavailableModule"),
            },
          };
        }

        return {
          id: slot,
          label: slotLabel(slot),
          changed,
          children: contents?.(mod),
          item: {
            id: mod.id,
            name: mod.name,
            image: mod.media?.storeImage?.smallUrl,
            figure: figure(mod),
          },
        };
      });

    // A hull has a handful of module slots, each named for where it sits, so
    // one group without a heading reads better than a heading per socket.
    return slots.length ? [{ key: "modules", slots }] : [];
  };

  const options = (
    modules: ModelModule[],
    slot: string,
    fittedId: string | undefined,
    ownedIds: string[],
  ): LoadoutPickerOption[] => {
    const fitted = modules.find((mod) => mod.id === fittedId);

    return modules
      .filter((mod) => mod.slot === slot)
      .map((mod) => {
        const cargo = mod.metrics?.cargo;

        return {
          id: mod.id,
          name: mod.name,
          image: mod.media?.storeImage?.smallUrl,
          manufacturer: mod.manufacturer?.name,
          // What it holds where its hardpoints say, else the store's words.
          description: contents(mod) || mod.description,
          owned: ownedIds.includes(mod.id),
          stock: !!mod.stock,
          figure: figure(mod),
          delta: delta(mod, fitted),
          sortValues: cargo ? { [CARGO]: cargo } : undefined,
        };
      });
  };

  // Cargo is the one figure modules share widely enough to rank them by.
  const sorts = (candidates: LoadoutPickerOption[]): LoadoutPickerSort[] =>
    candidates.some((option) => option.sortValues?.[CARGO])
      ? [{ key: CARGO, label: t("labels.model.cargo") }]
      : [];

  return { groups, options, sorts, slotLabel };
};
