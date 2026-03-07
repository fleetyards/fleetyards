export function humanizeHoldName(name: string): string {
  return (
    name
      .replace(/^hardpoint_(?:cargogrid|cargo(?:door)?|door_cargo)[-_]?/, "")
      .replace(/[-_]hardpoint_cargo[-_]?grid$/, "")
      .replace(/^cargogrid_/, "")
      .replace(/[_-]/g, " ")
      .trim()
      .replace(/\b\w/g, (c) => c.toUpperCase()) || "Cargo"
  );
}

function getHoldGroupKey(name: string, allNames: string[]): string {
  if (!name) return name;
  for (const other of allNames) {
    if (other !== name && name.startsWith(other + "_")) {
      return other;
    }
  }
  return name;
}

export function groupByHoldName<T>(
  items: T[],
  getName: (item: T) => string,
): { key: string; label: string; items: T[] }[] {
  const allNames = items.map(getName).filter((n) => n);

  // Pass 1: prefix matching (e.g. module_01 is prefix of module_01_walkway)
  const groupKeys: string[] = items.map((item, idx) => {
    const name = getName(item);
    if (!name) return `unnamed_${idx}`;
    return getHoldGroupKey(name, allNames);
  });

  // Pass 2: merge single-item groups by stripping last name segment
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

  // Build groups maintaining insertion order
  const groupMap = new Map<string, T[]>();
  const groupOrder: string[] = [];

  for (let i = 0; i < items.length; i++) {
    const key = groupKeys[i];
    if (!groupMap.has(key)) {
      groupMap.set(key, []);
      groupOrder.push(key);
    }
    groupMap.get(key)!.push(items[i]);
  }

  return groupOrder.map((key) => ({
    key,
    label: key.startsWith("unnamed_") ? "Cargo" : humanizeHoldName(key),
    items: groupMap.get(key)!,
  }));
}
