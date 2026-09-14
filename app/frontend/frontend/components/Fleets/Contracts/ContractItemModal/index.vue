<script lang="ts">
export default {
  name: "FleetContractsItemModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BaseSelectVariantsEnum } from "@/shared/components/base/Select/types";
import ComponentPicker from "@/frontend/components/Logistics/ComponentPicker/index.vue";
import CommodityPicker from "@/frontend/components/Logistics/CommodityPicker/index.vue";
import EquipmentPicker from "@/frontend/components/Logistics/EquipmentPicker/index.vue";
import { type PickedItem } from "@/frontend/components/Logistics/types";
import { useInventoryOptions } from "@/frontend/composables/useInventoryOptions";
import { validationErrorFrom } from "@/shared/utils/ApiErrors";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Fleet,
  type Commodity,
  type Equipment as GameEquipment,
  type Component as GameComponent,
  type FilterOption,
  type FleetContractDetail,
  InventoryCategoryEnum,
  InventoryUnitEnum,
  FleetContractQualityMatchEnum,
  useCreateFleetContractItem,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  contract: FleetContractDetail;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { categoryOptions, unitOptionsFor } = useInventoryOptions();

const submitting = ref(false);

// The catalogue entry this line asks for, when it asks for one. Same slot and
// same rules as `Logistics/InventoryItemModal`, so a contract names goods the
// way the ledger names them.
const pickedItem = ref<PickedItem | undefined>(undefined);

const validationSchema = {
  name: "required|min:2",
  quantity: "required|min_value:0",
};

const { defineField, handleSubmit, setFieldValue, setErrors } = useForm({
  initialValues: {
    name: "",
    category: InventoryCategoryEnum.COMMODITY as InventoryCategoryEnum,
    quantity: 1,
    unit: InventoryUnitEnum.SCU as InventoryUnitEnum,
    quality: undefined as number | undefined,
    qualityMatch: FleetContractQualityMatchEnum.AT_LEAST,
  },
});

const [name, nameProps] = defineField("name");
const [category, categoryProps] = defineField("category");
const [quantity, quantityProps] = defineField("quantity");
const [unit] = defineField("unit");
const [quality, qualityProps] = defineField("quality");
const [qualityMatch] = defineField("qualityMatch");

const isComponent = computed(
  () => category.value === InventoryCategoryEnum.COMPONENT,
);

const isCommodity = computed(
  () => category.value === InventoryCategoryEnum.COMMODITY,
);

// One table backs all three: the game files file magazines as weapon
// attachments, so ammunition is not a catalogue of its own.
const EQUIPMENT_CATEGORIES: InventoryCategoryEnum[] = [
  InventoryCategoryEnum.WEAPON,
  InventoryCategoryEnum.EQUIPMENT,
  InventoryCategoryEnum.AMMUNITION,
];

const isEquipment = computed(() =>
  EQUIPMENT_CATEGORIES.includes(category.value),
);

const EQUIPMENT_TYPES_FOR_CATEGORY: Record<string, string[]> = {
  [InventoryCategoryEnum.WEAPON]: ["weapon"],
  [InventoryCategoryEnum.AMMUNITION]: ["weapon_attachment"],
  [InventoryCategoryEnum.EQUIPMENT]: [
    "armor",
    "clothing",
    "undersuit",
    "tool",
    "medical",
    "hacking_tool",
  ],
};

const equipmentTypes = computed(
  () => EQUIPMENT_TYPES_FOR_CATEGORY[category.value] || [],
);

const unitOptions = unitOptionsFor(category);

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

const applyPickedEquipment = (equipment: GameEquipment) => {
  pickedItem.value = {
    type: "Equipment",
    id: equipment.id,
    name: equipment.name,
  };

  setFieldValue("name", equipment.name);
};

// A hand-edited name no longer describes the picked item, so the reference goes
// with it rather than mislabelling a real catalogue entry. Asking for something
// the catalogue does not carry stays allowed; it just is not a reference.
watch(name, (val) => {
  if (pickedItem.value && val !== pickedItem.value.name) {
    pickedItem.value = undefined;
  }
});

// Switching away from the category that offered the picker leaves the reference
// pointing at the wrong kind of thing.
watch([isComponent, isCommodity, isEquipment], () => {
  if (!pickedItem.value) return;

  const stillOffered = {
    Component: isComponent.value,
    Commodity: isCommodity.value,
    Equipment: isEquipment.value,
  }[pickedItem.value.type];

  if (!stillOffered) pickedItem.value = undefined;
});

const createItem = useCreateFleetContractItem();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createItem
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetContractSlug: props.contract.slug,
      data: {
        name: values.name,
        category: values.category,
        unit: values.unit,
        quantity: String(values.quantity),
        quality: values.quality != null ? Number(values.quality) : null,
        qualityMatch: values.qualityMatch,
        itemType: pickedItem.value?.type,
        itemId: pickedItem.value?.id,
      },
    })
    .then(() => {
      comlink.emit("fleet-contract-item-created");
      comlink.emit("close-modal");
    })
    .catch((error) => {
      // The API says *why* -- asking for the same goods twice is the common
      // refusal, and a generic toast leaves the author guessing.
      const { message, formErrors } = validationErrorFrom(error, {
        name: "itemName",
        quantity: "itemQuantity",
        quality: "itemQuality",
      });

      setErrors(formErrors);

      displayAlert({
        text: message || t("messages.fleets.contract.item.create.failure"),
      });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="t('headlines.fleets.contracts.addItem')">
    <form id="fleet-contract-item-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="name"
        v-bind="nameProps"
        name="itemName"
        :rules="validationSchema.name"
        :label="t('labels.fleets.contracts.itemName')"
      />

      <BaseSelect
        v-model="category"
        v-bind="categoryProps"
        name="itemCategory"
        :options="categoryOptions"
        :label="t('labels.logistics.category')"
        :searchable="false"
      />

      <ComponentPicker v-if="isComponent" @select="applyPickedComponent" />
      <CommodityPicker v-if="isCommodity" @select="applyPickedCommodity" />
      <EquipmentPicker
        v-if="isEquipment"
        :equipment-types="equipmentTypes"
        @select="applyPickedEquipment"
      />

      <div class="row">
        <div class="col-6">
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
             Offered on every kind, because the ledger records a grade on every
             entry -- leaving it blank is what asks for any. -->
        <div class="col-6">
          <FormInput
            v-model="quality"
            v-bind="qualityProps"
            name="itemQuality"
            :type="InputTypesEnum.NUMBER"
            :label="t('labels.logistics.quality')"
            :min="0"
            :step="1"
            :max="1000"
            no-placeholder
          >
            <!-- The suffix slot is wrapped by FormInput; the prefix slot is
                 not -- its default content carries the class itself. Without
                 the wrapper the select is unconstrained and takes the whole
                 field, leaving the number with nowhere to go. -->
            <template #prefix>
              <div class="base-input__prefix">
                <BaseSelect
                  v-model="qualityMatch"
                  :options="qualityMatchOptions"
                  :label="t('labels.fleets.contracts.qualityMatch')"
                  :variant="BaseSelectVariantsEnum.AFFIX"
                  name="itemQualityMatch"
                  no-label
                  :searchable="false"
                />
              </div>
            </template>
          </FormInput>
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LG"
          data-test="contract-item-save"
          @click="onSubmit"
        >
          {{ t("actions.fleets.contracts.addItem") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
