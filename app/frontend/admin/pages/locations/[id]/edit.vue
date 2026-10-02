<script lang="ts">
export default {
  name: "AdminLocationEditPage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Location,
  type LocationInput,
  getLocationQueryKey,
  getLocationsQueryKey,
  useLocation,
  useUpdateLocation,
} from "@/services/fyAdminApi";
import AsyncData from "@/shared/components/AsyncData.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormFileInput from "@/shared/components/base/FormFileInput/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { AllowedFileTypes } from "@/shared/components/DirectUpload/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { globeStyle } from "@/shared/utils/LocationGlobe";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const queryClient = useQueryClient();
const { updateMetaInfo } = useMetaInfo();

const locationId = computed(() => route.params.id as string);

const { data: location, ...asyncStatus } = useLocation(locationId);

const title = (record?: Location) => record?.name || record?.scKey || "";

watch(
  () => location.value,
  (value) => {
    if (!value) return;

    updateMetaInfo({ title: `${t("actions.edit")} ${title(value)}` });
  },
  { immediate: true },
);

const crumbs = computed(() => [
  {
    to: { name: "admin-locations", hash: `#${locationId.value}` },
    label: t("nav.admin.locations.index"),
  },
  {
    to: { name: "admin-location", params: { id: locationId.value } },
    label: title(location.value),
  },
]);

const { defineField, handleSubmit, meta, resetForm, values } =
  useForm<LocationInput>({
    validationSchema: {
      color: { regex: /^#[0-9a-fA-F]{6}$/ },
    },
  });

watch(
  () => location.value,
  (value) => {
    if (!value) return;

    resetForm({ values: { color: value.color ?? null, image: undefined } });
  },
  { immediate: true },
);

const [color, colorProps] = defineField("color");
const [image, imageProps] = defineField("image");

// The colour as it is typed, over the picture already uploaded, so the
// preview shows what the strip will draw.
const preview = computed(() =>
  globeStyle({
    color: /^#[0-9a-fA-F]{6}$/.test(values.color ?? "") ? values.color : null,
    image: values.image === null ? null : location.value?.image,
  }),
);

const submitting = ref(false);

const updateMutation = useUpdateLocation({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({ queryKey: getLocationsQueryKey() }),
        queryClient.invalidateQueries({
          queryKey: getLocationQueryKey(locationId.value),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (formValues) => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      id: locationId.value,
      data: { ...formValues, color: formValues.color || null },
    })
    .then(() =>
      router.push({ name: "admin-location", params: { id: locationId.value } }),
    )
    .catch((error) => {
      console.error("Error updating location:", error);
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push({
    name: "admin-location",
    params: { id: locationId.value },
  });
};
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <BreadCrumbs :crumbs="crumbs" :current-id="locationId" />

      <Heading hero class="mb-4">{{ title(location) }}</Heading>

      <form
        v-if="location"
        id="admin-location-edit-form"
        @submit.prevent="onSubmit"
      >
        <h2 class="admin-location-edit__title">
          {{ t("labels.admin.locations.appearance") }}
        </h2>
        <p class="admin-location-edit__hint">
          {{ t("labels.admin.locations.appearanceHint") }}
        </p>

        <div class="row">
          <div class="col-12 col-md-6">
            <FormFileInput
              v-model="image"
              v-bind="imageProps"
              :file="location.image"
              translation-key="admin.locations.image"
              name="image"
              :allowed-types="AllowedFileTypes.IMAGE"
              clearable
            />
            <FormInput
              v-model="color"
              v-bind="colorProps"
              translation-key="admin.locations.color"
              name="color"
              placeholder="#a0522d"
              clearable
            />
          </div>
          <div class="col-12 col-md-6">
            <span
              class="admin-location-edit__globe"
              :style="preview"
              data-test="location-globe-preview"
              aria-hidden="true"
            />
          </div>
        </div>

        <FormActions
          :submitting="submitting"
          form-id="admin-location-edit-form"
          :dirty="meta.dirty"
          @cancel="handleCancel"
        />
      </form>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.admin-location-edit {
  &__title {
    margin: 0 0 4px;
    font-size: 16px;
  }

  &__hint {
    margin: 0 0 16px;
    font-size: 13px;
    color: var(--color-text-dim, #959595);
  }

  &__globe {
    display: block;
    width: 120px;
    height: 120px;
    border-radius: 50%;
    background-color: #1d2329;
    border: 1px solid
      var(--globe-border, var(--color-edge-soft, rgb(122 130 136 / 0.55)));
  }
}
</style>
