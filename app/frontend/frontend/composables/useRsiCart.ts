import {
  FleetyardsSyncAction,
  type FleetyardsSyncCartPayload,
  type FleetyardsSyncCartResult,
} from "@/frontend/lib/FleetyardsSyncHandler";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import type { HangarPlanCartItem } from "@/services/fyApi";

export const RSI_CART_URL =
  "https://robertsspaceindustries.com/en/store/pledge/cart";

// Every item takes up to three requests to RSI, one after the other, after
// one for the store page. A request that times out leaves the items it
// managed in the cart unmarked, so it is sized to the list.
const CART_TIMEOUT_BASE = 15000;
const CART_TIMEOUT_PER_ITEM = 10000;

export type RsiCartEntry = { key: string; item: HangarPlanCartItem };

export type RsiCartAnswer =
  | { ok: true; results: FleetyardsSyncCartResult[] }
  | { ok: false; noSession: boolean };

export const useRsiCart = () => {
  const extension = useSyncExtension();

  // Off until the extension says it can: one from before the cart answers
  // "Unknown Action".
  const available = ref(false);

  onMounted(async () => {
    available.value = await extension.supports(
      FleetyardsSyncAction.ADD_TO_CART,
    );
  });

  const add = async (entries: RsiCartEntry[]): Promise<RsiCartAnswer> => {
    const answer = await extension
      .request(
        FleetyardsSyncAction.ADD_TO_CART,
        { items: entries.map(({ key, item }) => ({ ...item, id: key })) },
        CART_TIMEOUT_BASE + entries.length * CART_TIMEOUT_PER_ITEM,
      )
      .catch(() => undefined);

    const results = (answer?.payload as FleetyardsSyncCartPayload | undefined)
      ?.results;
    if (answer?.code !== 200 || !Array.isArray(results)) {
      return { ok: false, noSession: answer?.code === 401 };
    }

    return { ok: true, results };
  };

  return { available, add };
};
