import {
  HardpointCategoryEnum,
  type ComponentQuantumDrive,
  type Hardpoint,
} from "@/services/fyApi";

export const findQuantumDrive = (
  hardpoints: Hardpoint[] | undefined,
): ComponentQuantumDrive | undefined => {
  for (const hardpoint of hardpoints || []) {
    if (
      hardpoint.category === HardpointCategoryEnum.QUANTUMDRIVE &&
      hardpoint.component?.typeData
    ) {
      return hardpoint.component.typeData as ComponentQuantumDrive;
    }

    const nested = findQuantumDrive(hardpoint.hardpoints);

    if (nested) {
      return nested;
    }
  }

  return undefined;
};
