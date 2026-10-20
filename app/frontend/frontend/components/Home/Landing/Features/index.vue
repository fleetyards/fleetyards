<script lang="ts">
export default {
  name: "HomeLandingFeatures",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

type Feature = {
  key: string;
  icon: string;
  to: RouteLocationRaw;
};

const features: Feature[] = [
  {
    key: "hangar",
    icon: "fa-light fa-warehouse",
    to: { name: "hangar-preview" },
  },
  { key: "fleets", icon: "fa-light fa-users", to: { name: "fleet-preview" } },
  { key: "ships", icon: "fa-light fa-crosshairs", to: { name: "ships" } },
  { key: "compare", icon: "fa-light fa-code-compare", to: { name: "compare" } },
  { key: "trade", icon: "fa-light fa-route", to: { name: "trade-routes" } },
  { key: "patches", icon: "fa-light fa-code-branch", to: { name: "stats" } },
];
</script>

<template>
  <div class="home-landing-features">
    <Panel
      v-for="feature in features"
      :key="feature.key"
      :outer-spacing="false"
    >
      <PanelHeading :level="HeadingLevelEnum.H3">
        {{ t(`home.landing.features.${feature.key}.title`) }}
      </PanelHeading>
      <PanelBody class="home-landing-features__body">
        <p>{{ t(`home.landing.features.${feature.key}.text`) }}</p>
        <div>
          <Btn :size="BtnSizesEnum.SM" :to="feature.to">
            <i :class="feature.icon" />
            {{ t(`home.landing.features.${feature.key}.action`) }}
          </Btn>
        </div>
      </PanelBody>
    </Panel>
  </div>
</template>

<style lang="scss" scoped>
.home-landing-features {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.home-landing-features__body {
  display: flex;
  flex-direction: column;
  gap: 14px;

  p {
    margin: 0;
  }
}

@media (max-width: 991px) {
  .home-landing-features {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 575px) {
  .home-landing-features {
    grid-template-columns: minmax(0, 1fr);
  }
}
</style>
