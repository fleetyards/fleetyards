import type { Ref } from "vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  type ItemPickerSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import { InventoryCategoryEnum } from "@/services/fyApi";

type Options = {
  name: Ref<string | undefined>;
  category: Ref<string | undefined>;
  pickedItem: Ref<PickedItem | undefined>;
  setFieldValue: (field: "name" | "category", value: string) => void;
  // Whatever else a pick or a clear makes stale in the form, such as a stock
  // position chosen before it.
  onReset?: () => void;
};

/**
 * The item picker as a step of a form modal rather than a modal of its own:
 * there is only one app modal, and opening another would discard the form. The
 * picker takes the modal's body while `picking`, and the form stays mounted,
 * hidden, so nothing typed into it is lost. The form must carry
 * `ref="itemPickerForm"`.
 */
export const useItemPickerStep = ({
  name,
  category,
  pickedItem,
  setFieldValue,
  onReset,
}: Options) => {
  const { t } = useI18n();

  const picking = ref(false);

  // The form element, for the scrolling body it sits in.
  const form = useTemplateRef<HTMLFormElement>("itemPickerForm");

  const showPicker = (shown: boolean) => {
    // The body scrolls, and whichever view comes in starts at its top.
    const body = form.value?.closest(".modal-body");
    if (body) body.scrollTop = 0;

    picking.value = shown;
  };

  const pickTitle = t("headlines.logistics.pickItem");

  // Only raw resources carry a grade. A crafted part's worth lies in the
  // materials that went into it, which a single number cannot say. Nothing is
  // graded before the goods are named, whatever category the form starts on.
  const graded = computed(
    () => !!name.value && category.value === InventoryCategoryEnum.COMMODITY,
  );

  const categoryLabel = computed(() =>
    name.value ? t(`labels.logistics.categories.${category.value}`) : undefined,
  );

  // A reopened picker lands where the last pick came from.
  const pickerCategory = computed(() =>
    name.value ? category.value : undefined,
  );

  const applySelection = (selection: ItemPickerSelection) => {
    onReset?.();
    pickedItem.value = selection.item;

    setFieldValue("category", selection.category);
    setFieldValue("name", selection.name);
    showPicker(false);
  };

  const clearItem = () => {
    onReset?.();
    pickedItem.value = undefined;

    setFieldValue("name", "");
  };

  return {
    picking,
    showPicker,
    pickTitle,
    graded,
    categoryLabel,
    pickerCategory,
    applySelection,
    clearItem,
  };
};
