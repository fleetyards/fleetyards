<script lang="ts">
export default {
  name: "LogisticsStockItemModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useInventoryOptions,
  unitsForCategory,
} from "@/frontend/composables/useInventoryOptions";
import type {
  FilterOption,
  InventoryStockPosition,
  InventoryStockPositionInput,
} from "@/services/fyApi";

type Props = {
  stockItem: InventoryStockPosition;
  onSave: (payload: InventoryStockPositionInput) => Promise<unknown>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { categoryOptions } = useInventoryOptions();
const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const validationSchema = {
  name: "required|min:2",
};

const { defineField, handleSubmit, setFieldValue } = useForm({
  initialValues: {
    name: props.stockItem.name,
    category: props.stockItem.category as string,
    unit: props.stockItem.unit as string,
  },
});

const [name, nameProps] = defineField("name");
const [category, categoryProps] = defineField("category");
const [unit] = defineField("unit");

const unitOptions = computed<FilterOption[]>(() =>
  unitsForCategory(category.value).map((value) => ({
    value,
    label: t(`labels.logistics.units.${value}`),
  })),
);

// Same pairing the API enforces: a category change drags the unit with it.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === unit.value)) return;

  setFieldValue("unit", options[0].value as string);
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  try {
    await props.onSave({
      name: values.name,
      category: values.category as InventoryStockPositionInput["category"],
      unit: values.unit as InventoryStockPositionInput["unit"],
    });

    comlink.emit("close-modal");
  } catch {
    displayAlert({
      text: t("messages.logistics.stockItem.update.failure"),
    });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal :title="t('headlines.logistics.editStockItem')">
    <form id="edit-stock-item-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="name"
        translation-key="logistics.itemName"
        :rules="validationSchema.name"
        :label="t('labels.logistics.itemName')"
      />
      <FilterGroup
        v-model="category"
        v-bind="categoryProps"
        name="category"
        :options="categoryOptions"
        :label="t('labels.logistics.category')"
        :searchable="false"
      />
      <FilterGroup
        v-if="unitOptions.length > 1"
        v-model="unit"
        name="unit"
        :options="unitOptions"
        :label="t('labels.logistics.unit')"
        :searchable="false"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
