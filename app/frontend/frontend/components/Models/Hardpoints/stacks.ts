import type { Hardpoint } from "@/services/fyApi";

/**
 * Hardpoints shown as one stacked row. The server's group key reads a slot by
 * what sits inside it, and leaves its own part out wherever it holds anything,
 * so three different turrets carrying the same tractor beam shared one key and
 * stacked under the first one's name; the part has to match as well.
 */
export const groupIntoStacks = (hardpoints: Hardpoint[]) =>
  hardpoints.reduce(
    (stacks, hardpoint) => {
      const key = `${hardpoint.groupKey ?? ""}|${hardpoint.component?.id ?? ""}`;
      stacks[key] = [...(stacks[key] ?? []), hardpoint];
      return stacks;
    },
    {} as Record<string, Hardpoint[]>,
  );
