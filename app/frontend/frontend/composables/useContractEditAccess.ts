import type { FleetContract } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { checkAccess } from "@/shared/utils/Access";

/*
 * Whether the reader may change a contract's terms, publish it or cancel it:
 * the fleet's contract privilege, or authorship of a personal one. The same
 * rule FleetContractPolicy applies, so the page offers what the API accepts.
 */
export const useContractEditAccess = (
  contract: MaybeRefOrGetter<
    Pick<FleetContract, "personal" | "createdBy"> | undefined
  >,
  resourceAccess: MaybeRefOrGetter<string[] | undefined>,
) => {
  const sessionStore = useSessionStore();

  return computed(() => {
    if (
      checkAccess(toValue(resourceAccess), [
        "fleet:manage",
        "fleet:contracts:manage",
        "fleet:contracts:update",
      ])
    ) {
      return true;
    }

    const value = toValue(contract);
    const userId = sessionStore.currentUser?.id;

    return !!value?.personal && !!userId && value.createdBy?.id === userId;
  });
};
