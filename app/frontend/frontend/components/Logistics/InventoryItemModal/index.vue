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
import BlueprintCrafter from "@/frontend/components/Blueprints/Crafter/index.vue";
import {
  type StockLot,
  lotEntry,
  useStockLots,
} from "@/frontend/composables/useStockLots";
import {
  type ItemPickerSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import { useCraftingStep } from "@/frontend/composables/useCraftingStep";
import { unitsForCategory } from "@/frontend/composables/useInventoryOptions";
import {
  type DepositTarget,
  useDepositTargets,
} from "@/frontend/composables/useDepositTargets";
import {
  type InventoryItemCreateInput,
  hangarInventoryStock,
  vehicleInventoryStock,
  useCreateHangarInventoryItem,
  useCreateVehicleInventoryItem,
  useCreateFleetInventoryItem,
  InventoryCategoryEnum,
  InventoryUnitEnum,
} from "@/services/fyApi";
import type { InventoryTarget } from "@/frontend/types/logistics";

type StockItem = StockLot;

type Props = {
  // Without one, the deposit is filed into any inventory the reader may
  // deposit into, picked here, as from a catalogue page that belongs to none.
  target?: InventoryTarget;
  initialEntryType?: "deposit" | "withdrawal";
  // The goods, already named.
  item?: ItemPickerSelection;
};

const props = withDefaults(defineProps<Props>(), {
  target: undefined,
  initialEntryType: undefined,
  item: undefined,
});

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { unitOptionsFor, entryTypeOptions } = useInventoryOptions();

const submitting = ref(false);

const choosesInventory = !props.target;

const {
  options: inventoryOptions,
  targetFor,
  empty: noInventories,
} = useDepositTargets(choosesInventory);

const inventoryId = ref<string>();

watch(
  inventoryOptions,
  (options) => {
    if (options.some((option) => option.value === inventoryId.value)) return;

    inventoryId.value = options[0]?.value as string | undefined;
  },
  { immediate: true },
);

const activeTarget = computed<DepositTarget | undefined>(
  () => props.target ?? targetFor(inventoryId.value),
);

// Opened outside any inventory, it only deposits: a withdrawal picks from the
// stock of an inventory the reader is already looking at.
const entryType = ref<"deposit" | "withdrawal">(
  choosesInventory ? "deposit" : (props.initialEntryType ?? "deposit"),
);
const selectedStockItem = ref<string | undefined>(undefined);
const selectedExistingItem = ref<string | undefined>(undefined);
const stockItems = ref<StockItem[]>([]);
// One slot for whichever catalogue the item came from, so the submit and the
// name-edit rule stay single rather than growing a branch per item type.
const pickedItem = ref<PickedItem | undefined>(props.item?.item);

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
  if (step.value === "crafting") return t("headlines.logistics.crafting");
  if (choosesInventory) return t("headlines.logistics.addToInventory");

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
// nobody chose.

const initialCategory = props.item?.category ?? InventoryCategoryEnum.COMMODITY;

const initialValues = {
  name: props.item?.name ?? "",
  category: initialCategory as InventoryCategoryEnum,
  quantity: undefined as number | undefined,
  unit: unitsForCategory(
    initialCategory,
    props.item?.item?.counted,
  )[0] as InventoryUnitEnum,
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
  step,
  showStep,
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

const {
  crafted,
  canApply: craftingCanApply,
  craftable,
  craftableType,
  craftedLabel,
  openCrafting,
  applyCrafting,
  removeCrafting,
  onCrafted,
  clearCrafted,
} = useCraftingStep({ pickedItem, isDeposit, showStep });

// The item, where it is filed, and how it was crafted, on one line.
const itemMeta = computed(() =>
  [categoryLabel.value, craftedLabel.value].filter(Boolean).join(" · "),
);

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

const fetchStock = (target: InventoryTarget) =>
  target.kind === "hangar"
    ? hangarInventoryStock(target.slug)
    : vehicleInventoryStock(target.vehicleId);

// Stock is shown only for the inventory the modal was opened from.
const loadStockItems = async () => {
  const target = props.target;
  if (!target) return;

  try {
    const data = await fetchStock(target);
    stockItems.value = data as unknown as StockItem[];
  } catch {
    stockItems.value = [];
  }
};

const {
  lotOptions: stockItemOptions,
  positionOptions: existingItemOptions,
  lotAt,
} = useStockLots(stockItems);

onMounted(() => {
  if (choosesInventory) return;

  void loadStockItems();
});

const applyPickedItem = (val: string | undefined) => {
  if (!val) return;

  const picked = lotAt(val);
  if (!picked) return;

  selectedPosition.value = picked;
  setFieldValue("name", picked.name);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", picked.category as any);
  setFieldValue("unit", picked.unit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
  pickedItem.value = undefined;
  crafted.value = undefined;
};

watch(selectedExistingItem, applyPickedItem);

// A withdrawal comes out of one lot, and carries what that lot is.
watch(selectedStockItem, (val) => {
  applyPickedItem(val);

  const picked = lotAt(val);
  if (!picked) return;

  const entry = lotEntry(picked);

  pickedItem.value = entry.item;
  crafted.value = entry.crafted;
});

watch(entryType, (val) => {
  if (val === "withdrawal") {
    void loadStockItems();
  }
  selectedStockItem.value = undefined;
  selectedPosition.value = undefined;
  pickedItem.value = undefined;
});

// A withdrawal comes out of the grade its stock row is held at -- 800, 0, or
// NULL for stock nobody graded -- exactly, since stock is grouped by it and a
// withdrawal at any other grade would leave the row it came from untouched.
const withdrawnQuality = computed(
  () => lotAt(selectedStockItem.value)?.quality ?? null,
);

const selectedStockMax = computed(
  () => lotAt(selectedStockItem.value)?.netQuantity,
);

const createHangarItem = useCreateHangarInventoryItem();
const createVehicleItem = useCreateVehicleInventoryItem();

const createFleetItem = useCreateFleetInventoryItem();

const createItem = (target: DepositTarget, data: InventoryItemCreateInput) => {
  if (target.kind === "fleet") {
    return createFleetItem.mutateAsync({
      fleetSlug: target.fleetSlug,
      fleetInventorySlug: target.slug,
      data,
    });
  }

  return target.kind === "hangar"
    ? createHangarItem.mutateAsync({
        hangarInventorySlug: target.slug,
        data,
      })
    : createVehicleItem.mutateAsync({
        vehicleId: target.vehicleId,
        data,
      });
};

// Deposit or withdrawal and the position or item picked live outside the form.
const entryChoice = computed(() => ({
  entryType: entryType.value,
  selectedStockItem: selectedStockItem.value,
  selectedExistingItem: selectedExistingItem.value,
  pickedItemId: pickedItem.value?.id,
  crafted: crafted.value,
}));

const formDirty = useFormDirty(values, initialValues);
const choiceDirty = useFormDirty(entryChoice, { ...entryChoice.value });

useModalDirty(() => formDirty.value || choiceDirty.value);

const onSubmit = handleSubmit(async (values) => {
  const target = activeTarget.value;
  if (!target) return;

  submitting.value = true;

  await createItem(target, {
    name: values.name,
    category: values.category,
    quantity:
      values.category === "commodity"
        ? Number(values.quantity)
        : Math.round(Number(values.quantity)),
    unit: values.unit,
    entryType: entryType.value,
    quality: isDeposit.value
      ? graded.value && values.quality != null
        ? Number(values.quality)
        : undefined
      : withdrawnQuality.value,
    image: values.image || undefined,
    notes: values.notes || undefined,
    itemType: pickedItem.value?.type,
    itemId: pickedItem.value?.id,
    craftedBlueprintId: crafted.value?.blueprintId,
    craftedQualities: crafted.value?.qualities,
  })
    .then(() => {
      displaySuccess({
        text: isDeposit.value
          ? t("messages.logistics.inventoryItem.deposit.success")
          : t("messages.logistics.inventoryItem.withdrawal.success"),
      });
      comlink.emit(
        target.kind === "fleet"
          ? "fleet-inventory-item-created"
          : "inventory-item-created",
      );
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

    <!-- The shared crafter, with this modal's footer driving it. -->
    <BlueprintCrafter
      v-if="step === 'crafting' && pickedItem"
      ref="itemCrafter"
      :title="pickedItem.name"
      :item="pickedItem"
      :craftable-type="craftableType"
      :crafted="crafted"
      embedded
      @apply="onCrafted"
      @remove="clearCrafted"
    />

    <div
      v-if="noInventories"
      class="inventory-item-modal__empty"
      data-test="inventory-item-no-inventories"
    >
      <p>{{ t("texts.hangarPledgeItems.noInventories") }}</p>
      <Btn :to="{ name: 'hangar-inventories' }">
        {{ t("actions.hangarPledgeItems.createInventory") }}
      </Btn>
    </div>

    <!-- Hidden rather than unmounted while another step is open, so nothing
         typed into it is lost. -->
    <form
      v-show="step === 'form' && !noInventories"
      id="create-hangar-inventory-item-form"
      ref="itemPickerForm"
      @submit.prevent="onSubmit"
    >
      <BaseSelect
        v-if="choosesInventory"
        v-model="inventoryId"
        :options="inventoryOptions"
        :nullable="false"
        :label="t('labels.logistics.inventory')"
        name="inventory"
        data-test="inventory-item-inventory"
      />

      <BaseSelect
        v-else
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
          :category-label="itemMeta"
          :craft-label="
            craftable ? t('labels.logistics.crafted.edit') : undefined
          "
          :crafted="!!crafted"
          :error="nameError"
          @open="showPicker(true)"
          @clear="clearItem"
          @craft="openCrafting"
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

        <!-- A withdrawal's grade is the stock row's, named in the row it
             picked. -->
        <div v-if="graded && isDeposit" class="col-6">
          <FormInput
            v-model="quality"
            v-bind="qualityProps"
            name="quality"
            :type="InputTypesEnum.NUMBER"
            :rules="validationSchema.quality"
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
      <template v-if="step !== 'form'">
        <Btn
          :variant="BtnVariantsEnum.BARE"
          data-test="item-picker-back"
          @click="showStep('form')"
        >
          {{ t("actions.back") }}
        </Btn>
        <Btn
          v-if="step === 'crafting' && crafted"
          :variant="BtnVariantsEnum.BARE"
          data-test="crafting-clear"
          @click="removeCrafting"
        >
          {{ t("actions.blueprint.removeCrafting") }}
        </Btn>
        <Btn
          v-if="step === 'crafting'"
          :disabled="!craftingCanApply"
          data-test="crafting-apply"
          @click="applyCrafting"
        >
          {{ t("actions.blueprint.apply") }}
        </Btn>
      </template>
      <Btn
        v-else-if="!noInventories"
        :type="BtnTypesEnum.SUBMIT"
        form="create-hangar-inventory-item-form"
        :disabled="!activeTarget"
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

<style lang="scss" scoped>
.inventory-item-modal__empty {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 14px;

  p {
    margin: 0;
  }
}
</style>
