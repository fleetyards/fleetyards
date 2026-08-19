<script lang="ts">
export default {
  name: "SettingsFeatures",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import {
  useUserFeatures,
  getUserFeaturesQueryKey,
  getFeaturesQueryKey,
  enableUserFeature,
  disableUserFeature,
  UserFeatureScope,
  type UserFeature,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: features, isLoading } = useUserFeatures();
const queryClient = useQueryClient();
const invalidateUserFeatures = () =>
  Promise.all([
    queryClient.invalidateQueries({ queryKey: getUserFeaturesQueryKey() }),
    queryClient.invalidateQueries({ queryKey: getFeaturesQueryKey() }),
  ]);

interface FeatureItem extends UserFeature {
  id: string;
}

const featureItems = computed<FeatureItem[]>(() => {
  if (!features.value) return [];
  return features.value.map((f) => ({ ...f, id: f.name }));
});

// A fleet feature has two switches with different reach: this one enables it for
// you alone, and a fleet admin's enables it for everyone in that fleet. The pill
// and its tooltip are what keep the two apart.
const isFleetFeature = (feature: FeatureItem) =>
  feature.scope === UserFeatureScope.fleet;

// The fleet already gives every member the feature, so there is nothing for a
// personal switch to add — and it cannot take it away either.
const grantedByFleet = (feature: FeatureItem) => feature.fleets.length > 0;

const toggleFeature = async (feature: FeatureItem) => {
  if (grantedByFleet(feature)) return;

  try {
    if (feature.enabledForSelf) {
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
  <BreadCrumbs
    :crumbs="[{ to: { name: 'settings' }, label: t('nav.settings.index') }]"
  />

  <Heading hero>{{ t("headlines.settings.features") }}</Heading>

  <p class="features-intro">
    {{ t("labels.features.settingsIntro") }}
  </p>

  <Loader :loading="isLoading" />

  <Empty v-if="!featureItems.length && !isLoading" variant="box" hide-actions>
    <template #headline>
      {{ t("empty.headlines.features") }}
    </template>
    <template #info>
      <p>{{ t("empty.info.features") }}</p>
    </template>
  </Empty>

  <InlineEditableList
    v-if="featureItems.length"
    :items="featureItems"
    hide-destroy
    hide-edit
  >
    <template #display="{ item }">
      <BasePill
        :variant="
          item.enabled ? PillVariantsEnum.SUCCESS : PillVariantsEnum.DANGER
        "
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
      <span
        v-if="isFleetFeature(item)"
        v-tooltip="
          grantedByFleet(item)
            ? t('labels.features.fleetFeatureGranted')
            : t('labels.features.fleetFeatureInfo')
        "
        class="feature-scope"
      >
        <BasePill uppercase>
          {{
            grantedByFleet(item)
              ? t("labels.features.fleetFeatureGrantedShort")
              : t("labels.features.fleetFeature")
          }}
        </BasePill>
      </span>
      <span v-if="grantedByFleet(item)" class="feature-fleets">
        <template v-for="(fleet, index) in item.fleets" :key="fleet.slug">
          <span v-if="index > 0">, </span>
          <router-link :to="{ name: 'fleet', params: { slug: fleet.slug } }">
            {{ fleet.name }}
          </router-link>
        </template>
      </span>
    </template>

    <template #actions="{ item, mobile }">
      <Btn
        v-tooltip="
          grantedByFleet(item)
            ? t('labels.features.fleetFeatureGranted')
            : isFleetFeature(item)
              ? t('labels.features.toggleForSelf')
              : t('labels.features.toggle')
        "
        :disabled="grantedByFleet(item)"
        @click="toggleFeature(item)"
        :variant="BtnVariantsEnum.GHOST"
      >
        <i
          class="fa-duotone fa-power-off"
          :class="item.enabled ? 'text-success' : 'text-muted'"
        />
        <span v-if="mobile">{{ t("labels.features.toggle") }}</span>
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

.feature-scope {
  margin-left: 0.5rem;
}

.feature-fleets {
  margin-left: 0.5rem;
  color: var(--text-muted);
}
</style>
