import type { Hardpoint } from "@/services/fyApi";

/**
 * Hardpoints shown as one stacked row. The server's group key reads a slot by
 * what sits inside it, and leaves its own part out wherever it holds anything,
 * so three different turrets carrying the same tractor beam shared one key and
 * stacked under the first one's name; the part has to match as well. By name:
 * the game files carry one part as several records -- a Constellation's left
 * and right missile racks -- which are the same part to anyone reading the list.
 */
export const groupIntoStacks = (hardpoints: Hardpoint[]) =>
  hardpoints.reduce(
    (stacks, hardpoint) => {
      const part = hardpoint.component?.name || hardpoint.component?.id || "";
      const key = `${hardpoint.groupKey ?? ""}|${part}`;
      stacks[key] = [...(stacks[key] ?? []), hardpoint];
      return stacks;
    },
    {} as Record<string, Hardpoint[]>,
  );
