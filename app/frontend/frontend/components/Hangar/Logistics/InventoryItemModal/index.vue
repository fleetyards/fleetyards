<script lang="ts">
export default {
  name: "HangarLogisticsInventoryItemModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import {
  type FilterOption,
  type HangarInventory,
  hangarInventoryStock as fetchStock,
  useCreateHangarInventoryItem,
  HangarInventoryItemCreateInputCategory,
  HangarInventoryItemCreateInputUnit,
} from "@/services/fyApi";

type StockItem = {
  name: string;
  category: string;
  unit: string;
  netQuantity: number;
};

type Props = {
  inventory: HangarInventory;
  initialEntryType?: "deposit" | "withdrawal";
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { categoryOptions, unitOptions, entryTypeOptions } =
  useInventoryOptions();

const submitting = ref(false);
const entryType = ref<"deposit" | "withdrawal">(
  props.initialEntryType ?? "deposit",
);
const selectedStockItem = ref<string | undefined>(undefined);
const selectedExistingItem = ref<string | undefined>(undefined);
const stockItems = ref<StockItem[]>([]);

const isDeposit = computed(() => entryType.value === "deposit");

const modalTitle = computed(() =>
  isDeposit.value
    ? t("headlines.logistics.deposit")
    : t("headlines.logistics.withdrawal"),
);

const validationSchema = {
  name: "required|min:2",
  quantity: "required|min_value:0",
};

const { defineField, handleSubmit, setFieldValue } = useForm({
  initialValues: {
    name: "",
    category: HangarInventoryItemCreateInputCategory.commodity,
    quantity: 1,
    unit: HangarInventoryItemCreateInputUnit.scu,
    quality: 0,
    image: undefined as string | undefined,
    notes: "",
  },
});

const [name, nameProps] = defineField("name");
const [category, categoryProps] = defineField("category");
const [quantity, quantityProps] = defineField("quantity");
const [unit] = defineField("unit");
const [quality, qualityProps] = defineField("quality");
const [image, imageProps] = defineField("image");
const [notes, notesProps] = defineField("notes");

const loadStockItems = async () => {
  try {
    const data = await fetchStock(props.inventory.slug);
    stockItems.value = data as unknown as StockItem[];
  } catch {
    stockItems.value = [];
  }
};

const stockItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item) => ({
    value: `${item.name}|||${item.category}|||${item.unit}`,
    label: `${item.name} (${item.netQuantity} ${t(`labels.logistics.units.${item.unit}`)})`,
  })),
);

const existingItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item) => ({
    value: `${item.name}|||${item.category}|||${item.unit}`,
    label: `${item.name} (${t(`labels.logistics.categories.${item.category}`)})`,
  })),
);

onMounted(() => {
  void loadStockItems();
});

const applyPickedItem = (val: string | undefined) => {
  if (!val) return;

  const [itemName, itemCategory, itemUnit] = val.split("|||");
  setFieldValue("name", itemName);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", itemCategory as any);
  setFieldValue("unit", itemUnit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
};

watch(selectedExistingItem, applyPickedItem);
watch(selectedStockItem, applyPickedItem);

watch(entryType, (val) => {
  if (val === "withdrawal") {
    void loadStockItems();
  }
  selectedStockItem.value = undefined;
});

const selectedStockMax = computed(() => {
  if (!selectedStockItem.value) return undefined;

  const [itemName, itemCategory, itemUnit] =
    selectedStockItem.value.split("|||");

  return stockItems.value.find(
    (s) =>
      s.name === itemName && s.category === itemCategory && s.unit === itemUnit,
  )?.netQuantity;
});

const createMutation = useCreateHangarInventoryItem();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({
      hangarInventorySlug: props.inventory.slug,
      data: {
        name: values.name,
        category: values.category,
        quantity:
          values.category === "commodity"
            ? Number(values.quantity)
            : Math.round(Number(values.quantity)),
        unit: values.unit,
        entryType: entryType.value,
        quality: values.quality != null ? Number(values.quality) : undefined,
        image: values.image || undefined,
        notes: values.notes || undefined,
      },
    })
    .then(() => {
      displaySuccess({
        text: isDeposit.value
          ? t("messages.logistics.inventoryItem.deposit.success")
          : t("messages.logistics.inventoryItem.withdrawal.success"),
      });
      comlink.emit("hangar-inventory-item-created");
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: isDeposit.value
          ? t("messages.logistics.inventoryItem.deposit.failure")
          : t("messages.logistics.inventoryItem.withdrawal.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="modalTitle">
    <form id="create-hangar-inventory-item-form" @submit.prevent="onSubmit">
      <FilterGroup
        v-model="entryType"
        :options="entryTypeOptions"
        :label="t('labels.logistics.entryType')"
        name="entryType"
        :searchable="false"
      />

      <!-- Withdrawal: pick from existing stock -->
      <template v-if="!isDeposit">
        <FilterGroup
          v-model="selectedStockItem"
          :options="stockItemOptions"
          :label="t('labels.logistics.selectItem')"
          name="stockItem"
          :searchable="true"
        />

        <p v-if="selectedStockMax !== undefined" class="text-muted">
          {{ t("labels.logistics.currentStock") }}:
          {{ selectedStockMax }}
          {{ t(`labels.logistics.units.${unit}`) }}
        </p>
      </template>

      <!-- Deposit: pick existing or manual entry -->
      <template v-if="isDeposit">
        <FilterGroup
          v-if="existingItemOptions.length"
          v-model="selectedExistingItem"
          :options="existingItemOptions"
          :label="t('labels.logistics.existingItem')"
          name="existingItem"
          :searchable="true"
          :nullable="true"
        />
        <FormInput
          v-model="name"
          v-bind="nameProps"
          name="name"
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
      </template>

      <div class="row">
        <div class="col-6">
          <FormInput
            v-model="quantity"
            v-bind="quantityProps"
            name="quantity"
            :type="InputTypesEnum.NUMBER"
            :rules="validationSchema.quantity"
            :label="t('labels.logistics.quantity')"
            :min="0"
            no-placeholder
            :max="!isDeposit && selectedStockMax ? selectedStockMax : undefined"
          >
            <template #suffix>
              <template v-if="isDeposit">
                <select v-model="unit" class="base-input__suffix-select">
                  <option
                    v-for="opt in unitOptions"
                    :key="String(opt.value)"
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </option>
                </select>
              </template>
              <span v-else class="base-input__suffix-text">
                {{ t(`labels.logistics.units.${unit}`) }}
              </span>
            </template>
          </FormInput>
        </div>

        <div class="col-6">
          <FormInput
            v-model="quality"
            v-bind="qualityProps"
            name="quality"
            :type="InputTypesEnum.NUMBER"
            :label="t('labels.logistics.quality')"
            :min="0"
            :step="1"
            :max="1000"
            no-placeholder
          />
        </div>
      </div>

      <FormFileInput
        v-model="image"
        v-bind="imageProps"
        name="image"
        :label="t('labels.logistics.image')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />

      <FormTextarea
        v-model="notes"
        v-bind="notesProps"
        name="notes"
        :label="t('labels.logistics.notes')"
        :placeholder="t('labels.logistics.notesPlaceholder')"
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
          {{
            isDeposit
              ? t("actions.logistics.deposit")
              : t("actions.logistics.withdraw")
          }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
