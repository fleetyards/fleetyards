<script lang="ts">
export default {
  name: "SettingsFeatures",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  useUserFeatures,
  getUserFeaturesQueryKey,
  enableUserFeature,
  disableUserFeature,
  type UserFeature,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: features, isLoading } = useUserFeatures();
const queryClient = useQueryClient();
const invalidateUserFeatures = () =>
  queryClient.invalidateQueries({ queryKey: getUserFeaturesQueryKey() });

interface FeatureItem extends UserFeature {
  id: string;
}

const featureItems = computed<FeatureItem[]>(() => {
  if (!features.value) return [];
  return features.value.map((f) => ({ ...f, id: f.name }));
});

const toggleFeature = async (feature: FeatureItem) => {
  try {
    if (feature.enabled) {
      await disableUserFeature(feature.name);
    } else {
      await enableUserFeature(feature.name);
    }
    void invalidateUserFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};
</script>

<template>
  <Heading>{{ t("headlines.settings.features") }}</Heading>

  <p class="features-intro">
    {{ t("labels.features.settingsIntro") }}
  </p>

  <InlineEditableList
    empty-name="features"
    :loading="isLoading"
    :items="featureItems"
    hide-destroy
    hide-edit
  >
    <template #display="{ item }">
      <BasePill
        :variant="item.enabled ? 'success' : 'danger'"
        uppercase
        margin-right
      >
        {{
          item.enabled
            ? t("labels.features.stateOn")
            : t("labels.features.stateOff")
        }}
      </BasePill>
      <span class="feature-name">
        {{ item.name.replace(/_/g, " ").replace(/-/g, " ") }}
      </span>
    </template>

    <template #actions="{ item }">
      <Btn :size="BtnSizesEnum.SMALL" @click.prevent="toggleFeature(item)">
        <i :class="item.enabled ? 'fa-duotone fa-toggle-on' : 'fa-duotone fa-toggle-off'" />
      </Btn>
    </template>
  </InlineEditableList>
</template>

<style lang="scss" scoped>
.features-intro {
  margin-bottom: 1.5rem;
  color: var(--text-muted);
}

.feature-name {
  font-weight: 600;
  text-transform: capitalize;
}
</style>
