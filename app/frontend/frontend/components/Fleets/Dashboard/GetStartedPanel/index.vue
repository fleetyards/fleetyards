<script lang="ts">
export default {
  name: "FleetDashboardGetStartedPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/frontend/components/Fleets/Dashboard/DashboardPanel/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useEventDraft } from "@/frontend/composables/useDraftCreate";
import { useComlink } from "@/shared/composables/useComlink";
import type { Fleet, Mission } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Which modules have nothing on right now. Each is a prompt to start one
  // rather than a box of its own saying it is empty.
  events?: boolean;
  contracts?: boolean;
  canCreateEvents?: boolean;
  canCreateContracts?: boolean;
  // Whoever can read the fleet's missions is asked for one to start from.
  canReadMissions?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  events: false,
  contracts: false,
  canCreateEvents: false,
  canCreateContracts: false,
  canReadMissions: false,
});

const { t } = useI18n();

const router = useRouter();

const { create: createEventDraft, pending: creatingEvent } = useEventDraft();

const comlink = useComlink();

// The same start the events page makes: a mission template first, because the
// API copies a mission's teams only while it writes the event.
const planEvent = () => {
  if (creatingEvent.value) return;

  if (!props.canReadMissions) {
    void createEventDraft(props.fleet.slug);
    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Events/MissionTemplatePicker/index.vue"),
    props: {
      fleet: props.fleet,
      onPick: (mission: Mission | null) => {
        void createEventDraft(props.fleet.slug, { missionSlug: mission?.slug });
      },
    },
  });
};

const postContract = () =>
  void router.push({
    name: "fleet-contract-new",
    params: { slug: props.fleet.slug },
  });
</script>

<template>
  <DashboardPanel
    v-if="events || contracts"
    :title="t('fleetDashboard.getStarted.title')"
    data-test="fleet-dashboard-get-started"
  >
    <ul class="get-started">
      <li v-if="events" class="get-started__entry">
        <i
          class="fa-light fa-calendar-star get-started__icon"
          aria-hidden="true"
        />
        <div class="get-started__text">
          <span class="get-started__title">
            {{ t("fleetDashboard.getStarted.events.title") }}
          </span>
          <span class="get-started__hint">
            {{
              canCreateEvents
                ? t("fleetDashboard.getStarted.events.hintCreate")
                : t("fleetDashboard.getStarted.events.hint")
            }}
          </span>
        </div>
        <Btn
          v-if="canCreateEvents"
          :size="BtnSizesEnum.SM"
          :loading="creatingEvent"
          data-test="fleet-dashboard-plan-event"
          @click="planEvent"
        >
          <i class="fa-light fa-plus" />
          {{ t("fleetDashboard.getStarted.events.action") }}
        </Btn>
        <router-link
          v-else
          :to="{ name: 'fleet-events', params: { slug: fleet.slug } }"
          class="get-started__link"
        >
          {{ t("fleetDashboard.getStarted.events.link") }}
          <i class="fa-light fa-chevron-right" aria-hidden="true" />
        </router-link>
      </li>
      <li v-if="contracts" class="get-started__entry">
        <i
          class="fa-light fa-file-contract get-started__icon"
          aria-hidden="true"
        />
        <div class="get-started__text">
          <span class="get-started__title">
            {{ t("fleetDashboard.getStarted.contracts.title") }}
          </span>
          <span class="get-started__hint">
            {{
              canCreateContracts
                ? t("fleetDashboard.getStarted.contracts.hintCreate")
                : t("fleetDashboard.getStarted.contracts.hint")
            }}
          </span>
        </div>
        <Btn
          v-if="canCreateContracts"
          :size="BtnSizesEnum.SM"
          data-test="fleet-dashboard-post-contract"
          @click="postContract"
        >
          <i class="fa-light fa-plus" />
          {{ t("fleetDashboard.getStarted.contracts.action") }}
        </Btn>
        <router-link
          v-else
          :to="{ name: 'fleet-contracts', params: { slug: fleet.slug } }"
          class="get-started__link"
        >
          {{ t("fleetDashboard.getStarted.contracts.link") }}
          <i class="fa-light fa-chevron-right" aria-hidden="true" />
        </router-link>
      </li>
    </ul>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.get-started {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.get-started__entry {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
}

.get-started__icon {
  flex: 0 0 24px;
  color: var(--color-muted, #7a8288);
  font-size: 20px;
  text-align: center;
}

.get-started__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.get-started__title {
  color: var(--color-lifted, #eee);
  font-weight: 600;
}

.get-started__hint {
  color: var(--color-text-dim, #959595);
  font-size: 13px;
}

.get-started__link {
  flex: 0 0 auto;
  font-size: 13px;
  white-space: nowrap;
}
</style>
