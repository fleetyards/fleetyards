<script lang="ts">
export default {
  name: "LogisticsInventoryItemModal",
};
</script>

<script lang="ts" setup>
import { useField, useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BaseSelectVariantsEnum } from "@/shared/components/base/Select/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import { useItemPickerStep } from "@/frontend/composables/useItemPickerStep";
import ItemPicker from "@/frontend/components/Logistics/ItemPicker/index.vue";
import ItemPickerField from "@/frontend/components/Logistics/ItemPickerField/index.vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import {
  type FilterOption,
  type InventoryItemCreateInput,
  hangarInventoryStock,
  vehicleInventoryStock,
  useCreateHangarInventoryItem,
  useCreateVehicleInventoryItem,
  InventoryCategoryEnum,
  InventoryUnitEnum,
} from "@/services/fyApi";
import type { InventoryTarget } from "@/frontend/types/logistics";

type StockItem = {
  id: string;
  name: string;
  category: string;
  unit: string;
  netQuantity: number;
  // The grade this row of stock is held at; a position holding several grades
  // is one row per grade.
  quality?: number | null;
};

type Props = {
  target: InventoryTarget;
  initialEntryType?: "deposit" | "withdrawal";
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { unitOptionsFor, entryTypeOptions } = useInventoryOptions();

const submitting = ref(false);
const entryType = ref<"deposit" | "withdrawal">(
  props.initialEntryType ?? "deposit",
);
const selectedStockItem = ref<string | undefined>(undefined);
const selectedExistingItem = ref<string | undefined>(undefined);
const stockItems = ref<StockItem[]>([]);
// One slot for whichever catalogue the item came from, so the submit and the
// name-edit rule stay single rather than growing a branch per item type.
const pickedItem = ref<PickedItem | undefined>(undefined);

// Picking an existing position copies its unit but drops the catalogue
// reference on purpose -- a new entry is not a reference to what the old ones
// pointed at. That reference is also what says `units` is on offer, so the
// position is remembered here instead: without it the options watcher drags a
// piece-counted position back to SCU and the entry lands on a different
// position than the one that was picked.
const selectedPosition = ref<StockItem | undefined>(undefined);

// The position's own unit is the evidence, not its item: the stock list does
// not carry the catalogue reference, and it does not need to. The API accepted
// the position as it stands, so whatever unit it is recorded in is a unit this
// commodity may be recorded in.
const countedSelection = computed(() =>
  pickedItem.value
    ? pickedItem.value.counted
    : selectedPosition.value?.unit === "units" || undefined,
);

const isDeposit = computed(() => entryType.value === "deposit");

const modalTitle = computed(() => {
  if (picking.value) return pickTitle.value;

  return isDeposit.value
    ? t("headlines.logistics.deposit")
    : t("headlines.logistics.withdrawal");
});

const validationSchema = {
  name: "required|min:2",
  quantity: "required|min_value:0",
  quality: "required|between:0,1000",
};

// Left blank rather than defaulted, so the amount and grade of a deposit are
// entered for the goods at hand instead of slipping through as a 1 and a 0
// nobody chose. A withdrawal takes its grade from the stock row it picks.

const initialValues = {
  name: "",
  category: InventoryCategoryEnum.COMMODITY as InventoryCategoryEnum,
  quantity: undefined as number | undefined,
  unit: InventoryUnitEnum.SCU as InventoryUnitEnum,
  quality: undefined as number | undefined,
  image: undefined as string | undefined,
  notes: "",
};

const { defineField, handleSubmit, setFieldValue, values } = useForm({
  initialValues,
});

// Named by the picker or by an existing position rather than typed, so the
// rule lives here instead of on an input. A withdrawal names its goods by the
// stock position it picks, so only a deposit asks.
const { value: name, errorMessage: nameError } = useField<string>(
  "name",
  computed(() => (isDeposit.value ? validationSchema.name : "")),
  { label: t("labels.logistics.itemPicker.field") },
);
const [category] = defineField("category");

const {
  picking,
  showPicker,
  pickTitle,
  graded,
  categoryLabel,
  pickerCategory,
  applySelection,
  clearItem,
} = useItemPickerStep({
  name,
  category,
  pickedItem,
  setFieldValue,
  onReset: () => {
    selectedExistingItem.value = undefined;
    selectedPosition.value = undefined;
  },
});

const [quantity, quantityProps] = defineField("quantity");
const [unit] = defineField("unit");
const [quality, qualityProps] = defineField("quality");
const [image, imageProps] = defineField("image");
const [notes, notesProps] = defineField("notes");

// A counted commodity is the only thing that puts `units` on offer under the
// commodity category, and only the picked item knows -- so the options follow
// the pick as well as the category.
const unitOptions = unitOptionsFor(category, countedSelection);

// The category dictates which units make sense, so a category change pulls the
// unit along instead of leaving an impossible pairing the API would reject.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === unit.value)) return;

  setFieldValue("unit", options[0].value as InventoryUnitEnum);
});

