<script lang="ts">
export default {
  name: "AdminModelEditPricesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended, type ModelInput } from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
// import { useNoty } from "@/shared/composables/useNoty";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const { displayAlert } = useNoty();

const submitting = ref(false);

const initialValues = ref<ModelInput>({
  price: props.model.price,
  pledgePrice: props.model.pledgePrice,
  lastPledgePrice: props.model.lastPledgePrice,
  onSale: props.model.onSale,
  salesPageUrl: props.model.links.salesPageUrl,
  storeUrl: props.model.links.storeUrl,
});

const validationSchema = {};

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [price, priceProps] = defineField("price");
const [pledgePrice, pledgePriceProps] = defineField("pledgePrice");
const [lastPledgePrice, lastPledgePriceProps] = defineField("lastPledgePrice");
const [onSale, onSaleProps] = defineField("onSale");
const [salesPageUrl, salesPageUrlProps] = defineField("salesPageUrl");
const [storeUrl, storeUrlProps] = defineField("storeUrl");

// const { updateMutation } = useModels();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;
  console.info(values);
});

const onCancel = () => {
  alert("cancel");
};
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.prices") }}</Heading>
  <form @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="price"
          v-bind="priceProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="price"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.price"
          :suffix="t('number.units.uec')"
        />
        <FormInput
          v-model="pledgePrice"
          v-bind="pledgePriceProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="pledgePrice"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.pledgePrice"
          :suffix="t('number.units.currency')"
        />
        <FormInput
          v-model="lastPledgePrice"
          v-bind="lastPledgePriceProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="lastPledgePrice"
          :type="InputTypesEnum.NUMBER"
          translation-key="model.lastPledgePrice"
          :suffix="t('number.units.currency')"
        />
      </div>
      <div class="col-12 col-md-8">
        <FormCheckbox
          v-model="onSale"
          translation-key="model.onSale"
          v-bind="onSaleProps"
          name="onSale"
        />
        <FormInput
          v-model="salesPageUrl"
          v-bind="salesPageUrlProps"
          name="salesPageUrl"
          translation-key="model.salesPageUrl"
        />
        <FormInput
          v-model="storeUrl"
          v-bind="storeUrlProps"
          name="storeUrl"
          translation-key="model.storeUrl"
        />
      </div>
    </div>
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>
