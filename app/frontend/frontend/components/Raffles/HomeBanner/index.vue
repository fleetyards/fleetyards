<script lang="ts">
export default {
  name: "RaffleHomeBanner",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import {
  PanelTonesEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { RaffleStatusEnum } from "@/services/fyApi";
import { useHomeRaffle } from "@/frontend/components/Raffles/useHomeRaffle";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();

const raffle = useHomeRaffle();

const cover = computed(() => {
  const image = raffle.value?.images[0];

  return image?.smallUrl || image?.url;
});

const isOpen = computed(() => raffle.value?.status === RaffleStatusEnum.OPEN);
</script>

<template>
  <Panel
    v-if="raffle"
    :variant="PanelVariantsEnum.SLIM"
    :tone="isOpen ? PanelTonesEnum.SUCCESS : undefined"
    class="raffle-home-banner"
    data-test="raffle-home-banner"
  >
    <PanelBody>
      <div class="raffle-home-banner__body">
        <img
          v-if="cover"
          :src="cover"
          :alt="raffle.title"
          class="raffle-home-banner__cover"
        />
        <div class="raffle-home-banner__text">
          <div class="raffle-home-banner__title">
            <Pill
              :variant="
                isOpen ? PillVariantsEnum.SUCCESS : PillVariantsEnum.DEFAULT
              "
            >
              {{ t(`raffles.statuses.${raffle.status}`) }}
            </Pill>
            <router-link :to="{ name: 'raffles' }">
              {{ t("raffles.home.title", { title: raffle.title }) }}
            </router-link>
          </div>
          <span class="raffle-home-banner__meta">
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
          </span>
        </div>
        <Btn :to="{ name: 'raffles' }" :size="BtnSizesEnum.MD">
          {{ t("raffles.home.view") }}
          <i class="fa-light fa-chevron-right" />
        </Btn>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.raffle-home-banner__body {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
}

.raffle-home-banner__cover {
  width: 120px;
  aspect-ratio: 16 / 9;
  object-fit: cover;
  border-radius: var(--radius-control, 8px);
}

.raffle-home-banner__text {
  display: flex;
  flex: 1 1 240px;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.raffle-home-banner__title {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.raffle-home-banner__meta {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
