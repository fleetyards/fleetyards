<script lang="ts">
export default {
  name: "AdminModelModuleEditIndexPage",
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
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ManufacturerFilterGroup from "@/admin/components/base/ManufacturerFilterGroup/index.vue";
import ProductionStatusFilterGroup from "@/admin/components/base/ProductionStatusFilterGroup/index.vue";
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
  name: props.modelModule.name,
  description: props.modelModule.description,
  scKey: props.modelModule.scKey,
  manufacturerId: props.modelModule.manufacturer?.id ?? undefined,
  productionStatus: props.modelModule.productionStatus,
  active: props.modelModule.active,
  hidden: props.modelModule.hidden,
  storeImage: undefined,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ModelModuleInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [scKey, scKeyProps] = defineField("scKey");
const [manufacturerId, manufacturerIdProps] = defineField("manufacturerId");
const [productionStatus, productionStatusProps] =
  defineField("productionStatus");
const [active, activeProps] = defineField("active");
const [hidden, hiddenProps] = defineField("hidden");
const [storeImage, storeImageProps] = defineField("storeImage");

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
      console.error("Error updating model module:", error);
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
</script>

<template>
  <Heading hero>{{ t("headlines.admin.modelModules.edit") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-model-module-edit-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
        />
        <FormInput
          v-model="scKey"
          v-bind="scKeyProps"
          translation-key="modelModule.scKey"
          name="scKey"
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
          <div class="col-12 col-md-6">
            <FormToggle
              v-model="hidden"
              translation-key="modelModule.hidden"
              v-bind="hiddenProps"
              name="hidden"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormToggle
              v-model="active"
              translation-key="modelModule.active"
              v-bind="activeProps"
              name="active"
            />
          </div>
        </div>
        <hr />
        <ProductionStatusFilterGroup
          v-model="productionStatus"
          v-bind="productionStatusProps"
          :no-label="false"
          :multiple="false"
          name="productionStatus"
        />
        <FormFileInput
          v-model="storeImage"
          v-bind="storeImageProps"
          :file="modelModule.media.storeImage"
          translation-key="modelModule.storeImage"
          name="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-model-module-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
