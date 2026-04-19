<script lang="ts">
export default {
  name: "AdminModelModuleEditPricesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelModule,
  type ModelModuleInput,
  useUpdateModelModule,
  getListModelModulesQueryKey,
  getModelModuleQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ItemPricesList from "@/admin/components/ItemPrices/List.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  modelModule: ModelModule;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<ModelModuleInput>({
  price: props.modelModule.price,
  pledgePrice: props.modelModule.pledgePrice,
});

const validationSchema = {};

const { defineField, handleSubmit, meta } = useForm<ModelModuleInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [price, priceProps] = defineField("price");
const [pledgePrice, pledgePriceProps] = defineField("pledgePrice");

const submitting = ref(false);

const updateMutation = useUpdateModelModule({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getListModelModulesQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getModelModuleQueryKey(props.modelModule.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.modelModule.id, data: values })
    .catch((error) => {
      console.error("Error updating model module prices:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-model-modules",
      hash: `#${props.modelModule.id}`,
    }),
  );
};

const itemPricesList = ref<{
  creating: boolean;
  startCreate: () => void;
} | null>(null);
</script>

<template>
  <Heading hero>{{ t("headlines.admin.modelModules.prices") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-model-module-prices-form">
    <div class="row">
      <div class="col-12 col-md-4">
        <FormInput
          v-model="price"
          v-bind="priceProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="price"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModule.price"
          :suffix="t('number.units.uec')"
        />
      </div>
      <div class="col-12 col-md-4">
        <FormInput
          v-model="pledgePrice"
          v-bind="pledgePriceProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          name="pledgePrice"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModule.pledgePrice"
          :suffix="t('number.units.currency')"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-model-module-prices-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>

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
    :item-id="props.modelModule.id"
    item-type="ModelModule"
  />
</template>
