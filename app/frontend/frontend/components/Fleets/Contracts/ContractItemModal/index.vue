<script lang="ts">
export default {
  name: "FleetContractsItemModal",
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
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BaseSelectVariantsEnum } from "@/shared/components/base/Select/types";
import ItemPicker from "@/frontend/components/Logistics/ItemPicker/index.vue";
import ItemPickerField from "@/frontend/components/Logistics/ItemPickerField/index.vue";
import {
  type ItemPickerSelection,
  type PickedItem,
} from "@/frontend/components/Logistics/types";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import {
  type Fleet,
  type FilterOption,
  type FleetContractDetail,
  type FleetContractItem,
  type FleetContractItemInput,
  type FleetContractKindEnum,
  InventoryCategoryEnum,
  InventoryUnitEnum,
  FleetContractQualityMatchEnum,
  useCreateFleetContractItem,
  useUpdateFleetContractItem,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Absent while the contract is still being written, which is when `onDraft`
  // takes over: there is nothing to post the line to yet.
  contract?: FleetContractDetail;
  kind: FleetContractKindEnum;
  // Absent when the modal is asking for a new line.
  item?: FleetContractItem;
  onDraft?: (values: FleetContractItemInput) => void;
};

const props = defineProps<Props>();

const editing = computed(() => props.item != null);

const { t } = useI18n();

const modalTitle = computed(() => {
  if (picking.value) return t("headlines.logistics.pickItem");

  return editing.value
    ? t("headlines.fleets.contracts.editItem")
    : t("headlines.fleets.contracts.addItem");
});
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { categoryOptions, unitOptionsFor } = useInventoryOptions();

const isCrafting = computed(() => props.kind === "crafting");

// A commodity is the one thing you cannot craft — those are mined, bought or
// hauled. Written as an exclusion rather than an allowlist so a category added
// to the ledger later is craftable by default, which is the honest assumption:
// the ledger only holds things that exist, and all but raw cargo are made.
const UNCRAFTABLE_CATEGORIES: string[] = [InventoryCategoryEnum.COMMODITY];

const availableCategories = computed(() =>
  isCrafting.value
    ? categoryOptions.value.filter(
        (option) => !UNCRAFTABLE_CATEGORIES.includes(option.value as string),
      )
    : categoryOptions.value,
);

const submitting = ref(false);

// The catalogue entry this line asks for, when it asks for one. Same slot and
// same rules as `Logistics/InventoryItemModal`, so a contract names goods the
// way the ledger names them.
const pickedItem = ref<PickedItem | undefined>(
  props.item?.item
    ? {
        type: props.item.item.type as PickedItem["type"],
        id: props.item.item.id,
        name: props.item.item.name,
        counted: props.item.item.counted,
      }
    : undefined,
);

// The catalogue opens in place of the form rather than as a modal of its own:
// there is only one app modal, and opening another would discard this form.
const picking = ref(false);

const validationSchema = {
  name: "required|min:2",
  quantity: "required|min_value:0",
};

const initialValues = {
  name: props.item?.name ?? "",
  category: (props.item?.category ??
    (props.kind === "crafting"
      ? InventoryCategoryEnum.COMPONENT
      : InventoryCategoryEnum.COMMODITY)) as InventoryCategoryEnum,
  quantity: Number(props.item?.quantity ?? 1),
  unit: (props.item?.unit ?? InventoryUnitEnum.SCU) as InventoryUnitEnum,
  quality: (props.item?.quality ?? undefined) as number | undefined,
  qualityMatch:
    props.item?.qualityMatch ?? FleetContractQualityMatchEnum.AT_LEAST,
};

const { defineField, handleSubmit, setFieldValue, setErrors, values } = useForm(
  { initialValues },
);

useModalDirty(useFormDirty(values, initialValues));

// Named by the picker rather than typed, so the rule lives here instead of on
// an input.
const { value: name, errorMessage: nameError } = useField<string>(
  "name",
  validationSchema.name,
  { label: t("labels.logistics.itemPicker.field") },
);
const [category] = defineField("category");

// Only raw resources carry a grade. A crafted part's worth lies in the
// materials that went into it, which a single number cannot say.
const graded = computed(
  () => category.value === InventoryCategoryEnum.COMMODITY,
);
const [quantity, quantityProps] = defineField("quantity");
const [unit] = defineField("unit");
const [quality, qualityProps] = defineField("quality");
const [qualityMatch] = defineField("qualityMatch");

const categoryLabel = computed(() =>
  name.value ? t(`labels.logistics.categories.${category.value}`) : undefined,
);

// A counted commodity is the only thing that puts `units` on offer under the
// commodity category, and only the picked item knows -- so the options follow
// the pick as well as the category.
const unitOptions = unitOptionsFor(category, () => pickedItem.value?.counted);

// The category dictates which units make sense, so a category change pulls the
// unit along instead of leaving a pairing the API would reject.
watch(unitOptions, (options) => {
  if (options.some((option) => option.value === unit.value)) return;

  setFieldValue("unit", options[0].value as InventoryUnitEnum);
});

