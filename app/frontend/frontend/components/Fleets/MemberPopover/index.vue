<script lang="ts">
export default {
  name: "FleetMemberPopover",
};
</script>

<script lang="ts" setup>
import BasePopover from "@/shared/components/Popover/index.vue";
import FleetMemberStatsCard from "@/frontend/components/StatsCard/FleetMember/index.vue";
import { useFleetMember } from "@/services/fyApi";

type Props = {
  fleetSlug: string;
  username: string;
  fleetSid?: string;
};

const props = withDefaults(defineProps<Props>(), {
  fleetSid: undefined,
});

// Asked for on the first open, not with the list: a list of members holds
// what its check is about, the card everything else.
const requested = ref(false);

const {
  data: member,
  isPending,
  isLoadingError,
} = useFleetMember(
  () => props.fleetSlug,
  () => props.username,
  { query: { enabled: requested } },
);

const loading = computed(
  () => requested.value && isPending.value && !isLoadingError.value,
);

const to = computed(() => ({
  name: "fleet-members-index",
  params: { slug: props.fleetSlug },
  query: { searchCont: props.username },
}));
</script>

<template>
  <BasePopover :label="username" :focusable="false" @open="requested = true">
    <slot />

    <template #content="{ close }">
      <FleetMemberStatsCard
        :member="member"
        :name="username"
        :fleet-sid="fleetSid"
        :to="to"
        :loading="loading"
        @navigate="close"
      />
    </template>
  </BasePopover>
</template>
