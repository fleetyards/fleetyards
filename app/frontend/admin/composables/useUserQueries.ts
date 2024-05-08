import { useApiClient } from "@/admin/composables/useApiClient";
import {
  type ApiError,
  type Users,
  type UserQuery,
} from "@/services/fyAdminApi";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  USERS = "users",
}

export const useUserQueries = () => {
  const { users: usersService } = useApiClient();

  const queryClient = useQueryClient();

  const usersQuery = ({
    page,
    perPage,
    q,
    s,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    q: ComputedRef<UserQuery | undefined>;
    s: ComputedRef<string[] | undefined>;
  }) => {
    return useQuery<Users, ApiError>(
      {
        queryKey: [QueryKeysEnum.USERS, page, perPage, q, s],
        queryFn: () =>
          usersService.users({
            page: page.value,
            perPage: perPage.value,
            q: q.value,
            s: s.value,
          }),
      },
      queryClient,
    );
  };

  return {
    usersQuery,
  };
};
