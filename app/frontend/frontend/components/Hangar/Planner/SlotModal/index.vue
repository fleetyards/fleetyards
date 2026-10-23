<script lang="ts">
export default {
  name: "HangarPlannerSlotModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import ClassificationSelect from "@/frontend/components/base/ModelClassificationSelect/index.vue";
import FocusSelect from "@/frontend/components/base/ModelFocusSelect/index.vue";
import SizeSelect from "@/frontend/components/base/ModelSizeSelect/index.vue";
import ManufacturerSelect from "@/frontend/components/base/ManufacturerSelect/index.vue";
import ProductionStatusSelect from "@/frontend/components/base/ProductionStatusSelect/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanSlot,
  type HangarPlanSlotFilters,
  useCreateHangarPlanSlot,
  useUpdateHangarPlanSlot,
} from "@/services/fyApi";

type Props = {
  planId: string;
  slot?: HangarPlanSlot;
  label?: string;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const submitting = ref(false);

const filters = props.slot?.filters ?? {};

const initialValues = {
  label: props.slot?.label ?? props.label ?? "",
  description: props.slot?.description ?? "",
  quantity: props.slot?.quantity ?? 1,
  pledgePriceGteq: filters.pledgePriceGteq?.toString() ?? "",
  pledgePriceLteq: filters.pledgePriceLteq?.toString() ?? "",
  cargoGteq: filters.cargoGteq?.toString() ?? "",
  onSaleEq: filters.onSaleEq ?? false,
};

const { defineField, handleSubmit, values } = useForm({ initialValues });

// The list filters stay out of the form: the selects replace their whole
// value on every pick, the way the ship filters drive them, and the form
// keeping its own copy of the array left their rows unmarked after a pick.
const initialLists = {
  classificationIn: [...(filters.classificationIn ?? [])],
  focusIn: [...(filters.focusIn ?? [])],
  sizeIn: [...(filters.sizeIn ?? [])],
  manufacturerIn: [...(filters.manufacturerIn ?? [])],
  productionStatusIn: [...(filters.productionStatusIn ?? [])],
};
const lists = reactive({
  classificationIn: [...initialLists.classificationIn],
  focusIn: [...initialLists.focusIn],
  sizeIn: [...initialLists.sizeIn],
  manufacturerIn: [...initialLists.manufacturerIn],
  productionStatusIn: [...initialLists.productionStatusIn],
});

const formDirty = useFormDirty(values, initialValues);
const listsDirty = computed(
  () => JSON.stringify(lists) !== JSON.stringify(initialLists),
);
useModalDirty(computed(() => toValue(formDirty) || listsDirty.value));

const [label, labelProps] = defineField("label");
const [quantity, quantityProps] = defineField("quantity");
const [description, descriptionProps] = defineField("description");
const [pledgePriceGteq, pledgePriceGteqProps] = defineField("pledgePriceGteq");
const [pledgePriceLteq, pledgePriceLteqProps] = defineField("pledgePriceLteq");
const [cargoGteq, cargoGteqProps] = defineField("cargoGteq");
const [onSaleEq] = defineField("onSaleEq");

const toNumber = (value: string | number) =>
  value === "" || value === null ? undefined : Number(value);

const toList = (value: string | string[] | undefined) =>
  (Array.isArray(value) ? value : value ? [value] : []).filter(Boolean);

// Only the filters that say something are sent, so the set stays readable
// wherever it is shown and an emptied field really clears its filter.
const filterValues = (values: typeof initialValues): HangarPlanSlotFilters => {
  const result: HangarPlanSlotFilters = {
    classificationIn: toList(lists.classificationIn),
    focusIn: toList(lists.focusIn),
    sizeIn: toList(lists.sizeIn),
    manufacturerIn: toList(lists.manufacturerIn),
    productionStatusIn: toList(lists.productionStatusIn),
    pledgePriceGteq: toNumber(values.pledgePriceGteq),
    pledgePriceLteq: toNumber(values.pledgePriceLteq),
    cargoGteq: toNumber(values.cargoGteq),
    onSaleEq: values.onSaleEq || undefined,
  };

  return Object.fromEntries(
    Object.entries(result).filter(([, value]) =>
      Array.isArray(value) ? value.length > 0 : value !== undefined,
    ),
  );
};

const createMutation = useCreateHangarPlanSlot();
const updateMutation = useUpdateHangarPlanSlot();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    label: values.label,
    description: values.description || null,
    quantity: Number(values.quantity) || 1,
    filters: filterValues(values),
  };

  try {
    const plan = props.slot
      ? await updateMutation.mutateAsync({
          hangarPlanId: props.planId,
          id: props.slot.id,
          data,
        })
      : await createMutation.mutateAsync({ hangarPlanId: props.planId, data });

    updatePlan(plan);
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
});
</script>

