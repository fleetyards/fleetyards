<script lang="ts">
export default {
  name: "FleetLogisticsInventoryItemModal",
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
import ComponentPicker from "@/frontend/components/Logistics/ComponentPicker/index.vue";
import CommodityPicker from "@/frontend/components/Logistics/CommodityPicker/index.vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import {
  type Commodity,
  type Component as GameComponent,
  type Fleet,
  type FleetInventory,
  type FilterOption,
  type FleetMember,
  fleetMembers as fetchFleetMembers,
  fleetInventoryStock as fetchStock,
  useCreateFleetInventoryItem,
  FleetInventoryItemCreateInputCategory,
  FleetInventoryItemCreateInputUnit,
} from "@/services/fyApi";
import { type FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";

type StockItem = {
  name: string;
  category: string;
  unit: string;
  netQuantity: number;
};

type Props = {
  fleet: Fleet;
  inventory: FleetInventory;
  initialEntryType?: "deposit" | "withdrawal";
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const comlink = useComlink();
const { categoryOptions, unitOptionsFor, entryTypeOptions } =
  useInventoryOptions();

const submitting = ref(false);
const entryType = ref<"deposit" | "withdrawal">(
  props.initialEntryType ?? "deposit",
);
const selectedStockItem = ref<string | undefined>(undefined);
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
    category:
      FleetInventoryItemCreateInputCategory.commodity as FleetInventoryItemCreateInputCategory,
    quantity: 1,
    unit: FleetInventoryItemCreateInputUnit.scu as FleetInventoryItemCreateInputUnit,
    quality: 0,
    memberId: undefined as string | undefined,
    image: undefined as string | undefined,
    notes: "",
  },
});

const [name, nameProps] = defineField("name");
const [category, categoryProps] = defineField("category");
const [quantity, quantityProps] = defineField("quantity");
const [unit] = defineField("unit");
const [quality, qualityProps] = defineField("quality");
const [memberId] = defineField("memberId");
const [image, imageProps] = defineField("image");
const [notes, notesProps] = defineField("notes");

const isComponent = computed(
  () => category.value === FleetInventoryItemCreateInputCategory.component,
);

const isCommodity = computed(
  () => category.value === FleetInventoryItemCreateInputCategory.commodity,
);

const unitOptions = unitOptionsFor(category);

// The category dictates which units make sense, so a category change pulls the
// unit along instead of leaving an impossible pairing the API would reject.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === unit.value)) return;

  setFieldValue("unit", options[0].value as FleetInventoryItemCreateInputUnit);
});

// Load stock items for withdrawal picker
const loadStockItems = async () => {
  try {
    const data = await fetchStock(props.fleet.slug, props.inventory.slug);
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

// Load stock on mount for both withdrawal picker and deposit name suggestions
onMounted(() => {
  void loadStockItems();
});

const existingItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item) => ({
    value: `${item.name}|||${item.category}|||${item.unit}`,
    label: `${item.name} (${t(`labels.logistics.categories.${item.category}`)})`,
  })),
);

const selectedExistingItem = ref<string | undefined>(undefined);
// One slot for whichever catalogue the category exposes, so the submit and the
// name-edit rule stay single rather than growing a branch per item type.
const pickedItem = ref<PickedItem | undefined>(undefined);

watch(selectedExistingItem, (val) => {
  if (!val) return;

  const [itemName, itemCategory, itemUnit] = val.split("|||");
  setFieldValue("name", itemName);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", itemCategory as any);
  setFieldValue("unit", itemUnit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
  pickedItem.value = undefined;
});

const applyPickedComponent = (component: GameComponent) => {
  pickedItem.value = {
    type: "Component",
    id: component.id,
    name: component.name,
  };

  setFieldValue("name", component.name);
};

const applyPickedCommodity = (commodity: Commodity) => {
  pickedItem.value = {
    type: "Commodity",
    id: commodity.id,
    name: commodity.name,
  };

  setFieldValue("name", commodity.name);
};

// A hand-edited name no longer describes the picked item, so the reference goes
// with it rather than mislabeling a real component or commodity. Typing a name
// that isn't in the catalogue at all stays allowed; it just isn't a reference.
watch(name, (val) => {
  if (pickedItem.value && val !== pickedItem.value.name) {
    pickedItem.value = undefined;
  }
});

// Switching away from the category that offered the picker leaves the reference
// pointing at the wrong kind of thing.
watch([isComponent, isCommodity], ([component, commodity]) => {
  if (!pickedItem.value) return;

  const stillOffered =
    pickedItem.value.type === "Component" ? component : commodity;

  if (!stillOffered) pickedItem.value = undefined;
});

// When switching to withdrawal, load stock
watch(entryType, (val) => {
  if (val === "withdrawal") {
    void loadStockItems();
  }
  selectedStockItem.value = undefined;
});

// When stock item is picked, auto-fill fields
watch(selectedStockItem, (val) => {
  if (!val) return;

  const [itemName, itemCategory, itemUnit] = val.split("|||");
  setFieldValue("name", itemName);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", itemCategory as any);
  setFieldValue("unit", itemUnit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
});

const selectedStockMax = computed(() => {
  if (!selectedStockItem.value) return undefined;
  const [itemName, itemCategory, itemUnit] =
    selectedStockItem.value.split("|||");
  const match = stockItems.value.find(
    (s) =>
      s.name === itemName && s.category === itemCategory && s.unit === itemUnit,
  );
  return match?.netQuantity;
});

const fetchMembers = (params: FilterGroupParams<FilterOption>) => {
  return fetchFleetMembers(props.fleet.slug, {
    q: { usernameCont: params.search || undefined },
  });
};

const formatMembers = (response: { items: FleetMember[] }) => {
  return (response.items || []).map((m) => ({
    label: m.username,
    value: m.userId || "",
  }));
};

const createMutation = useCreateFleetInventoryItem();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetInventorySlug: props.inventory.slug,
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
        memberId: values.memberId || undefined,
        image: values.image || undefined,
        notes: values.notes || undefined,
        itemType: pickedItem.value?.type,
        itemId: pickedItem.value?.id,
      },
    })
    .then(() => {
      displaySuccess({
        text: isDeposit.value
          ? t("messages.logistics.inventoryItem.deposit.success")
          : t("messages.logistics.inventoryItem.withdrawal.success"),
      });
      comlink.emit("fleet-inventory-item-created");
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
    <form id="create-inventory-item-form" @submit.prevent="onSubmit">
      <FilterGroup
        v-model="entryType"
        :options="entryTypeOptions"
        :label="t('labels.logistics.entryType')"
        name="entryType"
        :searchable="false"
      />

      <FilterGroup
        v-model="memberId"
        :query-fn="fetchMembers"
        :query-response-formatter="formatMembers"
        :label="t('labels.logistics.member')"
        name="memberId"
        :searchable="true"
        :nullable="true"
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
        <ComponentPicker v-if="isComponent" @select="applyPickedComponent" />
        <CommodityPicker v-if="isCommodity" @select="applyPickedCommodity" />
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
      <div class="modal-actions">
        <Btn :loading="submitting" @click="onSubmit" :size="BtnSizesEnum.LG">
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
