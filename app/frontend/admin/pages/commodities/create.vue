<script lang="ts">
export default {
  name: "AdminCommodityCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type CommodityInput,
  useCreateCommodity,
  getCommoditiesQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
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

const { defineField, handleSubmit, meta } = useForm<CommodityInput>({
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [commodityType, commodityTypeProps] = defineField("commodityType");
const [description, descriptionProps] = defineField("description");
const [uexId, uexIdProps] = defineField("uexId");
const [uexCode, uexCodeProps] = defineField("uexCode");
const [scKey, scKeyProps] = defineField("scKey");
const [scRef, scRefProps] = defineField("scRef");
const [storeImage, storeImageProps] = defineField("storeImage");

const submitting = ref(false);

const createMutation = useCreateCommodity({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getCommoditiesQueryKey(),
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
          name: "admin-commodity-edit",
          params: { id: created.id },
        }),
      );
    })
    .catch((error) => {
      console.error("Error creating commodity:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-commodities" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.commodities.new") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-commodity-create-form">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput v-model="name" v-bind="nameProps" name="name" />
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          name="description"
        />
        <FormInput
          v-model="commodityType"
          v-bind="commodityTypeProps"
          translation-key="commodity.commodityType"
          name="commodityType"
        />
      </div>
      <div class="col-12 col-md-6">
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="uexId"
              v-bind="uexIdProps"
              translation-key="commodity.uexId"
              name="uexId"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="uexCode"
              v-bind="uexCodeProps"
              translation-key="commodity.uexCode"
              name="uexCode"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scKey"
              v-bind="scKeyProps"
              translation-key="commodity.scKey"
              name="scKey"
            />
          </div>
          <div class="col-12 col-md-6">
            <FormInput
              v-model="scRef"
              v-bind="scRefProps"
              translation-key="commodity.scRef"
              name="scRef"
            />
          </div>
        </div>
        <hr />
        <FormFileInput
          v-model="storeImage"
          v-bind="storeImageProps"
          translation-key="commodity.storeImage"
          name="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-commodity-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
