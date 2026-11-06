<script lang="ts">
export default {
  name: "MetricsCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Collapsed from "@/shared/components/Collapsed.vue";
import LoadingLine from "@/shared/components/LoadingLine/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";
import { metricsCardFoldKey, type MetricsCardFold } from "./fold";

type Props = {
  title: string;
  variant?: "default" | "slim";
  loading?: boolean;
  // Names the card among a page's folded ones. It only folds on a page that
  // provides somewhere to remember that.
  collapseKey?: string;
  // The body stays when folded, and the consumer swaps what is in it.
  keepBody?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: "default",
  loading: false,
  collapseKey: undefined,
  keepBody: false,
});

const { t } = useI18n();

const isSlim = computed(() => props.variant === "slim");

const fold = inject<MetricsCardFold | undefined>(metricsCardFoldKey, undefined);

const foldable = computed(() => !!fold && !!props.collapseKey);

const collapsed = computed(
  () => !!props.collapseKey && !!fold?.collapsed(props.collapseKey),
);

const toggleCollapsed = () => {
  if (props.collapseKey) fold?.toggle(props.collapseKey);
};
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
    <!-- A wrapper rather than a child of the heading: the heading's slots sit
         inside its title, whose text the e2e specs read, and inside its
         absolutely positioned actions, which the line would run along. -->
    <div class="metrics-card__head">
      <PanelHeading
        :tone="PanelHeadingTonesEnum.METRIC"
        :class="{ 'metrics-card__heading--foldable': foldable }"
        :compact="isSlim"
        :divider="isSlim"
      >
        {{ title }}
        <template v-if="$slots.head" #actions>
          <slot name="head" />
        </template>
      </PanelHeading>
      <Btn
        v-if="foldable"
        class="metrics-card__collapse"
        :variant="BtnVariantsEnum.BARE"
        :size="BtnSizesEnum.XS"
        :aria-expanded="!collapsed"
        :aria-label="t(collapsed ? 'labels.expand' : 'labels.collapse')"
        data-test="metrics-card-collapse"
        @click="toggleCollapsed"
      >
        <i
          class="fa-solid"
          :class="collapsed ? 'fa-chevron-down' : 'fa-chevron-up'"
          aria-hidden="true"
        />
      </Btn>
      <LoadingLine
        :loading="loading"
        :label="t('labels.statsCard.loading', { name: title })"
        edge="bottom"
      />
    </div>

    <!-- Only where the card folds: everywhere else the body stays a direct child
         of the panel. -->
    <Collapsed
      v-if="foldable && !keepBody"
      :visible="!collapsed"
      :duration="200"
    >
      <PanelBody :class="{ 'metrics-card__body--slim': isSlim }">
        <slot />
      </PanelBody>
    </Collapsed>
    <PanelBody v-else :class="{ 'metrics-card__body--slim': isSlim }">
      <slot />
    </PanelBody>

    <template v-if="$slots.footer && (keepBody || !collapsed)" #footer>
      <slot name="footer" />
    </template>
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

/*
 * Beside the title rather than in the heading's actions: a metric heading wraps
 * so a card's chips can flow, and a long title took the control down with it.
 * The title keeps clear of the corner and wraps on its own line instead.
 */
.metrics-card__heading--foldable {
  padding-right: 52px;
}

.metrics-card__collapse {
  position: absolute;
  top: 13px;
  right: 10px;
}

.metrics-card--slim .metrics-card__collapse {
  top: 9px;
}
</style>
