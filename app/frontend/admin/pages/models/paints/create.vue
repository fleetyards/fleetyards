<script lang="ts">
export default {
  name: "AdminModelPaintsCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelPaintInput,
  useCreateModelPaint,
  getListModelPaintsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ModelPaintInput>({
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

const createMutation = useCreateModelPaint({
  mutation: {
    onSettled: async () => {
      await queryClient.invalidateQueries({
        queryKey: getListModelPaintsQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: values })
    .then(async (created) => {
      await router.push(
        extend({
          name: "admin-model-paint-edit",
          params: { id: created.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating model paint:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-model-paints" }));
};
</script>

<template>
  <Heading>{{ t("headlines.admin.modelPaints.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-model-paint-create-form">
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
            <FormCheckbox
              v-model="hidden"
              translation-key="modelPaint.hidden"
              v-bind="hiddenProps"
              name="hidden"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormCheckbox
              v-model="active"
              translation-key="modelPaint.active"
              v-bind="activeProps"
              name="active"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormCheckbox
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
      formId="admin-model-paint-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
