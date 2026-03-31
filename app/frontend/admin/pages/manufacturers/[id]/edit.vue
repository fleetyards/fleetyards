<script lang="ts">
export default {
  name: "AdminManufacturerEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type Manufacturer,
  type ManufacturerInput,
  useUpdateManufacturer,
  getManufacturersQueryKey,
  getManufacturerQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  manufacturer: Manufacturer;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<ManufacturerInput>({
  name: props.manufacturer.name,
  longName: props.manufacturer.longName,
  code: props.manufacturer.code,
  description: undefined,
  knownFor: undefined,
  logo: undefined,
  scRef: props.manufacturer.scRef,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<ManufacturerInput>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [longName, longNameProps] = defineField("longName");
const [code, codeProps] = defineField("code");
const [scRef, scRefProps] = defineField("scRef");
const [logo, logoProps] = defineField("logo");

const submitting = ref(false);

const updateMutation = useUpdateManufacturer({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getManufacturersQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getManufacturerQueryKey(props.manufacturer.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.manufacturer.id, data: values })
    .catch((error) => {
      console.error("Error updating manufacturer:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-manufacturers",
      hash: `#${props.manufacturer.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.manufacturers.edit") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-manufacturer-edit-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormInput
          v-model="longName"
          v-bind="longNameProps"
          translation-key="manufacturer.longName"
          name="longName"
        />
        <FormInput
          v-model="code"
          v-bind="codeProps"
          translation-key="manufacturer.code"
          name="code"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormInput
          v-model="scRef"
          v-bind="scRefProps"
          translation-key="manufacturer.scRef"
          name="scRef"
        />
        <FormFileInput
          v-model="logo"
          v-bind="logoProps"
          :file="manufacturer.logo"
          translation-key="manufacturer.logo"
          name="logo"
          :allowed-types="AllowedFileTypes.IMAGE"
          avatar
          clearable
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-manufacturer-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
