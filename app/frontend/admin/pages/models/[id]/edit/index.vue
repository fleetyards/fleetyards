<script lang="ts">
export default {
  name: "AdminModelEditPage",
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
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormImageInput from "@/shared/components/base/FormImageInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import ModelFilterGroup from "@/admin/components/base/ModelFilterGroup/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
import ModelClassificationFilterGroup from "@/frontend/components/base/ModelClassificationFilterGroup/index.vue";
import ModelFocusFilterGroup from "@/frontend/components/base/ModelFocusFilterGroup/index.vue";
import DirectUpload from "@/shared/components/DirectUpload/index.vue";
import { useModelUpdateMutation } from "@/admin/composables/useModelUpdateMutation";
// import { useAppNotifications } from "@/shared/composables/useAppNotifications";

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();

const { t } = useI18n();

// const { displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = ref<ModelUpdateInput>({
  name: props.model.name,
  description: props.model.description,
  hidden: props.model.hidden,
  active: props.model.active,
  ground: props.model.metrics.isGroundVehicle,
  rsiId: props.model.rsiId,
  scIdentifier: props.model.scIdentifier,
  erkulIdentifier: props.model.erkulIdentifier,
  baseModelId: props.model.baseModelId,
  manufacturerId: props.model.manufacturer?.id,
  productionStatus: props.model.productionStatus,
  productionNote: props.model.productionNote,
  classification: props.model.classification,
  focus: props.model.focus,
  storeImageNew: undefined,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit } = useForm<ModelUpdateInput>({
  initialValues: initialValues.value,
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
const [baseModelId, baseModelIdProps] = defineField("baseModelId");
const [manufacturerId, manufacturerIdProps] = defineField("manufacturerId");
const [productionStatus, productionStatusProps] =
  defineField("productionStatus");
const [productionNote, productionNoteProps] = defineField("productionNote");
const [classification, classificationProps] = defineField("classification");
const [focus, focusProps] = defineField("focus");
const [storeImageNew, storeImageNewProps] = defineField("storeImageNew");

const { updateMutation: mutation } = useModelUpdateMutation(props.model);

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      id: props.model.id,
      data: values,
    })
    .finally(() => {
      submitting.value = false;
    });
});

const onCancel = () => {
  alert("cancel");
};
</script>

<template>
  <Heading>{{ t("headlines.admin.models.edit.index") }}</Heading>
  <form @submit.prevent="onSubmit">
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
        <ModelFilterGroup
          v-model="baseModelId"
          v-bind="baseModelIdProps"
          translation-key="model.baseModel"
          :no-label="false"
          value-attr="id"
          :multiple="false"
          name="baseModelId"
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
      <div class="col-12">
        <DirectUpload multiple />
      </div>

      <div class="col-12 col-md-4">
        <FormImageInput
          v-model="storeImageNew"
          :image="model.media.storeImage?.small"
          translation-key="model.storeImage"
          v-bind="storeImageNewProps"
          name="storeImageNew"
        />
      </div>
    </div>

    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
</template>
