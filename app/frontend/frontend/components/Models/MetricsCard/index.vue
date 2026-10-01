<script lang="ts">
export default {
  name: "MetricsCard",
};
</script>

<script lang="ts" setup>
import LoadingLine from "@/shared/components/LoadingLine/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  title: string;
  variant?: "default" | "slim";
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
  loading: false,
});

const { t } = useI18n();

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
    :aria-busy="loading"
  >
    <!-- A wrapper rather than a child of the heading: the heading's slots sit
         inside its title, whose text the e2e specs read, and inside its
         absolutely positioned actions, which the line would run along. -->
    <div class="metrics-card__head">
      <PanelHeading
        :tone="PanelHeadingTonesEnum.METRIC"
        :compact="isSlim"
        :divider="isSlim"
      >
        {{ title }}
        <template v-if="$slots.head" #actions>
          <slot name="head" />
        </template>
      </PanelHeading>
      <LoadingLine
        :loading="loading"
        :label="t('labels.statsCard.loading', { name: title })"
        edge="bottom"
      />
    </div>

    <PanelBody :class="{ 'metrics-card__body--slim': isSlim }">
      <slot />
    </PanelBody>
  </Panel>
</template>

<style scoped>
/*
 * One rhythm, matching Panel's own 21px. The card carried 15px/40px and the slim
 * variant 22px, so a column of cards sat almost twice as far apart as a column of
 * panels - which is why the panel's spacing wins.
 */
.metrics-card,
.metrics-card--slim {
  margin: 0 0 21px;
}

.metrics-card__head {
  position: relative;
}

.metrics-card__body--slim {
  padding: 6px 14px 14px;
}
</style>
