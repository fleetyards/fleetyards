<script lang="ts">
export default {
  name: "FleetDashboardPanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  title: string;
  loading?: boolean;
  // Said instead of the body when the panel has nothing to show. Left to the
  // caller to say only once its first answer is in: a refetch shows the panel
  // loading, and should not blank what it already says.
  empty?: boolean;
  emptyText?: string;
  more?: RouteLocationRaw;
  moreLabel?: string;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  empty: false,
  emptyText: undefined,
  more: undefined,
  moreLabel: undefined,
});

const { t } = useI18n();
</script>

<template>
  <Panel :variant="PanelVariantsEnum.SLIM" :loading="loading">
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ title }}
      <template v-if="more || $slots.actions" #actions>
        <slot name="actions" />
        <router-link v-if="more" :to="more" class="dashboard-panel__more">
          {{ moreLabel ?? t("fleetDashboard.showAll") }}
          <i class="fa-light fa-chevron-right" aria-hidden="true" />
        </router-link>
      </template>
    </PanelHeading>
    <PanelBody>
      <p v-if="empty" class="dashboard-panel__empty">
        {{ emptyText ?? t("fleetDashboard.empty") }}
      </p>
      <slot v-else />
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.dashboard-panel__more {
  font-size: 13px;
  white-space: nowrap;
}

.dashboard-panel__empty {
  margin: 0;
  color: var(--color-text-dim, #959595);
}
</style>
