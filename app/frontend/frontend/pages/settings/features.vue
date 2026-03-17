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
import Box from "@/shared/components/Box/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import Toggle from "@/shared/components/base/Toggle/index.vue";
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

  <Loader :loading="isLoading" />

  <Box v-if="!featureItems.length && !isLoading" :large="true">
    <p class="features-empty text-muted">
      {{ t("labels.features.noFeaturesAvailable") }}
    </p>
  </Box>

  <InlineEditableList
    v-if="featureItems.length"
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
      <Toggle
        :active="item.enabled"
        @toggle="toggleFeature(item)"
      />
    </template>
  </InlineEditableList>
</template>

<style lang="scss" scoped>
.features-intro {
  margin-bottom: 1.5rem;
  color: var(--text-muted);
}

.features-empty {
  text-align: center;
  padding: 2rem 0;
  margin: 0;
}

.feature-name {
  font-weight: 600;
  text-transform: capitalize;
}
</style>
