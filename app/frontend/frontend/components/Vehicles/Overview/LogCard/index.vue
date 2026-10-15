<script lang="ts">
export default {
  name: "VehicleOverviewLogCard",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type Vehicle,
  type VehicleLogEntry,
  useVehicleLogEntries,
} from "@/services/fyApi";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";

type Props = {
  vehicle: Vehicle;
  // Entries written before a ship moved to the wishlist stay readable, but no
  // new ones are started there.
  readonly?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  readonly: false,
});

const PREVIEW_COUNT = 3;

const { t, l } = useI18n();
const comlink = useComlink();

const { data: logEntries, isLoading } = useVehicleLogEntries(
  () => props.vehicle.id,
);

const entries = computed<VehicleLogEntry[]>(() => logEntries.value || []);

const preview = computed(() => entries.value.slice(0, PREVIEW_COUNT));

const publicCount = computed(
  () => entries.value.filter((entry) => entry.public).length,
);

// The preview is a teaser for the log tab, so the body loses its formatting
// rather than rendering a markdown block per line.
const excerpt = (body?: string | null) =>
  (body || "")
    .replace(/!\[[^\]]*\]\([^)]*\)/g, "")
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/[#>*_`~-]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const openEntryModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/LogEntryModal/index.vue"),
    props: { vehicle: props.vehicle },
  });
};

const toVehicle = useVehicleRoute();

const logRoute = computed(() => toVehicle("hangar-vehicle-log", props.vehicle));
</script>

<template>
  <MetricsCard
    v-if="!readonly || entries.length"
    :title="t('nav.hangar.vehicleLog')"
    :loading="isLoading"
    variant="slim"
    data-test="vehicle-overview-log"
  >
    <template v-if="!readonly" #head>
      <Btn
        :size="BtnSizesEnum.SM"
        data-test="vehicle-overview-log-add"
        @click="openEntryModal"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.vehicleLog.add") }}
      </Btn>
    </template>

    <p v-if="!isLoading && !entries.length" class="overview-log__summary">
      {{ t("texts.vehicleLog.empty") }}
    </p>

    <p v-else-if="entries.length" class="overview-log__summary">
      {{
        t("labels.vehicleOverview.logSummary", {
          count: entries.length,
          public: publicCount,
        })
      }}
    </p>

    <ol v-if="entries.length" class="overview-log__entries">
      <li
        v-for="entry in preview"
        :key="entry.id"
        class="overview-log__entry"
        data-test="vehicle-overview-log-entry"
      >
        <time :datetime="entry.loggedAt" class="overview-log__date">
          {{ l(entry.loggedAt, "datetime.formats.date") }}
        </time>
        <div class="overview-log__content">
          <h3 class="overview-log__title">
            {{ entry.title }}
            <span v-if="entry.public" class="overview-log__public">
              {{ t("labels.vehicleLog.publicShort") }}
            </span>
          </h3>
          <p v-if="entry.body" class="overview-log__excerpt">
            {{ excerpt(entry.body) }}
          </p>
        </div>
      </li>
    </ol>

    <template v-if="entries.length" #footer>
      <router-link :to="logRoute" class="overview-card-footer-link">
        {{ t("actions.vehicleOverview.openLog") }}
      </router-link>
    </template>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "../card.scss";

.overview-log {
  &__summary {
    margin: 0 0 8px;
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__entries {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__entry {
    display: grid;
    grid-template-columns: 96px minmax(0, 1fr);
    gap: 16px;
    padding: 12px 0;
    border-top: 1px solid var(--color-edge-faint);

    @media (max-width: $desktop-breakpoint) {
      grid-template-columns: minmax(0, 1fr);
      gap: 2px;
    }
  }

  &__date {
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__title {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
    margin: 0;
    font-size: 1rem;
    color: #fff;
    overflow-wrap: anywhere;
  }

  &__public {
    padding: 0 6px;
    border: 1px solid rgb(66 139 202 / 0.6);
    border-radius: 4px;
    color: #9cc5ea;
    font-size: 0.65rem;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  &__excerpt {
    display: -webkit-box;
    margin: 4px 0 0;
    overflow: hidden;
    color: var(--color-text-dim);
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
}
</style>
