export type CapacityGroup = {
  key: string;
  name: string;
  count: number;
  capacity: number;
  share: number;
};

type Container = {
  componentName?: string | null;
  capacity?: number;
};

/**
 * Containers grouped by component, for a card that lists them with a count and
 * a bar each: the external fuel pods, the ore pods, the salvage storage. Keyed
 * by name and capacity together, so two containers that share a name -- or
 * have none, as salvage storage does -- but hold different amounts stay apart.
 */
export const groupByCapacity = (
  containers: Container[],
  fallbackName: string,
): CapacityGroup[] => {
  const groups = new Map<string, CapacityGroup>();
  const total = containers.reduce(
    (sum, container) => sum + (container.capacity || 0),
    0,
  );

  containers.forEach((container) => {
    const name = container.componentName || fallbackName;
    const capacity = container.capacity || 0;
    const key = `${name}|${capacity}`;
    const group = groups.get(key);

    if (group) {
      group.count += 1;
    } else {
      groups.set(key, { key, name, count: 1, capacity, share: 0 });
    }
  });

  return [...groups.values()]
    .map((group) => ({
      ...group,
      share: total
        ? Math.round(((group.capacity * group.count) / total) * 100)
        : 0,
    }))
    .sort((a, b) => b.capacity * b.count - a.capacity * a.count);
};
