<script lang="ts">
export default {
  name: "FleetSettingsFeatures",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import {
  useFleetFeatures,
  getFleetFeaturesQueryKey,
  getFleetQueryKey,
  enableFleetFeature,
  disableFleetFeature,
  type Fleet,
  type FleetFeature,
  type FleetMember,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: features, isLoading } = useFleetFeatures(
  computed(() => props.fleet.slug),
);

const queryClient = useQueryClient();

// The fleet payload carries the flags, so the tabs and pages gated on them only
// change once it is refetched.
const invalidateFeatures = () =>
  Promise.all([
    queryClient.invalidateQueries({
      queryKey: getFleetFeaturesQueryKey(props.fleet.slug),
    }),
    queryClient.invalidateQueries({
      queryKey: getFleetQueryKey(props.fleet.slug),
    }),
  ]);

interface FeatureItem extends FleetFeature {
  id: string;
}

const featureItems = computed<FeatureItem[]>(
  () =>
    features.value?.map((feature) => ({ ...feature, id: feature.name })) ?? [],
);

const toggleFeature = async (feature: FeatureItem) => {
  try {
    if (feature.enabled) {
      await disableFleetFeature(props.fleet.slug, feature.name);
    } else {
      await enableFleetFeature(props.fleet.slug, feature.name);
    }
    void invalidateFeatures();
    displaySuccess({ text: t("messages.features.updated") });
  } catch {
    displayAlert({ text: t("messages.features.error") });
  }
};
</script>

<template>
  <p class="features-intro">
    {{ t("labels.features.fleetSettingsIntro") }}
  </p>

  <Loader :loading="isLoading" />

  <Empty v-if="!featureItems.length && !isLoading" variant="box" hide-actions>
    <template #headline>
      {{ t("empty.headlines.fleetFeatures") }}
    </template>
    <template #info>
      <p>{{ t("empty.info.fleetFeatures") }}</p>
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
    </template>

    <template #actions="{ item, mobile }">
      <Btn
        v-tooltip="t('labels.features.toggle')"
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
</style>
