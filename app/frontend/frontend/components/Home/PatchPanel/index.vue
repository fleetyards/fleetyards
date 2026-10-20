<script lang="ts">
export default {
  name: "HomePatchPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useScDataBuilds } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import patchArt from "@/images/bg-hangar.webp";

// One row per fact; a fact nobody has (yet) is left out rather than shown as 0.
type Fact = {
  key: string;
  label: string;
  value?: number;
};

type Props = {
  facts: Fact[];
  lede?: string;
};

withDefaults(defineProps<Props>(), {
  lede: undefined,
});

const { t } = useI18n();

const { data: builds } = useScDataBuilds();

const live = computed(() =>
  builds.value?.items.find((item) => item.environment.toLowerCase() === "live"),
);
</script>

<template>
  <Panel
    v-if="live"
    :bg-image="patchArt"
    class="home-patch-panel"
    data-test="home-patch-panel"
  >
    <PanelHeading :level="HeadingLevelEnum.H3">
      {{ t("home.patch.title", { version: live.version }) }}
      <template #actions>
        <Pill :variant="PillVariantsEnum.SUCCESS" uppercase>
          {{ live.environment }}
        </Pill>
      </template>
    </PanelHeading>
    <PanelBody>
      <p v-if="lede" class="home-patch-panel__lede">{{ lede }}</p>
      <div class="metrics-card__rows">
        <template v-for="fact in facts" :key="fact.key">
          <div v-if="fact.value !== undefined" class="metrics-card__row">
            <div class="metrics-card__row__label">{{ fact.label }}</div>
            <div class="metrics-card__row__value">{{ fact.value }}</div>
          </div>
        </template>
      </div>
      <div v-if="$slots.default" class="home-patch-panel__actions">
        <slot />
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.home-patch-panel__lede {
  margin: 0 0 12px;
}

.home-patch-panel__actions {
  margin-top: 14px;
}
</style>
