import { useI18n } from "@/shared/composables/useI18n";

// The name a component category goes by, or the category itself where no
// translation names it.
export const useComponentCategoryLabel = () => {
  const { t, tExists } = useI18n();

  return (category: string) => {
    const path = `labels.hardpoint.categories.${category}`;

    return tExists(path) ? t(path) : category;
  };
};
