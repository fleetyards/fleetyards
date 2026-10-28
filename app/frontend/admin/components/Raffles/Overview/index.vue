<script lang="ts">
export default {
  name: "RaffleOverview",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import { PanelVariantsEnum } from "@/shared/components/base/Panel/types";
import { PanelHeadingTonesEnum } from "@/shared/components/base/Panel/Heading/types";
import { type Raffle } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  raffle: Raffle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();

const date = (value?: string) =>
  value ? l(value, "datetime.formats.short") : "—";

const rows = computed(() => [
  { key: "prize", value: props.raffle.prize || "—" },
  {
    key: "code",
    value: props.raffle.codeSet
      ? props.raffle.maskedCode || "•••"
      : t("labels.raffle.overview.noCode"),
  },
  { key: "startsAt", value: date(props.raffle.startsAt) },
  { key: "endsAt", value: date(props.raffle.endsAt) },
  {
    key: "runDays",
    value: t("labels.raffle.overview.days", { days: props.raffle.runDays }),
  },
  {
    key: "claimPeriodDays",
    value: t("labels.raffle.overview.days", {
      days: props.raffle.claimPeriodDays,
    }),
  },
  { key: "startAnnouncedAt", value: date(props.raffle.startAnnouncedAt) },
  { key: "lastDayAnnouncedAt", value: date(props.raffle.lastDayAnnouncedAt) },
  {
    key: "drawnAt",
    value: props.raffle.drawnAt
      ? t("labels.raffle.overview.drawnBy", {
          date: date(props.raffle.drawnAt),
          admin: props.raffle.drawnBy || "—",
        })
      : "—",
  },
  { key: "concludedAt", value: date(props.raffle.concludedAt) },
]);

const publicUrl = computed(
  () => `${window.FRONTEND_ENDPOINT}/raffles/${props.raffle.id}/`,
);
</script>

<template>
  <div class="row">
    <div class="col-12 col-md-6">
      <Panel :variant="PanelVariantsEnum.SLIM" data-test="raffle-overview">
        <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
          {{ t("labels.raffle.overview.title") }}
        </PanelHeading>
        <PanelBody>
          <div class="metrics-card__rows">
            <div v-for="row in rows" :key="row.key" class="metrics-card__row">
              <div class="metrics-card__row__label">
                {{ t(`labels.raffle.overview.${row.key}`) }}
              </div>
              <div class="metrics-card__row__value">{{ row.value }}</div>
            </div>
          </div>
          <a
            :href="publicUrl"
            target="_blank"
            rel="noopener"
            class="raffle-overview__public"
          >
            {{ t("labels.raffle.overview.publicPage") }}
            <i class="fa-light fa-arrow-up-right-from-square" />
          </a>
        </PanelBody>
      </Panel>
    </div>
    <div class="col-12 col-md-6">
      <Panel v-if="props.raffle.description" :variant="PanelVariantsEnum.SLIM">
        <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
          {{ t("labels.raffle.description") }}
        </PanelHeading>
        <PanelBody>
          <p class="raffle-overview__description">
            {{ props.raffle.description }}
          </p>
        </PanelBody>
      </Panel>
      <Panel :variant="PanelVariantsEnum.SLIM">
        <PanelHeading :tone="PanelHeadingTonesEnum.METRIC" compact divider>
          {{ t("labels.raffle.images") }} · {{ props.raffle.images.length }}
        </PanelHeading>
        <PanelBody>
          <p v-if="!props.raffle.images.length" class="raffle-overview__dim">
            {{ t("labels.raffle.overview.noImages") }}
          </p>
          <div v-else class="raffle-overview__images">
            <img
              v-for="(image, index) in props.raffle.images"
              :key="image.signedId || index"
              :src="image.smallUrl || image.url"
              :alt="image.name"
            />
          </div>
        </PanelBody>
      </Panel>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.raffle-overview__public {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  margin-top: 12px;
  font-size: 0.875rem;
}

.raffle-overview__description {
  margin: 0;
  white-space: pre-line;
}

.raffle-overview__dim {
  margin: 0;
  color: var(--color-text-dim, #959595);
}

.raffle-overview__images {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;

  img {
    display: block;
    width: 100%;
    aspect-ratio: 16 / 9;
    object-fit: cover;
    border-radius: var(--radius-control, 8px);
  }
}
</style>
