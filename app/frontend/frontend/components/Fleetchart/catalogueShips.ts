import type { Model } from "@/services/fyApi";
import type { FleetchartPlacements } from "@/shared/stores/fleetchart";
import type { FleetchartEntry } from "@/frontend/components/Fleetchart/geometry";

// A copy of the model under the placement's own id, as one model can be placed
// several times and everything in a chart tells its ships apart by id.
export type FleetchartCatalogueEntry = Model & { notOwned: true };

export const isCatalogueEntry = (entry: FleetchartEntry) =>
  "notOwned" in entry && entry.notOwned === true;

export const catalogueEntriesFrom = (
  placed: { id: string; modelId: string }[],
  models: Model[],
): FleetchartCatalogueEntry[] => {
  const byId = new Map(models.map((model) => [model.id, model]));

  return placed.flatMap(({ id, modelId }) => {
    const model = byId.get(modelId);

    return model ? [{ ...model, id, notOwned: true as const }] : [];
  });
};

export const cataloguePlacementsIn = (placements: FleetchartPlacements) =>
  Object.entries(placements).flatMap(([id, { modelId }]) =>
    modelId ? [{ id, modelId }] : [],
  );
