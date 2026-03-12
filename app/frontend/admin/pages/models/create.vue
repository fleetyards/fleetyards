<script lang="ts">
export default {
  name: "AdminModelCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ModelCreateInput,
  useCreateModel,
  getModelsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
import ModelClassificationFilterGroup from "@/frontend/components/base/ModelClassificationFilterGroup/index.vue";
import ModelFocusFilterGroup from "@/frontend/components/base/ModelFocusFilterGroup/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ModelCreateInput>({
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [hidden, hiddenProps] = defineField("hidden");
const [active, activeProps] = defineField("active");
const [ground, groundProps] = defineField("ground");
const [rsiId, rsiIdProps] = defineField("rsiId");
const [scIdentifier, scIdentifierProps] = defineField("scIdentifier");
const [erkulIdentifier, erkulIdentifierProps] = defineField("erkulIdentifier");
const [manufacturerId, manufacturerIdProps] = defineField("manufacturerId");
const [productionStatus, productionStatusProps] =
  defineField("productionStatus");
const [productionNote, productionNoteProps] = defineField("productionNote");
const [classification, classificationProps] = defineField("classification");
const [focus, focusProps] = defineField("focus");
const [storeImageNew, storeImageNewProps] = defineField("storeImageNew");

const submitting = ref(false);

const createMutation = useCreateModel({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getModelsQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await createMutation
    .mutateAsync({ data: values })
    .then(async (createdModel) => {
      await router.push(
        extend({
          name: "admin-models-id-edit",
          params: { id: createdModel.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating model:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-models" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.models.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-models-create-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
        />
        <ManufacturerFilterGroup
          v-model="manufacturerId"
          v-bind="manufacturerIdProps"
          :no-label="false"
          value-attr="id"
          :multiple="false"
          name="manufacturer"
        />
      </div>
      <div class="col-12 col-md-6">
        <div class="row">
          <div class="col-12 col-md-4">
            <FormCheckbox
              v-model="hidden"
              translation-key="model.hidden"
              v-bind="hiddenProps"
              name="hidden"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormCheckbox
              v-model="active"
              translation-key="model.active"
              v-bind="activeProps"
              name="active"
            />
          </div>
          <div class="col-12 col-md-4">
            <FormCheckbox
              v-model="ground"
              translation-key="model.ground"
              v-bind="groundProps"
              name="ground"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="rsiId"
              translation-key="model.rsiId"
              v-bind="rsiIdProps"
              name="rsiId"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scIdentifier"
              v-bind="scIdentifierProps"
              translation-key="model.scIdentifier"
              name="scIdentifier"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="erkulIdentifier"
              translation-key="model.erkulIdentifier"
              v-bind="erkulIdentifierProps"
              name="erkulIdentifier"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <ModelClassificationFilterGroup
              v-model="classification"
              v-bind="classificationProps"
              :multiple="false"
              :no-label="false"
              name="classification"
            />
          </div>
          <div class="col-12 col-md-6">
            <ModelFocusFilterGroup
              v-model="focus"
              v-bind="focusProps"
              :no-label="false"
              :multiple="false"
              name="focus"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-12 col-md-6">
            <ProductionStatusFilterGroup
              v-model="productionStatus"
              :no-label="false"
              v-bind="productionStatusProps"
              :multiple="false"
              name="productionStatus"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="productionNote"
              translation-key="model.productionNote"
              v-bind="productionNoteProps"
              name="productionNote"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-12 col-md-4">
        <FormFileInput
          v-model="storeImageNew"
          translation-key="model.storeImage"
          v-bind="storeImageNewProps"
          name="storeImageNew"
          :allowed-types="AllowedFileTypes.IMAGE"
        />
      </div>
    </div>

    <FormActions
      :submitting="submitting"
      formId="admin-models-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
