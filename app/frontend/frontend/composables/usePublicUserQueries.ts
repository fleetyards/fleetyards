import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  PUBLIC_USER = "publicUser",
}

export const usePublicUserQueries = () => {
  const { publicUser: publicUserService } = useApiClient();

  const queryClient = useQueryClient();

  const publicUserQuery = ({ username }: { username: string }) => {
    return useQuery(
      {
        refetchOnWindowFocus: false,
        queryKey: [QueryKeysEnum.PUBLIC_USER, username],
        queryFn: () => {
          return publicUserService.publicUser({
            username,
          });
        },
      },
      queryClient,
    );
  };

  return {
    publicUserQuery,
  };
};
