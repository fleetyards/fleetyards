import { useI18n } from "@/shared/composables/useI18n";
import { HardpointCategoryEnum, type Hardpoint } from "@/services/fyApi";
import type { ModelModule } from "@/services/fyApi";

// Ports that say nothing about what the module is for. The slot row drops the
// same two from its own expansion.
const UNINFORMATIVE: HardpointCategoryEnum[] = [
  HardpointCategoryEnum.CONTROLLER,
  HardpointCategoryEnum.UNKNOWN,
];

/**
 * What a module brings, summarised from its own hardpoints: a torpedo bay and a
 * cargo bay fill the same slot and only their fittings tell them apart.
 *
 * Undefined rather than a "nothing to show" string, because the two pickers
 * that read this fall back differently — the slot picker says so outright,
 * since a module with no fittings is the answer to the question it is asking,
 * while the hangar's list would rather show the module's description. Most
 * modules in the catalogue have no hardpoints at all, so the fallback is the
 * common case, not the edge.
 */
export const useModuleContents = () => {
  const { t } = useI18n();

  const contents = (mod: ModelModule): string | undefined => {
    const counts = new Map<string, number>();

    (mod.hardpoints || []).forEach((hardpoint: Hardpoint) => {
      const category = hardpoint.category;

      if (!category || UNINFORMATIVE.includes(category)) {
        return;
      }

      counts.set(category, (counts.get(category) || 0) + 1);
    });

    if (!counts.size) {
      return undefined;
    }

    // The count is dropped at one, because every category label is plural.
    return [...counts.entries()]
      .map(([category, count]) => {
        const label = t(`labels.hardpoint.categories.${category}`);

        return count > 1 ? `${count} × ${label}` : label;
      })
      .join(" · ");
  };

  return { contents };
};
