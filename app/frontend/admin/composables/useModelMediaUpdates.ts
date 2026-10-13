import { type MaybeRefOrGetter, toValue } from "vue";
import { useQueryClient } from "@tanstack/vue-query";
import {
  useSubscription,
  type ConnectEvent,
} from "@/shared/composables/useSubscription";
import {
  AdminModelMediaChannel,
  type AdminModelMediaData,
} from "@/services/fyCableAdmin/channels/AdminModelMediaChannel";
import { getModelQueryKey } from "@/services/fyAdminApi";

// Each settled crop has replaced a blob the loaded model still names, so the
// model is fetched again rather than patched: the payload only says which views
// are left, the fresh URLs come from the API.
export const useModelMediaUpdates = (modelId: MaybeRefOrGetter<string>) => {
  const queryClient = useQueryClient();

  const refetch = () => {
    void queryClient.invalidateQueries({
      queryKey: getModelQueryKey(toValue(modelId)),
    });
  };

  // The channel has no replay, so a crop that settled while the socket was
  // down would leave the page waiting on it for good.
  const connected = ({ reconnect }: ConnectEvent) => {
    if (reconnect) {
      refetch();
    }
  };

  useSubscription({
    channel: AdminModelMediaChannel,
    received: (data: AdminModelMediaData) => {
      if (data.modelId === toValue(modelId)) {
        refetch();
      }
    },
    connected,
  });
};