const fetchStock = () =>
  props.target.kind === "hangar"
    ? hangarInventoryStock(props.target.slug)
    : vehicleInventoryStock(props.target.vehicleId);

const loadStockItems = async () => {
  try {
    const data = await fetchStock();
    stockItems.value = data as unknown as StockItem[];
  } catch {
    stockItems.value = [];
  }
};

// Keyed by row rather than by position: a position holding several grades is
// several rows, and a withdrawal comes out of one of them.
const stockItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item, index) => ({
    value: String(index),
    label:
      item.quality != null && item.category === "commodity"
        ? `${item.name} · ${t("labels.logistics.qualityShort", { quality: item.quality })} (${item.netQuantity} ${t(`labels.logistics.units.${item.unit}`)})`
        : `${item.name} (${item.netQuantity} ${t(`labels.logistics.units.${item.unit}`)})`,
  })),
);

const stockRowAt = (key?: string | null) =>
  key ? stockItems.value[Number(key)] : undefined;

const existingItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item) => ({
    value: item.id,
    label: `${item.name} (${t(`labels.logistics.categories.${item.category}`)})`,
  })),
);

onMounted(() => {
  void loadStockItems();
});

const applyPickedItem = (val: string | undefined) => {
  if (!val) return;

  const picked = stockItems.value.find((item) => item.id === val);
  if (!picked) return;

  selectedPosition.value = picked;
  setFieldValue("name", picked.name);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", picked.category as any);
  setFieldValue("unit", picked.unit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
  pickedItem.value = undefined;
};

watch(selectedExistingItem, applyPickedItem);

watch(selectedStockItem, (val) => {
  const picked = stockRowAt(val);
  if (!picked) return;

  selectedPosition.value = picked;
  setFieldValue("name", picked.name);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", picked.category as any);
  setFieldValue("unit", picked.unit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
  pickedItem.value = undefined;
  // The grade of the row it comes out of, blank for ungraded stock.
  setFieldValue("quality", picked.quality ?? undefined);
});

watch(entryType, (val) => {
  if (val === "withdrawal") {
    void loadStockItems();
  }
  selectedStockItem.value = undefined;
  selectedPosition.value = undefined;
  pickedItem.value = undefined;
});

// Ungraded stock is held as NULL, and an omitted grade is stored as 0 -- a
// group no deposit occupies -- so a withdrawal out of it says null outright.
const withdrawnUngraded = computed(() => (isDeposit.value ? undefined : null));

const selectedStockMax = computed(() => {
  return stockRowAt(selectedStockItem.value)?.netQuantity;
});

const createHangarItem = useCreateHangarInventoryItem();
const createVehicleItem = useCreateVehicleInventoryItem();

const createItem = (data: InventoryItemCreateInput) =>
  props.target.kind === "hangar"
    ? createHangarItem.mutateAsync({
        hangarInventorySlug: props.target.slug,
        data,
      })
    : createVehicleItem.mutateAsync({
        vehicleId: props.target.vehicleId,
        data,
      });

// Deposit or withdrawal and the position or item picked live outside the form.
const entryChoice = computed(() => ({
  entryType: entryType.value,
  selectedStockItem: selectedStockItem.value,
  selectedExistingItem: selectedExistingItem.value,
  pickedItemId: pickedItem.value?.id,
}));

const formDirty = useFormDirty(values, initialValues);
const choiceDirty = useFormDirty(entryChoice, { ...entryChoice.value });

useModalDirty(() => formDirty.value || choiceDirty.value);

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createItem({
    name: values.name,
    category: values.category,
    quantity:
      values.category === "commodity"
        ? Number(values.quantity)
        : Math.round(Number(values.quantity)),
    unit: values.unit,
    entryType: entryType.value,
    quality:
      graded.value && values.quality != null
        ? Number(values.quality)
        : withdrawnUngraded.value,
    image: values.image || undefined,
    notes: values.notes || undefined,
    itemType: pickedItem.value?.type,
    itemId: pickedItem.value?.id,
  })
    .then(() => {
      displaySuccess({
        text: isDeposit.value
          ? t("messages.logistics.inventoryItem.deposit.success")
          : t("messages.logistics.inventoryItem.withdrawal.success"),
      });
      comlink.emit("inventory-item-created");
      comlink.emit("close-modal", true);
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
  <Modal :title="modalTitle" :flush="picking">
    <ItemPicker
      v-if="picking"
      :category="pickerCategory"
      @select="applySelection"
    />

    <!-- Hidden rather than unmounted while the catalogue is open, so nothing
         typed into it is lost. -->
    <form
      v-show="!picking"
      id="create-hangar-inventory-item-form"
      ref="itemPickerForm"
      @submit.prevent="onSubmit"
    >
      <BaseSelect
        v-model="entryType"
        :options="entryTypeOptions"
        :label="t('labels.logistics.entryType')"
        name="entryType"
        :searchable="false"
      />

      <!-- Withdrawal: pick from existing stock -->
      <template v-if="!isDeposit">
        <BaseSelect
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
        <BaseSelect
          v-if="existingItemOptions.length"
          v-model="selectedExistingItem"
          :options="existingItemOptions"
          :label="t('labels.logistics.existingItem')"
          name="existingItem"
          :searchable="true"
          :nullable="true"
        />
        <ItemPickerField
          name="catalogueItem"
          :value="name"
          :category-label="categoryLabel"
          :error="nameError"
          @open="showPicker(true)"
          @clear="clearItem"
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
              <template v-if="isDeposit && unitOptions.length > 1">
                <BaseSelect
                  v-model="unit"
                  :options="unitOptions"
                  :label="t('labels.logistics.unit')"
                  :variant="BaseSelectVariantsEnum.AFFIX"
                  name="unit"
                  no-label
                />
              </template>
              <span v-else class="base-input__suffix-text">
                {{ t(`labels.logistics.units.${unit}`) }}
              </span>
            </template>
          </FormInput>
        </div>

        <div v-if="graded" class="col-6">
          <FormInput
            v-model="quality"
            v-bind="qualityProps"
            name="quality"
            :type="InputTypesEnum.NUMBER"
            :rules="isDeposit ? validationSchema.quality : ''"
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
      <Btn
        v-if="picking"
        :variant="BtnVariantsEnum.BARE"
        data-test="item-picker-back"
        @click="showPicker(false)"
      >
        {{ t("actions.back") }}
      </Btn>
      <Btn
        v-else
        :type="BtnTypesEnum.SUBMIT"
        form="create-hangar-inventory-item-form"
        :loading="submitting"
        data-test="inventory-item-save"
      >
        {{
          isDeposit
            ? t("actions.logistics.deposit")
            : t("actions.logistics.withdraw")
        }}
      </Btn>
    </template>
  </Modal>
</template>
