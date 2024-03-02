import { useApiClient } from "@/frontend/composables/useApiClient";
import { type ConfirmAccessInput } from "@/services/fyApi";
import { useMutation, useQueryClient } from "@tanstack/vue-query";

export const useSessionQueries = () => {
  const { sessions: sessionsService } = useApiClient();

  const queryClient = useQueryClient();

  const confirmAccessMutation = useMutation(
    {
      mutationFn: (requestBody: ConfirmAccessInput) => {
        return sessionsService.confirmAccess({
          requestBody,
        });
      },
    },
    queryClient,
  );

  return {
    confirmAccessMutation,
  };
};
