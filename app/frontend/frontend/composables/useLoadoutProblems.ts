import type { MaybeRefOrGetter } from "vue";
import type {
  LoadoutSocketGroup,
  LoadoutSocketSlot,
} from "@/frontend/components/Loadout/Socket/types";
import { slotName } from "@/frontend/composables/useComponentFitting";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type LoadoutItemProblem,
  useVehicleLoadoutProblems,
} from "@/services/fyApi";

/**
 * The saved items the build in force refuses. A loadout floats with the build,
 * so a slot a new build narrowed or removed leaves an item behind that no save
 * would accept; these name each one and why, for the owner to see before a
 * save takes them out.
 */
export const useLoadoutProblems = (
  vehicleId: MaybeRefOrGetter<string>,
  loadoutId: MaybeRefOrGetter<string | undefined>,
  enabled: MaybeRefOrGetter<boolean>,
) => {
  const { t } = useI18n();

  const { data } = useVehicleLoadoutProblems(
    vehicleId,
    () => toValue(loadoutId) ?? "",
    {
      query: {
        enabled: () => toValue(enabled) && !!toValue(loadoutId),
      },
    },
  );

  const problems = computed<LoadoutItemProblem[]>(() => data.value ?? []);

  const reason = (problem: LoadoutItemProblem) =>
    t(`labels.vehicleLoadout.refused.reasons.${problem.code}`);

  const describe = (problem: LoadoutItemProblem) =>
    `${problem.itemName || t("labels.loadoutPicker.emptySocket")} (${problem.slotPath
      .split("/")
      .map(slotName)
      .join(" › ")}): ${reason(problem)}`;

  const markSocket = (
    socket: LoadoutSocketSlot,
    refused: Map<string, string>,
  ): LoadoutSocketSlot => {
    const paths = socket.members ?? [socket.id];
    const why = paths.map((path) => refused.get(path)).find(Boolean);

    return {
      ...socket,
      refused: why,
      children: socket.children?.map((child) => markSocket(child, refused)),
      stack: socket.stack?.map((member) => markSocket(member, refused)),
    };
  };

  // Marks the sockets still holding a refused item, so the slot says so where
  // it is fitted.
  const markRefused = (
    groups: LoadoutSocketGroup[],
    refused: LoadoutItemProblem[],
  ): LoadoutSocketGroup[] => {
    if (!refused.length) return groups;

    const reasons = new Map(
      refused.map((problem) => [problem.slotPath, reason(problem)]),
    );

    return groups.map((group) => ({
      ...group,
      slots: group.slots.map((slot) => markSocket(slot, reasons)),
    }));
  };

  return { problems, reason, describe, markRefused };
};
