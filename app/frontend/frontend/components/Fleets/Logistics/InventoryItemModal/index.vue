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
import {
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

const submitting = ref(false);
const entryType = ref<"deposit" | "withdrawal">(
  props.initialEntryType ?? "deposit",
);
const selectedStockItem = ref<string | undefined>(undefined);
const stockItems = ref<StockItem[]>([]);

const isDeposit = computed(() => entryType.value === "deposit");

const modalTitle = computed(() =>
  isDeposit.value
    ? t("headlines.fleets.logistics.deposit")
    : t("headlines.fleets.logistics.withdrawal"),
);

const validationSchema = {
  name: "required|min:2",
  quantity: "required|min_value:0",
};

const { defineField, handleSubmit, setFieldValue } = useForm({
  initialValues: {
    name: "",
    category: FleetInventoryItemCreateInputCategory.commodity,
    quantity: 1,
    unit: FleetInventoryItemCreateInputUnit.scu,
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

const entryTypeOptions: FilterOption[] = [
  {
    value: "deposit",
    label: t("labels.fleets.logistics.entryTypes.deposit"),
  },
  {
    value: "withdrawal",
    label: t("labels.fleets.logistics.entryTypes.withdrawal"),
  },
];

const categoryOptions: FilterOption[] = [
  {
    value: "commodity",
    label: t("labels.fleets.logistics.categories.commodity"),
  },
  {
    value: "component",
    label: t("labels.fleets.logistics.categories.component"),
  },
  {
    value: "weapon",
    label: t("labels.fleets.logistics.categories.weapon"),
  },
  {
    value: "equipment",
    label: t("labels.fleets.logistics.categories.equipment"),
  },
  {
    value: "ammunition",
    label: t("labels.fleets.logistics.categories.ammunition"),
  },
  {
    value: "consumable",
    label: t("labels.fleets.logistics.categories.consumable"),
  },
  { value: "other", label: t("labels.fleets.logistics.categories.other") },
];

const unitOptions: FilterOption[] = [
  { value: "scu", label: t("labels.fleets.logistics.units.scu") },
  { value: "units", label: t("labels.fleets.logistics.units.units") },
];

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
    label: `${item.name} (${item.netQuantity} ${t(`labels.fleets.logistics.units.${item.unit}`)})`,
  })),
);

// Load stock on mount for both withdrawal picker and deposit name suggestions
onMounted(() => {
  void loadStockItems();
});

const existingItemOptions = computed<FilterOption[]>(() =>
  stockItems.value.map((item) => ({
    value: `${item.name}|||${item.category}|||${item.unit}`,
    label: `${item.name} (${t(`labels.fleets.logistics.categories.${item.category}`)})`,
  })),
);

const selectedExistingItem = ref<string | undefined>(undefined);

watch(selectedExistingItem, (val) => {
  if (!val) return;

  const [itemName, itemCategory, itemUnit] = val.split("|||");
  setFieldValue("name", itemName);
  /* eslint-disable @typescript-eslint/no-explicit-any */
  setFieldValue("category", itemCategory as any);
  setFieldValue("unit", itemUnit as any);
  /* eslint-enable @typescript-eslint/no-explicit-any */
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
      },
    })
    .then(() => {
      displaySuccess({
        text: isDeposit.value
          ? t("messages.fleets.logistics.inventoryItem.deposit.success")
          : t("messages.fleets.logistics.inventoryItem.withdrawal.success"),
      });
      comlink.emit("fleet-inventory-item-created");
      comlink.emit("close-modal");
    })
    .catch(() => {
      displayAlert({
        text: isDeposit.value
          ? t("messages.fleets.logistics.inventoryItem.deposit.failure")
          : t("messages.fleets.logistics.inventoryItem.withdrawal.failure"),
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
        :label="t('labels.fleets.logistics.entryType')"
        name="entryType"
        :searchable="false"
      />

      <FilterGroup
        v-model="memberId"
        :query-fn="fetchMembers"
        :query-response-formatter="formatMembers"
        :label="t('labels.fleets.logistics.member')"
        name="memberId"
        :searchable="true"
        :nullable="true"
      />

      <!-- Withdrawal: pick from existing stock -->
      <template v-if="!isDeposit">
        <FilterGroup
          v-model="selectedStockItem"
          :options="stockItemOptions"
          :label="t('labels.fleets.logistics.selectItem')"
          name="stockItem"
          :searchable="true"
        />

        <p v-if="selectedStockMax !== undefined" class="text-muted">
          {{ t("labels.fleets.logistics.currentStock") }}:
          {{ selectedStockMax }}
          {{ t(`labels.fleets.logistics.units.${unit}`) }}
        </p>
      </template>

      <!-- Deposit: pick existing or manual entry -->
      <template v-if="isDeposit">
        <FilterGroup
          v-if="existingItemOptions.length"
          v-model="selectedExistingItem"
          :options="existingItemOptions"
          :label="t('labels.fleets.logistics.existingItem')"
          name="existingItem"
          :searchable="true"
          :nullable="true"
        />
        <FormInput
          v-model="name"
          v-bind="nameProps"
          name="name"
          :rules="validationSchema.name"
          :label="t('labels.fleets.logistics.itemName')"
        />
        <FilterGroup
          v-model="category"
          v-bind="categoryProps"
          name="category"
          :options="categoryOptions"
          :label="t('labels.fleets.logistics.category')"
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
            :label="t('labels.fleets.logistics.quantity')"
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
                {{ t(`labels.fleets.logistics.units.${unit}`) }}
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
            :label="t('labels.fleets.logistics.quality')"
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
        :label="t('labels.fleets.logistics.image')"
        :allowed-types="AllowedFileTypes.IMAGE"
        clearable
      />

      <FormTextarea
        v-model="notes"
        v-bind="notesProps"
        name="notes"
        :label="t('labels.fleets.logistics.notes')"
        :placeholder="t('labels.fleets.logistics.notesPlaceholder')"
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
              ? t("actions.fleets.logistics.deposit")
              : t("actions.fleets.logistics.withdraw")
          }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
