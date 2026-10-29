<script lang="ts">
export default {
  name: "RafflePage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import { useDebounceFn } from "@vueuse/core";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import { AlertVariantsEnum } from "@/shared/components/base/Alert/types";
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
  useRafflePreview,
  getRaffleQueryKey,
  getRafflePreviewQueryKey,
  getCurrentRaffleQueryKey,
  getRaffleEntrantsQueryKey,
} from "@/services/fyApi";
import { RafflesChannel } from "@/services/fyCable/channels/RafflesChannel";
import { isRaffleOver } from "@/frontend/utils/raffleStatus";
import { useSubscription } from "@/shared/composables/useSubscription";
import { useI18n } from "@/shared/composables/useI18n";

const { t, l } = useI18n();
const route = useRoute();
const queryClient = useQueryClient();

// Without an id in the address this is the raffles page, which shows the one
// raffle that is current: there is only ever one online.
const routeId = computed(() => route.params.id as string | undefined);

// A preview link from the admin: shows a draft too, and works for readers
// the raffles feature is not enabled for.
const previewToken = computed(() => route.params.token as string | undefined);

const byId = useRaffle(() => routeId.value ?? "", {
  query: { enabled: () => !!routeId.value },
});
const current = useCurrentRaffle({
  query: { enabled: () => !routeId.value && !previewToken.value },
});
const preview = useRafflePreview(() => previewToken.value ?? "", {
  query: { enabled: () => !!previewToken.value },
});

const source = () => {
  if (previewToken.value) return preview;
  if (routeId.value) return byId;

  return current;
};

const { data: raffle, ...asyncStatus } = source();

const refresh = () =>
  Promise.all([
    queryClient.invalidateQueries({
      queryKey: getRaffleQueryKey(raffle.value?.id ?? ""),
    }),
    queryClient.invalidateQueries({ queryKey: getCurrentRaffleQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getRafflePreviewQueryKey(previewToken.value ?? ""),
    }),
    queryClient.invalidateQueries({
      queryKey: getRaffleEntrantsQueryKey(raffle.value?.id ?? ""),
    }),
  ]);

// Every entry sends a change, so a busy raffle would otherwise have each
// reader refetch once per entrant; maxWait keeps a steady stream from holding
// the page back for good.
const refreshSoon = useDebounceFn(() => void refresh(), 2_000, {
  maxWait: 10_000,
});

useSubscription({
  channel: RafflesChannel,
  received: (data) => {
    if (data.raffleId === raffle.value?.id) void refreshSoon();
  },
  // Nothing is replayed, so whatever changed while the socket was down is
  // caught up here.
  connected: (event) => {
    if (event?.reconnect) void refreshSoon();
  },
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
        <Alert
          v-if="previewToken"
          :title="t('raffles.preview.title')"
          :variant="AlertVariantsEnum.INFO"
          data-test="raffle-preview-notice"
        >
          {{ t("raffles.preview.text") }}
        </Alert>
        <Heading hero :size="HeadingSizeEnum.HERO">
          <span>
            <span aria-hidden="true">🎁</span>
            {{ raffle.title }}
            <span aria-hidden="true">🎉</span>
          </span>
        </Heading>
        <div class="raffle-meta">
          <Pill :variant="STATUS_PILLS[raffle.status]">
            {{ t(`raffles.statuses.${raffle.status}`) }}
          </Pill>
          <span class="raffle-meta__text">
            {{
              t(isRaffleOver(raffle) ? "raffles.metaClosed" : "raffles.meta", {
                date: l(raffle.endsAt, "datetime.formats.short"),
                count: raffle.entriesCount,
              })
            }}
          </span>
        </div>

        <div class="row">
          <div class="col-12 col-md-8">
            <RaffleKeyImage
              v-if="raffle.images.length"
              :images="raffle.images"
              :title="raffle.title"
            />
            <Panel v-if="raffle.description" :variant="PanelVariantsEnum.SLIM">
              <PanelBody>
                <p class="raffle-description">{{ raffle.description }}</p>
              </PanelBody>
            </Panel>
            <RaffleHowItWorks :raffle="raffle" />
            <RaffleConditions :raffle="raffle" />
          </div>
          <div class="col-12 col-md-4">
            <RaffleEntryPanel
              v-if="previewToken || raffle.status !== RaffleStatusEnum.DRAFT"
              :raffle="raffle"
              @changed="refresh"
            />
            <RaffleWinners :raffle="raffle" />
            <RaffleEntrants
              v-if="!previewToken"
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
  margin: 0;
  white-space: pre-line;
}
</style>
