<script lang="ts">
export default {
  name: "AdminCommodityEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type Commodity,
  type CommodityInput,
  useUpdateCommodity,
  getCommoditiesQueryKey,
  getCommodityQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  commodity: Commodity;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const queryClient = useQueryClient();

const initialValues = ref<CommodityInput>({
  name: props.commodity.name,
  description: props.commodity.description,
  commodityType: props.commodity.commodityType,
  uexId: props.commodity.uexId,
  uexCode: props.commodity.uexCode,
  scKey: props.commodity.scKey,
  scRef: props.commodity.scRef,
  storeImage: undefined,
});

const validationSchema = {
  name: "required",
};

const { defineField, handleSubmit, meta } = useForm<CommodityInput>({
  initialValues: initialValues.value,
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

const updateMutation = useUpdateCommodity({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getCommoditiesQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getCommodityQueryKey(props.commodity.id),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: props.commodity.id, data: values })
    .catch((error) => {
      console.error("Error updating commodity:", error);
      alert(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-commodities",
      hash: `#${props.commodity.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.commodities.edit.index") }}</Heading>
  <form @submit.prevent="onSubmit" id="admin-commodity-edit-form">
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
          :file="commodity.storeImage"
          translation-key="commodity.storeImage"
          name="storeImage"
          :allowed-types="AllowedFileTypes.IMAGE"
          clearable
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      formId="admin-commodity-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
