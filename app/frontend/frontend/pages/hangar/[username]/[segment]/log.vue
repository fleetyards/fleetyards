<script lang="ts">
export default {
  name: "HangarVehicleLogPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import VehicleTabLayout from "@/frontend/components/Vehicles/TabLayout/index.vue";
import Markdown from "@/shared/components/Markdown/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import ListSkeleton from "@/shared/components/ListSkeleton/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useQueryClient } from "@tanstack/vue-query";
import {
  type Vehicle,
  type VehicleLogEntry,
  useVehicleLogEntries,
  useDestroyVehicleLogEntry,
  useUpdateVehicle,
  getVehicleLogEntriesQueryKey,
} from "@/services/fyApi";
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();
const { displayConfirm, displayAlert } = useAppNotifications();
const { invalidateVehiclePage } = useVehicleMutations();

const vehicleId = computed(() => props.vehicle.id);

const { data: logEntries, isLoading } = useVehicleLogEntries(vehicleId);

const entries = computed<VehicleLogEntry[]>(() => logEntries.value || []);

const openEntryModal = (logEntry?: VehicleLogEntry) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/LogEntryModal/index.vue"),
    props: {
      // The switch below saves on its own, so the page's vehicle can still
      // carry the old default when a new entry is started.
      vehicle: {
        ...props.vehicle,
        logEntriesPublicByDefault: publicByDefault.value,
      },
      logEntry,
    },
  });
};

const destroyMutation = useDestroyVehicleLogEntry({
  mutation: {
    onSettled: () =>
      queryClient.invalidateQueries({
        queryKey: getVehicleLogEntriesQueryKey(props.vehicle.id),
      }),
  },
});

const destroy = (logEntry: VehicleLogEntry) => {
  displayConfirm({
    tone: AppConfirmTonesEnum.DANGER,
    text: t("messages.confirm.vehicleLog.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({ vehicleId: props.vehicle.id, id: logEntry.id })
        .catch(() => {
          displayAlert({ text: t("messages.vehicleLog.destroy.failure") });
        });
    },
  });
};

// A wishlist ship keeps the entries written before it moved there, readable
// and removable, but takes no new ones and no edits.
const readonly = computed(() => props.vehicle.wanted);

// The public hangar lists only bought ships, so a wishlist ship's entries are
// never shown there, public or not.
const publiclyListed = computed(
  () => props.vehicle.public && !props.vehicle.wanted,
);

// Only new entries follow it; the ones already written keep their own switch.
const publicByDefault = ref(props.vehicle.logEntriesPublicByDefault);

watch(
  () => props.vehicle.logEntriesPublicByDefault,
  (value) => {
    publicByDefault.value = value;
  },
);

const updateVehicle = useUpdateVehicle();

const updatePublicByDefault = async (value: boolean) => {
  publicByDefault.value = value;

  await updateVehicle
    .mutateAsync({
      id: props.vehicle.id,
      data: { logEntriesPublicByDefault: value },
    })
    .then((updatedVehicle) => invalidateVehiclePage(updatedVehicle))
    .catch(() => {
      publicByDefault.value = !value;
      displayAlert({ text: t("messages.vehicleLog.defaultUpdate.failure") });
    });
};

type Visibility = "all" | "public" | "private";

const visibility = ref<Visibility>("all");

const publicCount = computed(
  () => entries.value.filter((entry) => entry.public).length,
);

const filters = computed(() => [
  { key: "all" as const, count: entries.value.length },
  { key: "public" as const, count: publicCount.value },
  { key: "private" as const, count: entries.value.length - publicCount.value },
]);

const visibleEntries = computed(() =>
  entries.value.filter(
    (entry) =>
      visibility.value === "all" ||
      entry.public === (visibility.value === "public"),
  ),
);

// The log reads as a story, so it is told in years: newest first, as the API
// returns it, each year under a rule of its own.
const years = computed(() => {
  const groups: { year: string; entries: VehicleLogEntry[] }[] = [];

  visibleEntries.value.forEach((entry) => {
    const year = l(entry.loggedAt, "datetime.formats.year");
    const group = groups[groups.length - 1];

    if (group?.year === year) {
      group.entries.push(entry);
    } else {
      groups.push({ year, entries: [entry] });
    }
  });

  return groups;
});

const since = computed(() => {
  const oldest = entries.value[entries.value.length - 1];

  return oldest ? l(oldest.loggedAt, "datetime.formats.year") : undefined;
});
</script>

