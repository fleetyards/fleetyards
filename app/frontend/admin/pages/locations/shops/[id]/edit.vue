<script lang="ts">
export default {
  name: "AdminShopEditPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type ShopInput,
  getLocationQueryKey,
  getShopQueryKey,
  useShop,
  useUpdateShop,
} from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const queryClient = useQueryClient();
const { updateMetaInfo } = useMetaInfo();

const shopId = computed(() => route.params.id as string);

const { data: shop, ...asyncStatus } = useShop(shopId);

watch(
  () => shop.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({ title: `${t("actions.edit")} ${value.name}` });
  },
  { immediate: true },
);

const crumbs = computed(() => [
  { to: { name: "admin-locations" }, label: t("nav.admin.locations.index") },
  {
    to: {
      name: "admin-location",
      params: { id: shop.value?.location.id ?? "" },
    },
    label: shop.value?.location.name ?? "",
  },
]);

const { defineField, handleSubmit, meta } = useForm<ShopInput>({
  initialValues: { image: undefined },
});

const [image, imageProps] = defineField("image");

const submitting = ref(false);

const backToPlace = () =>
  router.push({
    name: "admin-location",
    params: { id: shop.value?.location.id ?? "" },
  });

const updateMutation = useUpdateShop({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getShopQueryKey(shopId.value),
        }),
        queryClient.invalidateQueries({
          queryKey: getLocationQueryKey(shop.value?.location.id ?? ""),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({ id: shopId.value, data: values })
    .then(backToPlace)
    .catch((error) => {
      console.error("Error updating shop:", error);
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="shopId" />

      <Heading hero class="mb-4">{{ shop?.name }}</Heading>

      <form v-if="shop" id="admin-shop-edit-form" @submit.prevent="onSubmit">
        <p class="admin-shop-edit__hint">
          {{ t("labels.admin.locations.shopImageHint") }}
        </p>

        <div class="row">
          <div class="col-12 col-md-6">
            <FormFileInput
              v-model="image"
              v-bind="imageProps"
              :file="shop.image"
              translation-key="admin.locations.image"
              name="image"
              :allowed-types="AllowedFileTypes.IMAGE"
              clearable
            />
          </div>
          <div class="col-12 col-md-6">
            <img
              v-if="shop.image && image !== null"
              :src="shop.image.largeUrl ?? shop.image.url"
              alt=""
              class="admin-shop-edit__header"
              data-test="shop-header-preview"
            />
          </div>
        </div>

        <FormActions
          :submitting="submitting"
          form-id="admin-shop-edit-form"
          :dirty="meta.dirty"
          @cancel="backToPlace"
        />
      </form>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.admin-shop-edit {
  &__hint {
    margin: 0 0 16px;
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }

  &__header {
    display: block;
    width: 100%;
    max-height: 220px;
    object-fit: cover;
    border-radius: 12px;
  }
}
</style>
