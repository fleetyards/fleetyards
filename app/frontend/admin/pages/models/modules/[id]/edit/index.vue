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
  useSyncComponentViews,
} from "@/services/fyAdminApi";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useForm } from "vee-validate";
import { useFormFeedback } from "@/admin/composables/useFormFeedback";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import {
  InputAlignmentsEnum,
  InputTypesEnum,
} from "@/shared/components/base/FormInput/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ManufacturerSelect from "@/admin/components/base/ManufacturerSelect/index.vue";
import ProductionStatusSelect from "@/admin/components/base/ProductionStatusSelect/index.vue";
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
  cargo: props.modelModule.cargo,
  manufacturerId: props.modelModule.manufacturer?.id ?? undefined,
  productionStatus: props.modelModule.productionStatus,
  active: props.modelModule.active,
  hidden: props.modelModule.hidden,
  storeImage: undefined,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta, setErrors } =
  useForm<ModelModuleInput>({
    initialValues: initialValues.value,
    validationSchema,
  });

const [name, nameProps] = defineField("name");
const [description, descriptionProps] = defineField("description");
const [scKey, scKeyProps] = defineField("scKey");
const [cargo, cargoProps] = defineField("cargo");
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

const { updated, failed } = useFormFeedback();

const { displayConfirm, displaySuccess } = useAppNotifications();

// The module's renders and hull lie on the part it is in the game files.
const syncViewsMutation = useSyncComponentViews({
  mutation: {
    onSuccess: () => {
      displaySuccess({ text: t("messages.itemViews.syncStarted") });
    },
  },
});

const syncViews = () => {
  const id = props.modelModule.componentId;
  if (!id) return;

  displayConfirm({
    text: t("messages.confirm.itemViews.sync"),
    onConfirm: async () => {
      await syncViewsMutation.mutateAsync({ id });
    },
  });
};

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.modelModule.id, data: values })
    .then(updated)
    .catch((error) => {
      failed(error, setErrors);
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
        <div
          v-if="modelModule.componentId"
          class="flex flex-wrap gap-2 mb-4"
          data-test="model-module-component-actions"
        >
          <Btn
            :to="{
              name: 'admin-component-edit',
              params: { id: modelModule.componentId },
            }"
            data-test="model-module-component-link"
          >
            <i class="fa-duotone fa-microchip" />
            {{ t("actions.itemViews.openComponent") }}
          </Btn>
          <Btn
            :loading="syncViewsMutation.isPending.value"
            data-test="model-module-sync-views"
            @click="syncViews"
          >
            <i class="fa-duotone fa-cloud-arrow-down" />
            {{ t("actions.itemViews.sync") }}
          </Btn>
        </div>
        <FormInput
          v-model="cargo"
          v-bind="cargoProps"
          :alignment="InputAlignmentsEnum.RIGHT"
          :type="InputTypesEnum.NUMBER"
          translation-key="modelModule.cargo"
          :suffix="t('number.units.cargo')"
          name="cargo"
        />
        <ManufacturerSelect
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
        <ProductionStatusSelect
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
