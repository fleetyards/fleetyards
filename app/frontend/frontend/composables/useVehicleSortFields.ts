import { useI18n } from "@/shared/composables/useI18n";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import { type Vehicle } from "@/services/fyApi";

/**
 * The sorts a hangar offers above its grid.
 *
 * Grid view had no way to sort at all: column headings are the only sort
 * control the site has, so a hangar shown as cards -- which is the only way a
 * public hangar is ever shown -- dropped all eighteen of them.
 *
 * A chosen few rather than all eighteen. A line of eighteen chips is a wall,
 * and these are the ones a card already shows. The labels are the hangar
 * table's own, so both views name a sort the same way.
 *
 * `flagship` is deliberately absent even though it leads the default order: it
 * is a yes/no, so sorting by it is a filter wearing the wrong clothes.
 */
export const useVehicleSortFields = () => {
  const { t } = useI18n();

  return computed<BaseTableCol<Vehicle>[]>(() =>
    (
      [
        ["name", t("labels.vehicle.name")],
        [
          "modelManufacturerName",
          t("labels.hangarTable.columns.modelManufacturerName"),
        ],
        ["modelLength", t("labels.hangarTable.columns.modelLength")],
        ["modelCargo", t("labels.hangarTable.columns.modelCargo")],
        ["modelPrice", t("labels.hangarTable.columns.modelPrice")],
        [
          "modelProductionStatus",
          t("labels.hangarTable.columns.modelProductionStatus"),
        ],
      ] as [string, string][]
    ).map(([name, label]) => ({ name, label, sortable: true })),
  );
};
