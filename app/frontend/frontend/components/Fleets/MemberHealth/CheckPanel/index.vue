<script lang="ts">
export default {
  name: "FleetMemberHealthCheckPanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import {
  PanelTonesEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import type { MemberHealthCheck } from "@/frontend/utils/memberHealth";

type Props = {
  check: MemberHealthCheck;
  title: string;
  description: string;
  clearLine: string;
  more?: RouteLocationRaw;
  moreLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  more: undefined,
  moreLabel: undefined,
});

const pillVariant = computed(
  () =>
    ({
      critical: PillVariantsEnum.DANGER,
      attention: PillVariantsEnum.WARNING,
      info: PillVariantsEnum.NEUTRAL,
      ok: PillVariantsEnum.SUCCESS,
    })[props.check.tone],
);

const panelTone = computed(() =>
  props.check.tone === "critical"
    ? PanelTonesEnum.ERROR
    : PanelTonesEnum.NEUTRAL,
);
</script>

<template>
  <section
    :id="`health-${check.key}`"
    class="health-check"
    :data-test="`health-${check.key}`"
    :data-tone="check.tone"
  >
    <Panel
      v-if="check.tone === 'ok'"
      :variant="PanelVariantsEnum.SLIM"
      :outer-spacing="false"
    >
      <p class="health-check__clear">
        <i
          class="fa-light fa-check health-check__clear-icon"
          aria-hidden="true"
        />
        <span class="health-check__clear-title">{{ title }}</span>
        <span class="health-check__clear-line">{{ clearLine }}</span>
        <!-- Kept on a clear check: the inactive check's threshold is how a
             reader asks whether a shorter window would find anyone. -->
        <span v-if="$slots.actions" class="health-check__clear-actions">
          <slot name="actions" />
        </span>
      </p>
    </Panel>
    <Panel
      v-else
      :variant="PanelVariantsEnum.SLIM"
      :tone="panelTone"
      :outer-spacing="false"
    >
      <PanelHeading
        :level="HeadingLevelEnum.H3"
        :size="HeadingSizeEnum.LG"
        compact
        divider
      >
        {{ title }}
        <Pill :variant="pillVariant" class="health-check__count">
          {{ check.display }}
        </Pill>
        <template #subtitle>{{ description }}</template>
        <template v-if="$slots.actions" #actions>
          <slot name="actions" />
        </template>
      </PanelHeading>
      <slot name="before" />
      <slot />
      <PanelBody v-if="more" class="health-check__footer">
        <router-link :to="more" :data-test="`health-${check.key}-all`">
          {{ moreLabel }}
          <i class="fa-light fa-arrow-right" aria-hidden="true" />
        </router-link>
      </PanelBody>
    </Panel>
  </section>
</template>

<style lang="scss" scoped>
.health-check {
  scroll-margin-top: 80px;
}

.health-check__count {
  margin-left: 8px;
  vertical-align: middle;
}

.health-check__clear {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px 10px;
  margin: 0;
  padding: 14px 20px;
}

.health-check__clear-icon {
  color: var(--color-success, #5cb85c);
}

.health-check__clear-title {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.health-check__clear-line {
  color: var(--color-text-dim, #959595);
}

.health-check__clear-actions {
  margin-left: auto;
}

.health-check__footer {
  font-weight: 600;
}
</style>
