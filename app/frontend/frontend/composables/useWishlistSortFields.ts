import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle } from "@/services/fyApi";
import {
  useWishlistStore,
  WishlistSortFieldsEnum,
} from "@/frontend/stores/wishlist";
import {
  useSelectableSortFields,
  type SelectableSortFieldsOptions,
} from "@/frontend/composables/useSelectableSortFields";

export const useWishlistSortFields = (
  options: SelectableSortFieldsOptions = {},
) => {
  const { t } = useI18n();

  const wishlistStore = useWishlistStore();

  return useSelectableSortFields<Vehicle>(
    () =>
      Object.values(WishlistSortFieldsEnum).map((name) => ({
        name,
        label:
          name === WishlistSortFieldsEnum.NAME
            ? t("labels.vehicle.name")
            : t(`labels.hangarTable.columns.${name}`),
      })),
    () => wishlistStore.sortFields,
    options,
  );
};
