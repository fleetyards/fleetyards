import { useI18n } from "@/shared/composables/useI18n";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { type Equipment } from "@/services/fyApi";

// Shared by the catalogue row and card, so the two layouts of one list never
// disagree about an item.
export const useEquipmentBadges = (equipment: MaybeRefOrGetter<Equipment>) => {
  const { t } = useI18n();

  return computed<RowListItemBadge[]>(() => {
    const record = toValue(equipment);
    const list: RowListItemBadge[] = [];

    if (record.slotLabel) {
      list.push({
        key: "slot",
        label: t("labels.equipment.slot"),
        value: record.slotLabel,
      });
    }

    if (record.size) {
      list.push({
        key: "size",
        label: t("labels.equipment.size"),
        value: record.size,
      });
    }

    if (record.grade) {
      list.push({
        key: "grade",
        label: t("labels.equipment.grade"),
        value: record.grade,
      });
    }

    return list;
  });
};
