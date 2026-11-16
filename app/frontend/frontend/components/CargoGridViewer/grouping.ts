import type { CargoHold } from "@/services/fyApi";
import { humanizeHoldName } from "@/shared/utils/CargoHolds";
import { holdPlacement } from "./placement";

export type CargoHoldGroup = {
  key: string;
  label: string;
  holdIndices: number[];
  // Every hold sits where the hull export placed it, in one frame.
  placed: boolean;
};

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

function commonPrefix(keys: string[]): string {
  return (
    keys.reduce((prefix, key) => {
      while (prefix && !key.startsWith(prefix)) {
        const lastUnderscore = prefix.lastIndexOf("_");
        prefix = lastUnderscore > 0 ? prefix.substring(0, lastUnderscore) : "";
      }
      return prefix;
    }, keys[0] ?? "") || "cargo"
  );
}

// Holds no export placed, grouped by name prefix.
function groupByName(holds: CargoHold[], indices: number[]): CargoHoldGroup[] {
  const allNames = indices.map((i) => holds[i].name || "").filter((n) => n);

  // Pass 1: prefix matching (e.g. module_01 is prefix of module_01_walkway)
  const groupKeys = new Map<number, string>(
    indices.map((i) => {
      const name = holds[i].name || "";
      return [i, name ? getHoldGroupKey(name, allNames) : `hold_${i}`];
    }),
  );

  // Pass 2: merge single-hold groups by stripping last name segment
  // (e.g. cargo_front_left + cargo_front_right → cargo_front)
  const keyCounts = new Map<string, number>();
  for (const key of groupKeys.values()) {
    keyCounts.set(key, (keyCounts.get(key) || 0) + 1);
  }

  const singleKeys = [...keyCounts.entries()]
    .filter(([, count]) => count === 1)
    .map(([key]) => key);

  if (singleKeys.length > 1) {
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

    for (const [index, key] of groupKeys) {
      const merged = mergeMap.get(key);
      if (merged) groupKeys.set(index, merged);
    }
  }

  const groupMap = new Map<string, number[]>();
  for (const [index, key] of groupKeys) {
    if (!groupMap.has(key)) groupMap.set(key, []);
    groupMap.get(key)!.push(index);
  }

  return [...groupMap.entries()].map(([key, holdIndices]) => ({
    key,
    label: key.startsWith("hold_")
      ? `Hold ${key.slice(5)}`
      : humanizeHoldName(key),
    holdIndices,
    placed: false,
  }));
}

// Holds the hull export placed form one group per ship or module they were
// placed in, laid out as they sit there. The rest are grouped by name and laid
// out side by side, since nothing says where they sit.
export function groupCargoHolds(holds: CargoHold[]): CargoHoldGroup[] {
  const frames = new Map<string, number[]>();
  const loose: number[] = [];

  // The same module fitted twice repeats its holds: each copy is a frame of
  // its own, told apart by how often a hold's name has come up in it.
  const seen = new Map<string, number>();

  holds.forEach((hold, index) => {
    if (hold.placedIn && holdPlacement(hold)) {
      const name = `${hold.placedIn}:${hold.name ?? index}`;
      const copy = seen.get(name) ?? 0;
      seen.set(name, copy + 1);

      const frame = `${hold.placedIn}#${copy}`;
      if (!frames.has(frame)) frames.set(frame, []);
      frames.get(frame)!.push(index);
    } else {
      loose.push(index);
    }
  });

  const placed = [...frames.entries()].map(([frame, holdIndices]) => {
    const key = commonPrefix(holdIndices.map((i) => holds[i].name || ""));

    return {
      key: `${frame}:${key}`,
      label: humanizeHoldName(key),
      holdIndices,
      placed: true,
    };
  });

  return [...placed, ...groupByName(holds, loose)].sort(
    (a, b) => a.holdIndices[0] - b.holdIndices[0],
  );
}
