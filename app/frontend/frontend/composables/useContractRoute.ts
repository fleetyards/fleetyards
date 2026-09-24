import {
  type FleetContract,
  FleetContractDestinationHolderEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type ContractEnds = Pick<FleetContract, "source" | "destination" | "createdBy">;

// How a contract names where its goods go. A destination in the author's own
// hangar says whose it is: to a contractor it is somebody else's inventory,
// and the delivery waits for that person rather than for the fleet.
export const useContractRoute = () => {
  const { t } = useI18n();

  const destinationName = (contract: ContractEnds) => {
    const destination = contract.destination;
    if (!destination) return undefined;

    if (destination.holder !== FleetContractDestinationHolderEnum.USER) {
      return destination.name;
    }

    return t("labels.fleets.contracts.authorHangarInventory", {
      name: destination.name,
      username: contract.createdBy?.username ?? "",
    });
  };

  // A haul has both ends; the other kinds only have somewhere to deliver.
  const routeLabel = (contract: ContractEnds) => {
    const to = destinationName(contract);
    const from = contract.source?.name;

    if (!to) return undefined;

    return from ? `${from} → ${to}` : to;
  };

  return { destinationName, routeLabel };
};