const qualityMatchOptions = computed<FilterOption[]>(() =>
  Object.values(FleetContractQualityMatchEnum).map((value) => ({
    value,
    label: t(`labels.fleets.contracts.qualityMatches.${value}`),
  })),
);

const form = ref<HTMLFormElement>();

const showPicker = (shown: boolean) => {
  // The body scrolls, and whichever view comes in starts at its top.
  const body = form.value?.closest(".modal-body");
  if (body) body.scrollTop = 0;

  picking.value = shown;
};

// The category comes from the picker, which is the depositor's word too:
// `Contracts::Progress` matches on (name, category, unit), so a line has to be
// filed where the courier's ledger files the same goods.
const applyCatalogueItem = (selection: ItemPickerSelection) => {
  pickedItem.value = selection.item;

  setFieldValue("category", selection.category);
  setFieldValue("name", selection.name);
  showPicker(false);
};

const clearItem = () => {
  pickedItem.value = undefined;

  setFieldValue("name", "");
};

const createItem = useCreateFleetContractItem();
const updateItem = useUpdateFleetContractItem();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    name: values.name,
    category: values.category,
    unit: values.unit,
    quantity: String(values.quantity),
    quality:
      graded.value && values.quality != null ? Number(values.quality) : null,
    qualityMatch: values.qualityMatch,
    itemType: pickedItem.value?.type,
    itemId: pickedItem.value?.id,
  };

  // Nothing to post to yet: the line goes back to the form, which saves it
  // with the contract in one request.
  if (props.onDraft) {
    props.onDraft(data);
    comlink.emit("close-modal", true);
    submitting.value = false;

    return;
  }

  const saved = props.item
    ? updateItem.mutateAsync({
        fleetSlug: props.fleet.slug,
        fleetContractSlug: props.contract!.slug,
        id: props.item.id,
        data,
      })
    : createItem.mutateAsync({
        fleetSlug: props.fleet.slug,
        fleetContractSlug: props.contract!.slug,
        data,
      });

  await saved
    .then(() => {
      comlink.emit("fleet-contract-item-saved");
      comlink.emit("close-modal", true);
    })
    .catch((error) => {
      // The API says *why* -- asking for the same goods twice is the common
      // refusal, and a generic toast leaves the author guessing.
      const { message, formErrors } = validationErrorFrom(error, {
        quantity: "itemQuantity",
        quality: "itemQuality",
      });

      setErrors(formErrors);

      displayAlert({
        text:
          message ||
          t(
            editing.value
              ? "messages.fleets.contract.item.update.failure"
              : "messages.fleets.contract.item.create.failure",
          ),
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
      :category="name ? category : undefined"
      :categories="availableCategories.map((option) => String(option.value))"
      @select="applyCatalogueItem"
    />

    <!-- Hidden rather than unmounted while the catalogue is open, so nothing
         typed into it is lost. -->
    <form
      v-show="!picking"
      id="fleet-contract-item-form"
      ref="form"
      @submit.prevent="onSubmit"
    >
      <ItemPickerField
        name="catalogueItem"
        :value="name"
        :category-label="categoryLabel"
        :error="nameError"
        @open="showPicker(true)"
        @clear="clearItem"
      />

      <div class="row">
        <div :class="graded ? 'col-6' : 'col-12'">
          <FormInput
            v-model="quantity"
            v-bind="quantityProps"
            name="itemQuantity"
            :type="InputTypesEnum.NUMBER"
            :rules="validationSchema.quantity"
            :label="t('labels.logistics.quantity')"
            :min="0"
            no-placeholder
          >
            <template #suffix>
              <template v-if="unitOptions.length > 1">
                <BaseSelect
                  v-model="unit"
                  :options="unitOptions"
                  :label="t('labels.logistics.unit')"
                  :variant="BaseSelectVariantsEnum.AFFIX"
                  name="itemUnit"
                  no-label
                />
              </template>
              <span v-else class="base-input__suffix-text">
                {{ t(`labels.logistics.units.${unit}`) }}
              </span>
            </template>
          </FormInput>
        </div>

        <!-- The grade, and how it is read. "At least" is the ordinary case; a
             job that wants exactly 500 and no better cannot say so otherwise.
             Leaving it blank is what asks for any. -->
        <div v-if="graded" class="col-6">
          <FormInput
            v-model="quality"
            v-bind="qualityProps"
            name="itemQuality"
            :type="InputTypesEnum.NUMBER"
            :label="t('labels.logistics.quality')"
            :min="0"
            :step="1"
            :max="1000"
          >
            <!-- How the grade is read, in the field's own end-cap. -->
            <template #prefix>
              <BaseSelect
                v-model="qualityMatch"
                :options="qualityMatchOptions"
                :label="t('labels.fleets.contracts.qualityMatch')"
                :variant="BaseSelectVariantsEnum.AFFIX"
                name="itemQualityMatch"
                no-label
                :searchable="false"
              />
            </template>
          </FormInput>
        </div>
      </div>
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
        form="fleet-contract-item-form"
        :loading="submitting"
        data-test="contract-item-save"
      >
        {{ t(editing ? "actions.save" : "actions.fleets.contracts.addItem") }}
      </Btn>
    </template>
  </Modal>
</template>