<template>
  <VehicleTabLayout class="vehicle-log">
    <BtnGroup
      v-if="entries.length"
      segmented
      class="vehicle-log__filters"
      data-test="vehicle-log-filters"
    >
      <Btn
        v-for="filter in filters"
        :key="filter.key"
        :active="visibility === filter.key"
        :aria-pressed="visibility === filter.key"
        :data-test="`vehicle-log-filter-${filter.key}`"
        @click="visibility = filter.key"
      >
        {{ t(`labels.vehicleLog.filters.${filter.key}`) }}
        <span class="vehicle-log__filter-count">{{ filter.count }}</span>
      </Btn>
    </BtnGroup>

    <ListSkeleton v-if="isLoading" />

    <Empty
      v-else-if="!entries.length"
      :variant="EmptyVariantsEnum.BOX"
      :name="t('labels.vehicleLog.entries')"
      hide-actions
    >
      <template #info>
        <p>{{ t("texts.vehicleLog.empty") }}</p>
      </template>
    </Empty>

    <p v-else-if="!visibleEntries.length" class="vehicle-log__none">
      {{ t("texts.vehicleLog.noneForFilter") }}
    </p>

    <section
      v-for="group in years"
      :key="group.year"
      class="vehicle-log__year"
      :aria-label="group.year"
    >
      <div class="vehicle-log__year-head">
        <h2 class="vehicle-log__year-title">{{ group.year }}</h2>
        <span class="vehicle-log__year-rule" />
        <span class="vehicle-log__year-count">
          {{
            t("labels.vehicleLog.entryCount", {
              count: group.entries.length,
            })
          }}
        </span>
      </div>

      <ol class="vehicle-log__entries">
        <li
          v-for="entry in group.entries"
          :key="entry.id"
          class="vehicle-log__entry"
          :class="{ 'vehicle-log__entry--public': entry.public }"
          data-test="vehicle-log-entry"
        >
          <time :datetime="entry.loggedAt" class="vehicle-log__date">
            <span class="vehicle-log__day">
              {{ l(entry.loggedAt, "datetime.formats.day") }}
            </span>
            <span class="vehicle-log__month">
              {{ l(entry.loggedAt, "datetime.formats.monthShort") }}
            </span>
            <span class="vehicle-log__time">
              {{ l(entry.loggedAt, "datetime.formats.time") }}
            </span>
          </time>

          <span class="vehicle-log__rail" aria-hidden="true">
            <span class="vehicle-log__dot" />
          </span>

          <article class="vehicle-log__card">
            <header class="vehicle-log__card-head">
              <h3 class="vehicle-log__title">{{ entry.title }}</h3>
              <span
                class="vehicle-log__badge"
                :data-test="
                  entry.public
                    ? 'vehicle-log-entry-public'
                    : 'vehicle-log-entry-private'
                "
              >
                {{
                  entry.public
                    ? t("labels.vehicleLog.publicShort")
                    : t("labels.vehicleLog.privateShort")
                }}
              </span>
              <span class="vehicle-log__actions">
                <Btn
                  v-if="!readonly"
                  :size="BtnSizesEnum.SM"
                  :variant="BtnVariantsEnum.BARE"
                  :aria-label="t('actions.edit')"
                  data-test="vehicle-log-entry-edit"
                  @click="openEntryModal(entry)"
                >
                  <i class="fa-light fa-pen" />
                </Btn>
                <Btn
                  :size="BtnSizesEnum.SM"
                  :variant="BtnVariantsEnum.BARE"
                  :tone="BtnTonesEnum.DANGER"
                  :aria-label="t('actions.remove')"
                  data-test="vehicle-log-entry-remove"
                  @click="destroy(entry)"
                >
                  <i class="fa-light fa-trash" />
                </Btn>
              </span>
            </header>
            <Markdown
              v-if="entry.body"
              :source="entry.body"
              class="vehicle-log__body"
            />
          </article>
        </li>
      </ol>
    </section>

    <template #side>
      <Btn
        v-if="!readonly"
        class="vehicle-log__add"
        data-test="vehicle-log-add"
        @click="openEntryModal()"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.vehicleLog.add") }}
      </Btn>

      <MetricsCard
        v-if="entries.length"
        :title="t('labels.vehicleLog.stats')"
        variant="slim"
      >
        <dl class="vehicle-log__stats">
          <div>
            <dt>{{ t("labels.vehicleLog.statsEntries") }}</dt>
            <dd>{{ entries.length }}</dd>
          </div>
          <div>
            <dt>{{ t("labels.vehicleLog.statsPublic") }}</dt>
            <dd>{{ publicCount }}</dd>
          </div>
          <div>
            <dt>{{ t("labels.vehicleLog.statsSince") }}</dt>
            <dd>{{ since }}</dd>
          </div>
        </dl>
      </MetricsCard>

      <MetricsCard
        v-if="!readonly"
        :title="t('labels.vehicleOverview.visibility')"
        variant="slim"
      >
        <FormToggle
          :model-value="publicByDefault"
          name="logEntriesPublicByDefault"
          :label="t('labels.vehicleLog.publicByDefault')"
          :disabled="updateVehicle.isPending.value"
          data-test="vehicle-log-public-default"
          @update:model-value="updatePublicByDefault"
        />
        <p class="vehicle-log__hint">
          {{
            publiclyListed
              ? t("texts.vehicleLog.visibility")
              : t("texts.vehicleLog.visibilityHidden")
          }}
        </p>
      </MetricsCard>
    </template>
  </VehicleTabLayout>
