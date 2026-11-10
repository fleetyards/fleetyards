import type { FleetFleetchart } from "@/services/fyApi";
import type {
  FleetchartShip,
  FleetchartSlimModel,
} from "@/frontend/components/Fleetchart/geometry";

// The response sends each model and module package once and points at them, so a
// fleet of thousands stays small; the chart wants each ship to carry its own.
// A model is cloned per ship, as the chart merges its pictures into it, and starts
// with no pictures rather than none at all, as the older charts read them directly.
export const joinFleetchartShips = (
  data: FleetFleetchart | undefined,
): FleetchartShip[] => {
  if (!data) {
    return [];
  }

  const models = new Map(data.models.map((model) => [model.id, model]));
  const modulePackages = new Map(
    data.modulePackages.map((modulePackage) => [
      modulePackage.id,
      modulePackage,
    ]),
  );

  return data.items.flatMap(({ modelId, modulePackageId, ...ship }) => {
    const model = models.get(modelId);

    if (!model) {
      return [];
    }

    return [
      {
        ...ship,
        model: { ...model, media: {} },
        modulePackage: modulePackageId
          ? modulePackages.get(modulePackageId)
          : undefined,
      },
    ];
  });
};

// One entry per model, in the order its first ship came.
export const modelsOfShips = (
  ships: FleetchartShip[],
): FleetchartSlimModel[] => {
  const seen = new Map<string, FleetchartSlimModel>();

  ships.forEach(({ model }) => {
    if (!seen.has(model.id)) {
      seen.set(model.id, { ...model });
    }
  });

  return [...seen.values()];
};
