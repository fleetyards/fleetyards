import { useI18n } from "@/shared/composables/useI18n";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import { type Component } from "@/services/fyApi";

// What the catalogue row and card both say about a component besides its
// figures, so the two layouts of one list never disagree.
export const useComponentFacts = (component: MaybeRefOrGetter<Component>) => {
  const { t, tExists } = useI18n();

  // The payload carries the game's own category string ("quantumdrive"). The
  // hardpoint list already names all of them in every locale, so the label
  // comes from there -- falling back to the raw key for a category a patch
  // introduces before anyone writes a label for it.
  const categoryLabel = computed(() => {
    const key = toValue(component).category;
    if (!key) return undefined;

    const path = `labels.hardpoint.categories.${key}`;

    return tExists(path) ? t(path) : key;
  });

  const badges = computed<RowListItemBadge[]>(() => {
    const record = toValue(component);
    const list: RowListItemBadge[] = [];

    if (record.size) {
      list.push({
        key: "size",
        label: t("labels.hardpoint.size"),
        value: String(record.size),
      });
    }

    if (record.gradeLabel) {
      list.push({
        key: "grade",
        label: t("labels.component.grade"),
        value: record.gradeLabel,
      });
    }

    return list;
  });

  return { categoryLabel, badges };
};
