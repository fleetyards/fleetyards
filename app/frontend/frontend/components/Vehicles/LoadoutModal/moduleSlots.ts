import type { ModelModule } from "@/services/fyApi";

// The hull's module slots in the order the editor lists them; the comparison
// panel falls back to the first.
export const moduleSlots = (modules: ModelModule[]) =>
  [
    ...new Set(
      modules.map((mod) => mod.slot).filter((slot): slot is string => !!slot),
    ),
  ].sort();
