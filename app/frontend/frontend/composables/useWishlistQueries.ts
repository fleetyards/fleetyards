import { useApiClient } from "@/frontend/composables/useApiClient";
import { type HangarQuery } from "@/services/fyApi";
import { useQuery, useQueryClient, useMutation } from "@tanstack/vue-query";

export enum QueryKeysEnum {
  WISHLIST = "wishlist",
}

export const useWishlistQueries = () => {
  const { wishlist: wishlistService } = useApiClient();

  const queryClient = useQueryClient();

  const wishlistQuery = ({
    page,
    perPage,
    filters,
  }: {
    page: ComputedRef<string>;
    perPage: ComputedRef<string | undefined>;
    filters: ComputedRef<HangarQuery | undefined>;
  }) => {
    return useQuery(
      {
        refetchOnWindowFocus: false,
        queryKey: [QueryKeysEnum.WISHLIST, page, perPage, filters],
        queryFn: () => {
          return wishlistService.getWishlist({
            page: page.value,
            perPage: perPage.value,
            q: filters.value,
          });
        },
      },
      queryClient,
    );
  };

  const exportQuery = () => {
    return wishlistService.exportWishlist();
  };

  const destroyAllMutation = useMutation(
    {
      mutationFn: () => {
        return wishlistService.destroyWishlist();
      },
    },
    queryClient,
  );

  return {
    wishlistQuery,
    exportQuery,
    destroyAllMutation,
  };
};
