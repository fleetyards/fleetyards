<script lang="ts">
export default {
  name: "FleetDashboard",
};
</script>

<script lang="ts" setup>
import ActivityPanel from "@/frontend/components/Fleets/Dashboard/ActivityPanel/index.vue";
import UpcomingEventsPanel from "@/frontend/components/Fleets/Dashboard/UpcomingEventsPanel/index.vue";
import WeekCalendarPanel from "@/frontend/components/Fleets/Dashboard/WeekCalendarPanel/index.vue";
import ActionQueuePanel from "@/frontend/components/Fleets/Dashboard/ActionQueuePanel/index.vue";
import ContractsPanel from "@/frontend/components/Fleets/Dashboard/ContractsPanel/index.vue";
import InventoryPanel from "@/frontend/components/Fleets/Dashboard/InventoryPanel/index.vue";
import NewMembersPanel from "@/frontend/components/Fleets/Dashboard/NewMembersPanel/index.vue";
import AboutPanel from "@/frontend/components/Fleets/Dashboard/AboutPanel/index.vue";
import GetStartedPanel from "@/frontend/components/Fleets/Dashboard/GetStartedPanel/index.vue";
import { useFleetDashboardAccess } from "@/frontend/composables/useFleetDashboardAccess";
import {
  FleetActivityCategoryEnum,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const {
  showEvents,
  showContracts,
  showInventory,
  showNewMembers,
  showActionQueue,
  canAnswerJoinRequests,
  canAnswerTransfers,
  canCreateEvents,
  canCreateContracts,
  canReadMissions,
} = useFleetDashboardAccess(
  () => props.fleet,
  () => props.membership,
);

// Modules the reader may see that have nothing on right now. They are folded
// into one prompt to start something, rather than a box each saying so.
const empty = reactive({ events: false, contracts: false });

// What a panel of its own already tells is left out of the feed, so nothing on
// the page is said twice.
const excludedFromFeed = computed(() => [
  ...(showNewMembers.value ? [FleetActivityCategoryEnum.MEMBERS] : []),
  ...(showInventory.value ? [FleetActivityCategoryEnum.INVENTORY] : []),
]);
</script>

<template>
  <div class="fleet-dashboard" data-test="fleet-dashboard">
    <div class="fleet-dashboard__main">
      <GetStartedPanel
        :fleet="fleet"
        :events="showEvents && empty.events"
        :contracts="showContracts && empty.contracts"
        :can-create-events="canCreateEvents"
        :can-create-contracts="canCreateContracts"
        :can-read-missions="canReadMissions"
        class="fleet-dashboard__get-started"
      />
      <UpcomingEventsPanel
        v-if="showEvents"
        :fleet="fleet"
        class="fleet-dashboard__events"
        @empty="empty.events = $event"
      />
      <!-- Always there for a reader of events: an empty week is still the
           week, and where they go to look ahead. -->
      <WeekCalendarPanel
        v-if="showEvents"
        :fleet="fleet"
        class="fleet-dashboard__calendar"
      />
      <ActivityPanel
        :fleet="fleet"
        :exclude="excludedFromFeed"
        class="fleet-dashboard__activity"
      />
      <!-- The fleet's own words read best at the width they were written
           for, and they keep a quiet fleet's main column from standing empty
           beside a long side one. -->
      <AboutPanel
        :fleet="fleet"
        :membership="membership"
        class="fleet-dashboard__about"
      />
    </div>
    <aside class="fleet-dashboard__side">
      <ActionQueuePanel
        v-if="showActionQueue"
        :fleet="fleet"
        :can-answer-join-requests="canAnswerJoinRequests"
        :can-answer-transfers="canAnswerTransfers"
        class="fleet-dashboard__queue"
      />
      <ContractsPanel
        v-if="showContracts"
        :fleet="fleet"
        class="fleet-dashboard__contracts"
        @empty="empty.contracts = $event"
      />
      <InventoryPanel
        v-if="showInventory"
        :fleet="fleet"
        class="fleet-dashboard__inventory"
      />
      <NewMembersPanel
        v-if="showNewMembers"
        :fleet="fleet"
        class="fleet-dashboard__members"
      />
    </aside>
  </div>
</template>

<style lang="scss" scoped>
// Two columns from the tablet breakpoint: what is coming and what happened on
// the left, what wants the reader beside it. On a phone the columns dissolve
// into one list ordered by urgency, so an officer's queue is not below the
// whole feed.
.fleet-dashboard {
  display: flex;
  flex-direction: column;
  margin-top: 16px;
}

.fleet-dashboard__main,
.fleet-dashboard__side {
  display: contents;
}

.fleet-dashboard__queue {
  order: 1;
}

.fleet-dashboard__get-started,
.fleet-dashboard__events {
  order: 2;
}

.fleet-dashboard__calendar {
  order: 3;
}

.fleet-dashboard__contracts {
  order: 4;
}

.fleet-dashboard__inventory {
  order: 5;
}

.fleet-dashboard__activity {
  order: 6;
}

.fleet-dashboard__members {
  order: 7;
}

.fleet-dashboard__about {
  order: 8;
}

@media (min-width: 992px) {
  .fleet-dashboard {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
    gap: 0 24px;
    align-items: start;
  }

  .fleet-dashboard__main,
  .fleet-dashboard__side {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }
}
</style>
