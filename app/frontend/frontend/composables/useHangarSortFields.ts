import { type MaybeRefOrGetter } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Vehicle } from "@/services/fyApi";
import { useHangarStore, HangarSortFieldsEnum } from "@/frontend/stores/hangar";

/**
 * The sorts the owner's own hangar offers as chips: the ones picked in the
 * display options, in the order the options list them.
 *
 * `include` names a sort that is shown whether it was picked or not -- the one
 * the hangar is in right now. A chip that is chosen but hidden would leave the
 * bar claiming no sort at all.
 *
 * `all` ignores the pick, for the places that choose among every sort.
 */
export const useHangarSortFields = ({
  include,
  all = false,
}: { include?: MaybeRefOrGetter<string | undefined>; all?: boolean } = {}) => {
  const { t } = useI18n();

  const hangarStore = useHangarStore();

  const label = (field: HangarSortFieldsEnum) => {
    if (field === HangarSortFieldsEnum.RANK) {
      return t("labels.vehicle.customOrder");
    }

    if (field === HangarSortFieldsEnum.NAME) {
      return t("labels.vehicle.name");
    }

    return t(`labels.hangarTable.columns.${field}`);
  };

  return computed<BaseTableCol<Vehicle>[]>(() => {
    const included = toValue(include)?.split(" ")[0];

    return Object.values(HangarSortFieldsEnum)
      .filter(
        (field) =>
          all || hangarStore.sortFields.includes(field) || field === included,
      )
      .map((field) => ({ name: field, label: label(field), sortable: true }));
  });
};
