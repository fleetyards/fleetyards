import type { ModelModule } from "@/services/fyApi";

// The hull's module slots, in the order the editor lists their sockets.
export const moduleSlots = (modules: ModelModule[]) =>
  [
    ...new Set(
      modules.map((mod) => mod.slot).filter((slot): slot is string => !!slot),
    ),
  ].sort();
