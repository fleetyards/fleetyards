<script lang="ts">
export default {
  name: "HomeDashboardComingUpPanel",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import EventCard from "@/frontend/components/Fleets/Dashboard/EventCard/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  FleetEventSignupStatusEnum,
  getMyEventsQueryKey,
  type FleetEvent,
  type MyEvent,
  useMyEvents,
  useSignupFleetEvent,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

// How many entries a dashboard shows before "Calendar" takes over.
const SHOWN = 6;

const { data, isLoading, isFetching, isLoadingError } = useMyEvents(undefined, {
  query: liveQuery,
});

const entries = computed(() =>
  (data.value?.items || [])
    .filter((entry) => {
      const status = entry.fleetEvent?.status;
      return status !== "cancelled" && status !== "completed";
    })
    .slice(0, SHOWN),
);

const startOfDay = (date: Date) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();

type Group = { key: "today" | "week" | "later"; entries: MyEvent[] };

// Grouped by how soon, which is how an agenda is read: what is on tonight,
// what this week holds, and what is further out.
const groups = computed<Group[]>(() => {
  const today = startOfDay(new Date());
  const inAWeek = today + 7 * 24 * 60 * 60 * 1000;

  const result: Group[] = [
    { key: "today", entries: [] },
    { key: "week", entries: [] },
    { key: "later", entries: [] },
  ];

  entries.value.forEach((entry) => {
    const day = startOfDay(new Date(entry.startsAt));
    if (day <= today) result[0].entries.push(entry);
    else if (day < inAWeek) result[1].entries.push(entry);
    else result[2].entries.push(entry);
  });

  return result.filter((group) => group.entries.length);
});

// The three answers a member can give from the dashboard without opening the
// event; picking a ship or a slot still happens on the event page.
const answers = [
  { status: FleetEventSignupStatusEnum.CONFIRMED, icon: "fa-light fa-check" },
  {
    status: FleetEventSignupStatusEnum.TENTATIVE,
    icon: "fa-light fa-circle-question",
  },
  { status: FleetEventSignupStatusEnum.INTERESTED, icon: "fa-light fa-eye" },
];

const canAnswer = (event?: FleetEvent) =>
  !!event && event.signupsOpen && !event.viewerSignup;

const signupMutation = useSignupFleetEvent();
const busy = ref<string | undefined>();

const entryKey = (entry: MyEvent) =>
  entry.fleetEvent
    ? `${entry.fleetEvent.id}-${entry.fleetEvent.occurrenceDate || ""}`
    : entry.gameEvent?.id || entry.startsAt;

const answer = async (entry: MyEvent, status: FleetEventSignupStatusEnum) => {
  if (!entry.fleet || !entry.fleetEvent) return;

  busy.value = entryKey(entry);

  try {
    await signupMutation.mutateAsync({
      fleetSlug: entry.fleet.slug,
      slug: entry.fleetEvent.parentEventSlug || entry.fleetEvent.slug,
      data: {
        status,
        occurrenceDate: entry.fleetEvent.occurrenceDate || null,
      },
    });
    await queryClient.invalidateQueries({ queryKey: getMyEventsQueryKey() });
  } catch {
    displayAlert({ text: t("home.dashboard.comingUp.signupFailed") });
  } finally {
    busy.value = undefined;
  }
};
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.comingUp.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!entries.length"
    :more="{ name: 'settings-calendar' }"
    :more-label="t('home.dashboard.comingUp.calendar')"
    data-test="home-coming-up"
  >
    <div class="home-coming-up">
      <template v-for="group in groups" :key="group.key">
        <div class="home-coming-up__group">
          {{ t(`home.dashboard.comingUp.groups.${group.key}`) }}
        </div>
        <div
          v-for="entry in group.entries"
          :key="entryKey(entry)"
          class="home-coming-up__entry"
        >
          <EventCard
            v-if="entry.fleetEvent && entry.fleet"
            :fleet="entry.fleet"
            :event="entry.fleetEvent"
          />
          <EventCard v-else-if="entry.gameEvent" :event="entry.gameEvent">
            <template #badge>
              <span class="home-coming-up__in-game">
                {{ t("home.dashboard.comingUp.inGame") }}
              </span>
            </template>
          </EventCard>
          <div v-if="entry.fleet" class="home-coming-up__meta">
            <span>{{ entry.fleet.name }}</span>
            <BtnGroup
              v-if="canAnswer(entry.fleetEvent)"
              :aria-label="t('home.dashboard.comingUp.answer')"
            >
              <Btn
                v-for="option in answers"
                :key="option.status"
                :size="BtnSizesEnum.SM"
                :disabled="busy === entryKey(entry)"
                mobile-icon-only
                @click="answer(entry, option.status)"
              >
                <i :class="option.icon" />
                {{ t(`labels.fleets.events.signupStatuses.${option.status}`) }}
              </Btn>
            </BtnGroup>
          </div>
        </div>
      </template>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-calendar"
        :title="t('home.dashboard.comingUp.empty.title')"
        :hint="t('home.dashboard.comingUp.empty.hint')"
      >
        <router-link :to="{ name: 'fleets' }">
          {{ t("home.dashboard.comingUp.empty.action") }}
        </router-link>
      </DashboardEmpty>
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-coming-up {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-coming-up__group {
  margin: 6px 2px 0;
  color: var(--color-text-dim, #959595);
  font-family: "Orbitron", sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;

  &:first-child {
    margin-top: 0;
  }
}

.home-coming-up__entry {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.home-coming-up__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 0 2px;
  color: var(--color-text-dim, #959595);
  font-size: 12px;
}

.home-coming-up__in-game {
  flex: 0 0 auto;
  font-size: 12px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  white-space: nowrap;
}
</style>
