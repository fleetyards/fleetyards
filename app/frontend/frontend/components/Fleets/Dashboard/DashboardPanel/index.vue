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
  // The first answer is still out: the panel stands in its place, loading, and
  // says nothing yet rather than that it has nothing.
  pending?: boolean;
  // Any ask is out, a refetch included. The bar shows over what the panel
  // already says.
  fetching?: boolean;
  // The ask failed with no answer to fall back on. Callers pass it as
  // `isError && !data`: TanStack keeps a failed refetch's old answer and still
  // reports the error, and that answer is what the panel should go on saying.
  failed?: boolean;
  // Nothing to show once answered: the `empty` slot stands in for the body.
  empty?: boolean;
  more?: RouteLocationRaw;
  moreLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  pending: false,
  fetching: false,
  failed: false,
  empty: false,
  more: undefined,
  moreLabel: undefined,
});

const state = computed(() => {
  if (!props.empty) return "content";
  if (props.pending) return "pending";
  if (props.failed) return "failed";

  return "empty";
});

const { t } = useI18n();
</script>

<template>
  <Panel
    :variant="PanelVariantsEnum.SLIM"
    :loading="pending || fetching"
    :aria-busy="pending || fetching"
  >
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
    <PanelBody class="dashboard-panel__body">
      <slot v-if="state === 'content'" />
      <div v-else-if="state === 'pending'" class="dashboard-panel__pending" />
      <p
        v-else-if="state === 'failed'"
        class="dashboard-panel__note"
        data-test="fleet-dashboard-failed"
      >
        {{ t("fleetDashboard.failed") }}
      </p>
      <slot v-else name="empty">
        <p class="dashboard-panel__note">{{ t("fleetDashboard.empty") }}</p>
      </slot>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
// The body's own top padding is sized for a heading without a rule under it;
// under the divider the content would start against the line. Doubled class to
// outrank PanelBody's scoped rule regardless of stylesheet order.
.dashboard-panel__body.panel-body {
  padding-top: 14px;
}

.dashboard-panel__more {
  font-size: 13px;
  white-space: nowrap;
}

// Holds the panel at about one row's height, so the answer does not push the
// column down as far.
.dashboard-panel__pending {
  min-height: 40px;
}

.dashboard-panel__note {
  margin: 0;
  color: var(--color-text-dim, #959595);
}
</style>
