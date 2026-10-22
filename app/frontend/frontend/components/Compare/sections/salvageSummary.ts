import type { ComponentSalvageController, Hardpoint } from "@/services/fyApi";

export type SalvageSummary = {
  heads: number;
  fieldSupporters: number;
  crate?: { size: number; fillTimePerScu?: number };
  structural?: Pick<
    ComponentSalvageController,
    "fracture" | "disintegration" | "fieldAlignment"
  >;
  scrapingResource?: string;
};

const controllersIn = (
  hardpoints: Hardpoint[] | undefined,
): ComponentSalvageController[] =>
  (hardpoints || []).flatMap((hardpoint) => {
    const data = hardpoint.component?.typeData as
      ComponentSalvageController | undefined;

    return [
      ...(data?.salvageController ? [data] : []),
      ...controllersIn(
        hardpoint.hardpoints?.length
          ? hardpoint.hardpoints
          : hardpoint.component?.hardpoints,
      ),
    ];
  });

// A ship's salvage, read off its salvage controllers: the Moth has one per
// turret cab and one for the tool arm, and each says something different -- the
// cabs pack the crates, the arm fractures and grinds a hull down.
export const salvageSummary = (
  hardpoints: Hardpoint[] | undefined,
): SalvageSummary | undefined => {
  // A tractor-only controller -- a C1's, an SRV's -- names a head too, but its
  // head is the tractor beam: it packs no crates and works no hull.
  const controllers = controllersIn(hardpoints).filter(
    (controller) =>
      controller.crates || controller.disintegration || controller.fracture,
  );

  if (!controllers.length) {
    return undefined;
  }

  const crateMaker = controllers
    .filter((controller) => controller.crates?.maxSize)
    .sort((a, b) => (b.crates?.maxSize ?? 0) - (a.crates?.maxSize ?? 0))[0];

  const structural = controllers
    .filter((controller) => controller.disintegration || controller.fracture)
    .sort(
      (a, b) =>
        (b.disintegration?.maxRadius ?? 0) - (a.disintegration?.maxRadius ?? 0),
    )[0];

  return {
    heads: controllers.reduce(
      (sum, controller) => sum + (controller.heads ?? 0),
      0,
    ),
    fieldSupporters: Math.max(
      0,
      ...controllers.map(
        (controller) => controller.fieldSupportersRequired ?? 0,
      ),
    ),
    crate: crateMaker?.crates?.maxSize
      ? {
          size: crateMaker.crates.maxSize,
          fillTimePerScu: crateMaker.crates.fillTimePerScu,
        }
      : undefined,
    structural: structural
      ? {
          fracture: structural.fracture,
          disintegration: structural.disintegration,
          fieldAlignment: structural.fieldAlignment,
        }
      : undefined,
    scrapingResource: controllers.find(
      (controller) => controller.scrapingResource,
    )?.scrapingResource,
  };
};
