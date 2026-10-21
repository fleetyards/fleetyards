<script lang="ts">
export default {
  name: "AdminHomepagePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import AsyncData from "@/shared/components/AsyncData.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import ModelSelect from "@/admin/components/base/ModelSelect/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import {
  useHomepageSettings,
  useUpdateHomepageSettings,
  getHomepageSettingsQueryKey,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const { data: settings, ...asyncStatus } = useHomepageSettings();

// A plain list rather than a form field: a multi-select replaces its whole
// value on every pick, and a vee-validate field keeps its own copy of the
// array -- the pick is counted, but its row is never marked.
const selectedModelIds = ref<string[]>([]);

const featuredRandom = ref(true);

const savedModelIds = computed(() => settings.value?.featuredModelIds ?? []);
const savedRandom = computed(() => settings.value?.featuredRandom ?? true);

const reset = () => {
  selectedModelIds.value = [...savedModelIds.value];
  featuredRandom.value = savedRandom.value;
};

// The settings arrive after the page is set up.
watch(settings, reset, { immediate: true });

// The picker hands back a string or a list depending on how it is used; this
// one always wants a list.
const onPick = (value?: string | string[]) => {
  selectedModelIds.value = Array.isArray(value) ? value : value ? [value] : [];
};

const dirty = computed(
  () =>
    featuredRandom.value !== savedRandom.value ||
    JSON.stringify(selectedModelIds.value) !==
      JSON.stringify(savedModelIds.value),
);

const submitting = ref(false);

const updateMutation = useUpdateHomepageSettings({
  mutation: {
    onSettled: () =>
      queryClient.invalidateQueries({
        queryKey: getHomepageSettingsQueryKey(),
      }),
  },
});

const onSubmit = async () => {
  submitting.value = true;

  await updateMutation
    .mutateAsync({
      data: {
        featuredModelIds: selectedModelIds.value,
        featuredRandom: featuredRandom.value,
      },
    })
    .then((saved) => {
      selectedModelIds.value = [...saved.featuredModelIds];
      featuredRandom.value = saved.featuredRandom;
      displaySuccess({ text: t("messages.homepageSetting.updated") });
    })
    .catch((error) => {
      console.error("Error saving the homepage:", error);
      displayAlert({ text: t("messages.homepageSetting.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.homepage") }}</Heading>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <form id="admin-homepage-form" @submit.prevent="onSubmit">
        <div class="row">
          <div class="col-12 col-md-6">
            <ModelSelect
              :model-value="selectedModelIds"
              name="featuredModelIds"
              translation-key="homepageSetting.featuredModels"
              value-attr="id"
              multiple
              :no-label="false"
              @update:model-value="onPick"
            />
            <p class="admin-homepage__info">
              {{ t("labels.homepageSetting.featuredModelsInfo") }}
            </p>
            <Btn
              v-if="selectedModelIds.length"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.GHOST"
              data-test="homepage-clear-featured-models"
              @click="selectedModelIds = []"
            >
              <i class="fa-light fa-xmark" />
              {{ t("labels.homepageSetting.clearFeaturedModels") }}
            </Btn>
            <FormToggle
              v-model="featuredRandom"
              name="featuredRandom"
              class="admin-homepage__random"
              :label="t('labels.homepageSetting.featuredRandom')"
              :description="t('labels.homepageSetting.featuredRandomInfo')"
              no-placeholder
              data-test="homepage-featured-random"
            />
          </div>
        </div>
        <FormActions
          :submitting="submitting"
          form-id="admin-homepage-form"
          :dirty="dirty"
          @cancel="reset"
        />
      </form>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.admin-homepage__random {
  margin-top: 16px;
}

.admin-homepage__info {
  margin: -8px 0 16px;
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}
</style>
