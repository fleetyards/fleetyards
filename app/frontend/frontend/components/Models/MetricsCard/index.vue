<script lang="ts">
export default {
  name: "MetricsCard",
};
</script>

<script lang="ts" setup>
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";

type Props = {
  title: string;
  variant?: "default" | "slim";
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
  loading: false,
});

const isSlim = computed(() => props.variant === "slim");
</script>

<template>
  <!--
    The card frame is Panel's now. What stays here is the part that is genuinely
    card-local: the Orbitron title tone, and the content primitives in
    metricsCard.scss - which live in the *consumer's* scope, because Vue keeps
    slotted markup in the parent's scope.

    outer-spacing is off because the card's own rhythm differs from the panel
    default of 21px, and that difference is unresolved rather than accidental.
  -->
  <Panel
    class="metrics-card"
    :class="{ 'metrics-card--slim': isSlim }"
    :outer-spacing="false"
    :variant="isSlim ? PanelVariantsEnum.SLIM : PanelVariantsEnum.DEFAULT"
  >
    <PanelHeading
      :tone="PanelHeadingTonesEnum.METRIC"
      :compact="isSlim"
      :divider="isSlim"
    >
      {{ title }}
      <template #actions>
        <SmallLoader :loading="loading" alignment="right" />
        <slot name="head" />
      </template>
    </PanelHeading>

    <PanelBody :class="{ 'metrics-card__body--slim': isSlim }">
      <slot />
    </PanelBody>
  </Panel>
</template>

<style scoped>
.metrics-card {
  margin: 15px 0 40px;
}

.metrics-card--slim {
  margin: 0 0 22px;
}

.metrics-card__body--slim {
  padding: 6px 14px 14px;
}
</style>