</template>

<style lang="scss" scoped>
.vehicle-log {
  &__filters {
    margin-bottom: 16px;
  }

  &__filter-count {
    margin-left: 6px;
    color: var(--color-text-dim);
  }

  &__none {
    color: var(--color-text-dim);
  }

  &__add {
    width: 100%;
  }

  &__stats {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
    margin: 0;

    dt {
      color: var(--color-text-dim);
      font-size: 0.7rem;
      font-weight: normal;
      letter-spacing: 0.1em;
      text-transform: uppercase;
    }

    dd {
      margin: 0;
      color: #fff;
      font-family: Orbitron, sans-serif;
      font-size: 1.15rem;
    }
  }

  &__hint {
    margin: 8px 0 0;
    color: var(--color-text-dim);
    font-size: 0.85rem;
  }

  &__year {
    margin-bottom: 8px;
  }

  &__year-head {
    display: flex;
    align-items: center;
    gap: 14px;
    margin: 8px 0 14px;
  }

  &__year-title {
    margin: 0;
    color: var(--color-text-dim);
    font-family: Orbitron, sans-serif;
    font-size: 0.95rem;
    font-weight: 500;
    letter-spacing: 0.12em;
  }

  &__year-rule {
    flex: 1;
    height: 1px;
    background: var(--color-edge-faint);
  }

  &__year-count {
    color: var(--color-muted);
    font-size: 0.75rem;
  }

  &__entries {
    margin: 0;
    padding: 0;
    list-style: none;
  }

  // Date, rail, card: the rail runs through every entry, so the log reads as
  // one line with stops on it.
  &__entry {
    display: grid;
    grid-template-columns: 72px 28px minmax(0, 1fr);
    column-gap: 12px;

    @media (max-width: $desktop-breakpoint) {
      grid-template-columns: 56px 20px minmax(0, 1fr);
      column-gap: 8px;
    }
  }

  &__date {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    padding-top: 16px;
    text-align: right;
  }

  &__day {
    color: #fff;
    font-family: Orbitron, sans-serif;
    font-size: 1.5rem;
    line-height: 1;
  }

  &__month {
    color: var(--color-text-dim);
    font-size: 0.7rem;
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  &__time {
    color: var(--color-muted);
    font-size: 0.7rem;
  }

  &__rail {
    position: relative;
    display: flex;
    justify-content: center;

    &::before {
      position: absolute;
      top: 0;
      bottom: 0;
      width: 1px;
      background: var(--color-edge-soft);
      content: "";
    }
  }

  // Hollow for an entry only the owner sees, filled for one the public hangar
  // shows: the difference reads down the rail without reading a badge.
  &__dot {
    position: relative;
    box-sizing: border-box;
    width: 11px;
    height: 11px;
    margin-top: 22px;
    border: 2px solid var(--color-muted);
    border-radius: 50%;
    background: var(--color-background);
    box-shadow: 0 0 0 3px var(--color-background);
  }

  &__entry--public &__dot {
    border-color: var(--color-primary);
    background: var(--color-primary);
  }

  &__card {
    margin: 6px 0 14px;
    padding: 14px 18px 16px;
    border: 1px solid var(--color-edge-soft);
    border-radius: 10px;
    background: var(--color-surface);
  }

  &__card-head {
    display: flex;
    align-items: flex-start;
    gap: 10px;
  }

  &__title {
    flex: 1;
    margin: 0;
    color: #fff;
    font-size: 1.05rem;
    overflow-wrap: anywhere;
  }

  &__badge {
    flex: none;
    margin-top: 3px;
    padding: 1px 7px;
    border: 1px solid var(--color-edge);
    border-radius: 4px;
    color: var(--color-text-dim);
    font-size: 0.65rem;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  &__entry--public &__badge {
    border-color: rgb(66 139 202 / 0.6);
    color: #9cc5ea;
  }

  &__actions {
    display: flex;
    flex: none;
    gap: 2px;
    opacity: 0.55;
    transition: opacity 0.15s ease;
  }

  &__entry:hover &__actions,
  &__entry:focus-within &__actions {
    opacity: 1;
  }

  &__body {
    margin-top: 8px;
  }
}
</style>
