<script lang="ts">
export default {
  name: "AdminManufacturerCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type ManufacturerInput,
  useCreateManufacturer,
  getManufacturersQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
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

const { defineField, handleSubmit, meta } = useForm<ManufacturerInput>({
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [longName, longNameProps] = defineField("longName");
const [code, codeProps] = defineField("code");
const [scRef, scRefProps] = defineField("scRef");
const [logo, logoProps] = defineField("logo");

const submitting = ref(false);

const createMutation = useCreateManufacturer({
  mutation: {
    onSettled: async () => {
      await queryClient.invalidateQueries({
        queryKey: getManufacturersQueryKey(),
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
          name: "admin-manufacturer-edit",
          params: { id: created.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating manufacturer:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-manufacturers" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.manufacturers.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-manufacturer-create-form">
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
          translation-key="manufacturer.logo"
          name="logo"
          :allowed-types="AllowedFileTypes.IMAGE"
          avatar
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-manufacturer-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