<template>
  <Modal
    :title="slot ? t('hangarPlanner.editSlot') : t('hangarPlanner.addSlot')"
  >
    <form id="hangar-plan-slot-form" @submit.prevent="onSubmit">
      <FormInput
        v-model="label"
        v-bind="labelProps"
        name="label"
        rules="required"
        :label="t('hangarPlanner.fields.slotLabel')"
        :placeholder="t('hangarPlanner.fields.slotLabelPlaceholder')"
      />
      <FormInput
        v-model="quantity"
        v-bind="quantityProps"
        name="quantity"
        :type="InputTypesEnum.NUMBER"
        :min="1"
        :max="999"
        :step="1"
        :label="t('hangarPlanner.fields.quantity')"
        no-placeholder
      />
      <FormTextarea
        v-model="description"
        v-bind="descriptionProps"
        name="description"
        :label="t('hangarPlanner.fields.slotDescription')"
      />

      <fieldset class="slot-filters">
        <legend>{{ t("hangarPlanner.fields.filters") }}</legend>
        <p class="slot-filters__hint">
          {{ t("hangarPlanner.fields.filtersInfo") }}
        </p>
        <ClassificationSelect
          v-model="lists.classificationIn"
          name="classificationIn"
          :no-label="false"
        />
        <FocusSelect v-model="lists.focusIn" name="focusIn" :no-label="false" />
        <SizeSelect v-model="lists.sizeIn" name="sizeIn" :no-label="false" />
        <ManufacturerSelect
          v-model="lists.manufacturerIn"
          name="manufacturerIn"
          :no-label="false"
        />
        <ProductionStatusSelect
          v-model="lists.productionStatusIn"
          name="productionStatusIn"
          :no-label="false"
        />
        <div class="slot-filters__row">
          <FormInput
            v-model="pledgePriceGteq"
            v-bind="pledgePriceGteqProps"
            name="pledgePriceGteq"
            :type="InputTypesEnum.NUMBER"
            :min="0"
            prefix="$"
            :label="t('hangarPlanner.fields.priceFrom')"
            no-placeholder
          />
          <FormInput
            v-model="pledgePriceLteq"
            v-bind="pledgePriceLteqProps"
            name="pledgePriceLteq"
            :type="InputTypesEnum.NUMBER"
            :min="0"
            prefix="$"
            :label="t('hangarPlanner.fields.priceTo')"
            no-placeholder
          />
          <FormInput
            v-model="cargoGteq"
            v-bind="cargoGteqProps"
            name="cargoGteq"
            :type="InputTypesEnum.NUMBER"
            :min="0"
            suffix="SCU"
            :label="t('hangarPlanner.fields.minCargo')"
            no-placeholder
          />
        </div>
        <FormCheckbox
          v-model="onSaleEq"
          name="onSaleEq"
          :label="t('hangarPlanner.fields.onSaleOnly')"
        />
      </fieldset>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-slot-form"
        :loading="submitting"
        data-test="hangar-plan-slot-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.slot-filters {
  margin: 16px 0 0;
  padding: 0;
  border: 0;

  legend {
    margin-bottom: 4px;
    font-weight: 600;
  }
}

.slot-filters__hint {
  margin: 0 0 8px;
  color: var(--color-text-dim);
}

.slot-filters__row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 0 12px;
}
</style>
