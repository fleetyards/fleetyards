<script lang="ts">
export default {
  name: "AdminModelEditPricesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelExtended,
  type ModelUpdateInput,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import ModelForm from "@/admin/components/Models/Form/index.vue";
import ItemPricesList from "@/admin/components/ItemPrices/List.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<ModelUpdateInput>({
  price: props.model.price,
  pledgePrice: props.model.pledgePrice,
  onSale: props.model.onSale,
  salesPageUrl: props.model.links.salesPageUrl,
  storeUrl: props.model.links.storeUrl,
});

const validationSchema = {};

const { defineField } = useForm({
  initialValues: initialValues.value,
  validationSchema,
});

const [price, priceProps] = defineField("price");
const [pledgePrice, pledgePriceProps] = defineField("pledgePrice");
const [onSale, onSaleProps] = defineField("onSale");
const [salesPageUrl, salesPageUrlProps] = defineField("salesPageUrl");
const [storeUrl, storeUrlProps] = defineField("storeUrl");

const itemPricesList = ref<{
  creating: boolean;
  startCreate: () => void;
} | null>(null);
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.edit.prices") }}</Heading>
  <ModelForm
    :model="model"
    :validation-schema="validationSchema"
    :initial-values="initialValues"
  >
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
      </div>
      <div class="col-12 col-md-8">
        <FormToggle
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
  </ModelForm>

  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.models.edit.itemPrices") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
      :disabled="itemPricesList?.creating"
      @click="itemPricesList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <ItemPricesList
    ref="itemPricesList"
    :item-id="props.model.id"
    item-type="Model"
  />
</template>
