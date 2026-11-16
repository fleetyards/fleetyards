import type { CargoHold } from "@/services/fyApi";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";

function getHoldGroupKey(name: string, allNames: string[]): string {
  if (!name) return name;
  for (const other of allNames) {
    if (other !== name && name.startsWith(other)) {
      const suffix = name.slice(other.length);
      // Match underscore separator (e.g. cargo_walkway) or numeric suffix (e.g. cargo2)
      if (suffix.startsWith("_") || /^\d+$/.test(suffix)) {
        return other;
      }
    }
  }
  return name;
}

// Group cargo holds by name prefix, preserving original indices
export function groupCargoHolds(
  holds: CargoHold[],
): { key: string; label: string; holdIndices: number[] }[] {
  const allNames = holds.map((h) => h.name || "").filter((n) => n);

  // Pass 1: prefix matching (e.g. module_01 is prefix of module_01_walkway)
  const groupKeys: string[] = holds.map((hold, idx) => {
    const name = hold.name || "";
    if (!name) return `hold_${idx}`;
    return getHoldGroupKey(name, allNames);
  });

  // Pass 2: merge single-hold groups by stripping last name segment
  // (e.g. cargo_front_left + cargo_front_right → cargo_front)
  const keyCounts = new Map<string, number>();
  for (const key of groupKeys) {
    keyCounts.set(key, (keyCounts.get(key) || 0) + 1);
  }

  const singleKeys = new Set(
    [...keyCounts.entries()].filter(([, c]) => c === 1).map(([k]) => k),
  );

  if (singleKeys.size > 1) {
    const parentChildren = new Map<string, string[]>();
    for (const key of singleKeys) {
      const lastUnderscore = key.lastIndexOf("_");
      if (lastUnderscore > 0) {
        const parent = key.substring(0, lastUnderscore);
        if (!parentChildren.has(parent)) parentChildren.set(parent, []);
        parentChildren.get(parent)!.push(key);
      }
    }

    const mergeMap = new Map<string, string>();
    for (const [parent, children] of parentChildren) {
      if (children.length >= 2) {
        for (const child of children) mergeMap.set(child, parent);
      }
    }

    if (mergeMap.size > 0) {
      for (let i = 0; i < groupKeys.length; i++) {
        const merged = mergeMap.get(groupKeys[i]);
        if (merged) groupKeys[i] = merged;
      }
    }
  }

  const allHaveOffsets = holds.every(
    (h) =>
      h.offset &&
      h.offset.x != null &&
      h.offset.y != null &&
      h.offset.z != null,
  );

  // Build groups maintaining insertion order
  const groupMap = new Map<string, number[]>();
  const groupOrder: string[] = [];

  for (let i = 0; i < holds.length; i++) {
    const key = groupKeys[i];
    if (!groupMap.has(key)) {
      groupMap.set(key, []);
      groupOrder.push(key);
    }
    groupMap.get(key)!.push(i);
  }

  // If all holds have offsets and every natural group is small (≤ 2 holds),
  // collapse into a single group so the backend fully controls the cross-group
  // layout (e.g. Hull B diamond pattern spanning 8 name-based groups).
  // Ships with larger groups (e.g. Caterpillar modules with 3 holds each)
  // keep their per-group arrangement so offsets work within each group.
  // Holds the ship-view export placed sit where they are in the ship, so the
  // ship is one group whatever their names group them into.
  if (allHaveOffsets && holds.length > 1) {
    const maxGroupSize = Math.max(
      ...groupOrder.map((key) => groupMap.get(key)!.length),
    );

    if (maxGroupSize <= 2 || holds.every((hold) => hold.placed)) {
      const commonPrefix =
        groupKeys.reduce((prefix, key) => {
          while (prefix && !key.startsWith(prefix)) {
            const lastUnderscore = prefix.lastIndexOf("_");
            prefix =
              lastUnderscore > 0 ? prefix.substring(0, lastUnderscore) : "";
          }
          return prefix;
        }, groupKeys[0]) || "cargo";

      return [
        {
          key: commonPrefix,
          label: humanizeHoldName(commonPrefix),
          holdIndices: holds.map((_, i) => i),
        },
      ];
    }
  }

  return groupOrder.map((key) => ({
    key,
    label: key.startsWith("hold_")
      ? `Hold ${key.slice(5)}`
      : humanizeHoldName(key),
    holdIndices: groupMap.get(key)!,
  }));
}
