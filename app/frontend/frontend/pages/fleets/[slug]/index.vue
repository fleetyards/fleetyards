<script lang="ts">
export default {
  name: "FleetShow",
};
</script>

<script lang="ts" setup>
import Markdown from "@/shared/components/Markdown/index.vue";
import FleetHeader from "@/frontend/components/Fleets/Header/index.vue";
import FleetDashboard from "@/frontend/components/Fleets/Dashboard/index.vue";
import SquadronStrip from "@/frontend/components/Fleets/SquadronStrip/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useTourAutostart } from "@/shared/composables/useTourAutostart";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import {
  FleetMembershipStatusEnum,
  usePublicFleetSquadrons,
  type Fleet,
  type FleetMember,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership?: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { isFleetSquadronsEnabled } = useFeatures();

/*
 * Two pages under one address. Somebody meeting the fleet gets its
 * introduction: what it is, where it sits, the squadrons it is made of. A
 * member already knows all that and opens the page to see what is going on,
 * so they get the dashboard, with the introduction kept in a panel of it.
 */
const isMember = computed(
  () => props.membership?.status === FleetMembershipStatusEnum.ACCEPTED,
);

const acceptedMembership = computed(() =>
  isMember.value ? props.membership : undefined,
);

const showPublicSquadrons = computed(
  () => isFleetSquadronsEnabled(props.fleet) && !isMember.value,
);

const { data: publicSquadrons } = usePublicFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { enabled: showPublicSquadrons, retry: false } },
);

const publicSquadronList = computed(() =>
  showPublicSquadrons.value ? (publicSquadrons.value?.items ?? []) : [],
);

// The FID notice and the tour button are for whoever runs the fleet: verifying
// and setting it up are theirs to do, and the settings pages check the same.
const canManage = computed(
  () =>
    isMember.value && (props.membership?.capabilities?.manageFleet ?? false),
);

const fleetStore = useFleetStore();

const sessionStore = useSessionStore();

const userId = computed(() => sessionStore.currentUser?.id);

const openTour = () => fleetStore.openTour(props.fleet);

useTourAutostart({
  ready: () =>
    !!userId.value &&
    canManage.value &&
    fleetStore.isTourPending(userId.value, props.fleet.id),
  start: openTour,
});
</script>

<template>
  <FleetHeader :fleet="fleet" :can-manage="canManage" :compact="isMember" />
  <FleetDashboard
    v-if="acceptedMembership"
    :fleet="fleet"
    :membership="acceptedMembership"
  />
  <template v-else>
    <div v-if="fleet.description" class="row md:justify-center">
      <div class="col-12 col-md-8">
        <!-- Markdown renders a fragment, so it never carries this page's scope id. -->
        <div class="description">
          <Markdown :source="fleet.description" />
        </div>
      </div>
    </div>
    <!-- Not links: a squadron's own page is for members, and the public list
         carries no team flag, so squadrons and teams share one row here. -->
    <div v-if="publicSquadronList.length" class="row md:justify-center">
      <div class="col-12 col-md-8">
        <SquadronStrip
          :fleet="fleet"
          :squadrons="publicSquadronList"
          class="squadrons"
          centred
        />
      </div>
    </div>
  </template>

  <Teleport v-if="canManage" to="#header-right">
    <Btn
      v-tooltip="t('actions.showGuide')"
      :size="BtnSizesEnum.MD"
      :aria-label="t('actions.showGuide')"
      data-tour="fleet-guide"
      data-test="fleet-show-guide"
      @click="openTour"
    >
      <i class="fa-duotone fa-question" />
    </Btn>
  </Teleport>
</template>

<style lang="scss" scoped>
.description {
  margin-top: 15px;
  margin-bottom: 20px;
}

.squadrons {
  margin-bottom: 20px;
}
</style>
