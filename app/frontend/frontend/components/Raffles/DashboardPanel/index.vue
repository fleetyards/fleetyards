<script lang="ts">
export default {
  name: "RaffleDashboardPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { storeToRefs } from "pinia";
import { RaffleStatusEnum } from "@/services/fyApi";
import { useSessionStore } from "@/frontend/stores/session";
import { useHomeRaffle } from "@/frontend/components/Raffles/useHomeRaffle";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const raffle = useHomeRaffle();

const cover = computed(() => {
  const image = raffle.value?.images[0];

  return image?.mediumUrl || image?.url;
});

const isOpen = computed(() => raffle.value?.status === RaffleStatusEnum.OPEN);

const { currentUser } = storeToRefs(useSessionStore());

const canEnter = computed(
  () =>
    isOpen.value && !raffle.value?.entered && !currentUser?.value?.maintainer,
);
</script>

<template>
  <Panel
    v-if="raffle"
    :variant="PanelVariantsEnum.SLIM"
    data-test="raffle-dashboard-panel"
  >
    <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
      {{ t("raffles.home.panelTitle") }}
    </PanelHeading>
    <PanelImage v-if="cover" :image="cover" :alt="raffle.title" />
    <PanelBody>
      <p class="raffle-dashboard__title">{{ raffle.title }}</p>
      <p class="raffle-dashboard__meta">
        {{
          isOpen
            ? t("raffles.meta", {
                date: l(raffle.endsAt, "datetime.formats.short"),
                count: raffle.entriesCount,
              })
            : t("raffles.entry.opensAt", {
                date: l(raffle.startsAt, "datetime.formats.short"),
              })
        }}
      </p>
      <div class="raffle-dashboard__row">
        <Pill v-if="raffle.entered" :variant="PillVariantsEnum.SUCCESS">
          {{ t("raffles.home.entered") }}
        </Pill>
        <span v-else-if="canEnter" class="raffle-dashboard__meta">
          {{ t("raffles.home.notEntered") }}
        </span>
        <Btn
          :to="{ name: 'raffles' }"
          :size="BtnSizesEnum.SM"
          :variant="raffle.entered ? BtnVariantsEnum.BARE : undefined"
        >
          {{ canEnter ? t("raffles.home.enter") : t("raffles.home.view") }}
        </Btn>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-dashboard__title {
  margin: 0 0 4px;
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.raffle-dashboard__meta {
  margin: 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}

.raffle-dashboard__row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-top: 12px;
}
</style>
