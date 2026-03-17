<script lang="ts">
export default {
  name: "AdminModelPaintsEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelPaint,
  type ModelPaintInput,
  useUpdateModelPaint,
  getListModelPaintsQueryKey,
  getModelPaintQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  modelPaint: ModelPaint;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<ModelPaintInput>({
  name: props.modelPaint.name,
  description: props.modelPaint.description,
  modelId: props.modelPaint.model?.id,
  active: props.modelPaint.active,
  hidden: props.modelPaint.hidden,
  onSale: undefined,
  pledgePrice: undefined,
  productionStatus: undefined,
  productionNote: undefined,
  storeUrl: undefined,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ModelPaintInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [modelId, modelIdProps] = defineField("modelId");
const [active, activeProps] = defineField("active");
const [hidden, hiddenProps] = defineField("hidden");
const [onSale, onSaleProps] = defineField("onSale");
const [pledgePrice, pledgePriceProps] = defineField("pledgePrice");
const [productionStatus, productionStatusProps] =
  defineField("productionStatus");
const [productionNote, productionNoteProps] = defineField("productionNote");

const submitting = ref(false);

const updateMutation = useUpdateModelPaint({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getListModelPaintsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getModelPaintQueryKey(props.modelPaint.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.modelPaint.id, data: values })
    .catch((error) => {
      console.error("Error updating model paint:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-model-paints",
      hash: `#${props.modelPaint.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.modelPaints.edit") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-model-paint-edit-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
        />
        <ModelFilterGroup
          v-model="modelId"
          v-bind="modelIdProps"
          :no-label="false"
          value-attr="id"
          :multiple="false"
          name="model"
        />
      </div>
      <div class="col-12 col-md-6">
        <div class="row">
          <div class="col-12 col-md-4">
            <FormToggle
              v-model="hidden"
              translation-key="modelPaint.hidden"
              v-bind="hiddenProps"
              name="hidden"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormToggle
              v-model="active"
              translation-key="modelPaint.active"
              v-bind="activeProps"
              name="active"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormToggle
              v-model="onSale"
              translation-key="modelPaint.onSale"
              v-bind="onSaleProps"
              name="onSale"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="pledgePrice"
              v-bind="pledgePriceProps"
              translation-key="modelPaint.pledgePrice"
              name="pledgePrice"
              type="number"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="productionStatus"
              v-bind="productionStatusProps"
              translation-key="modelPaint.productionStatus"
              name="productionStatus"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="productionNote"
              v-bind="productionNoteProps"
              translation-key="modelPaint.productionNote"
              name="productionNote"
            />
          </div>
        </div>
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-model-paint-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
