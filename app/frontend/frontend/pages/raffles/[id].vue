<script lang="ts">
export default {
  name: "RafflePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Heading from "@/shared/components/base/Heading/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import AsyncData from "@/shared/components/AsyncData.vue";
import RaffleKeyImage from "@/frontend/components/Raffles/KeyImage/index.vue";
import RaffleEntryPanel from "@/frontend/components/Raffles/EntryPanel/index.vue";
import RaffleHowItWorks from "@/frontend/components/Raffles/HowItWorks/index.vue";
import RaffleConditions from "@/frontend/components/Raffles/Conditions/index.vue";
import RaffleWinners from "@/frontend/components/Raffles/Winners/index.vue";
import RaffleEntrants from "@/frontend/components/Raffles/Entrants/index.vue";
import {
  RaffleStatusEnum,
  useRaffle,
  useCurrentRaffle,
  getRaffleQueryKey,
  getCurrentRaffleQueryKey,
  getRaffleEntrantsQueryKey,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();
const route = useRoute();
const queryClient = useQueryClient();

// Without an id in the address this is the raffles page, which shows the one
// raffle that is current: there is only ever one online.
const routeId = computed(() => route.params.id as string | undefined);

const byId = useRaffle(() => routeId.value ?? "", {
  query: { enabled: () => !!routeId.value },
});
const current = useCurrentRaffle({
  query: { enabled: () => !routeId.value },
});

const { data: raffle, ...asyncStatus } = routeId.value ? byId : current;

const refresh = () =>
  Promise.all([
    queryClient.invalidateQueries({
      queryKey: getRaffleQueryKey(raffle.value?.id ?? ""),
    }),
    queryClient.invalidateQueries({ queryKey: getCurrentRaffleQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getRaffleEntrantsQueryKey(raffle.value?.id ?? ""),
    }),
  ]);

// The uploaded gallery, or the prize ship's store image when the raffle has
// no pictures of its own.
const keyImages = computed(() => {
  if (!raffle.value) return [];
  if (raffle.value.images.length) return raffle.value.images;

  const storeImage = raffle.value.prize?.storeImage;
  return storeImage?.url ? [storeImage] : [];
});

const STATUS_PILLS: Record<RaffleStatusEnum, `${PillVariantsEnum}`> = {
  [RaffleStatusEnum.DRAFT]: PillVariantsEnum.NEUTRAL,
  [RaffleStatusEnum.UPCOMING]: PillVariantsEnum.DEFAULT,
  [RaffleStatusEnum.OPEN]: PillVariantsEnum.SUCCESS,
  [RaffleStatusEnum.CLOSED]: PillVariantsEnum.NEUTRAL,
  [RaffleStatusEnum.DRAWN]: PillVariantsEnum.NEUTRAL,
  [RaffleStatusEnum.CONCLUDED]: PillVariantsEnum.NEUTRAL,
};
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="raffle">
        <Heading hero>{{ raffle.title }}</Heading>
        <div class="raffle-meta">
          <Pill :variant="STATUS_PILLS[raffle.status]">
            {{ t(`raffles.statuses.${raffle.status}`) }}
          </Pill>
          <span class="raffle-meta__text">
            {{
              t("raffles.meta", {
                date: l(raffle.endsAt, "datetime.formats.short"),
                count: raffle.entriesCount,
              })
            }}
          </span>
        </div>

        <RaffleKeyImage
          v-if="keyImages.length"
          :images="keyImages"
          :title="raffle.title"
        />

        <div class="row">
          <div class="col-12 col-md-8">
            <Panel
              v-if="raffle.description || raffle.prize"
              :variant="PanelVariantsEnum.SLIM"
            >
              <PanelBody>
                <p v-if="raffle.description" class="raffle-description">
                  {{ raffle.description }}
                </p>
                <p v-if="raffle.prize" class="raffle-prize">
                  {{ t("raffles.prizeShip") }}
                  <router-link
                    :to="{ name: 'ship', params: { slug: raffle.prize.slug } }"
                  >
                    {{ raffle.prize.name }}
                  </router-link>
                </p>
              </PanelBody>
            </Panel>
            <RaffleHowItWorks :raffle="raffle" />
            <RaffleConditions :raffle="raffle" />
          </div>
          <div class="col-12 col-md-4">
            <RaffleEntryPanel
              v-if="raffle.status !== RaffleStatusEnum.DRAFT"
              :raffle="raffle"
              @changed="refresh"
            />
            <RaffleWinners :raffle="raffle" />
            <RaffleEntrants
              :raffle-id="raffle.id"
              :count="raffle.entriesCount"
            />
          </div>
        </div>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.raffle-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  margin-bottom: 20px;
}

.raffle-meta__text {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}

.raffle-description {
  margin-top: 0;
  white-space: pre-line;
}

.raffle-prize {
  margin-bottom: 0;
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
