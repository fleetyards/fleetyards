import type { Hardpoint } from "@/services/fyApi";

/**
 * Hardpoints shown as one stacked row. The server's group key reads a slot by
 * what sits inside it, and leaves its own part out wherever it holds anything,
 * so three different turrets carrying the same tractor beam shared one key and
 * stacked under the first one's name; the part has to match as well. By name:
 * the game files carry one part as several records -- a Constellation's left
 * and right missile racks -- which are the same part to anyone reading the list.
 * A part with no name -- a thruster, one record per position -- is matched on
 * what it does instead, so two that burn different fuel stay apart.
 */
export const groupIntoStacks = (hardpoints: Hardpoint[]) =>
  hardpoints.reduce(
    (stacks, hardpoint) => {
      const component = hardpoint.component;
      const part = component
        ? component.name ||
          JSON.stringify([component.size, component.typeData ?? null])
        : "";
      const key = `${hardpoint.groupKey ?? ""}|${part}`;
      stacks[key] = [...(stacks[key] ?? []), hardpoint];
      return stacks;
    },
    {} as Record<string, Hardpoint[]>,
  );
