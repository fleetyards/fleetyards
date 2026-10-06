<script lang="ts">
export default {
  name: "FleetSquadronMembersViewSwitch",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  SQUADRON_MEMBERS_VIEWS,
  type SquadronMembersView,
} from "@/frontend/components/Fleets/Squadrons/SquadronMembersViewSwitch/types";

type Props = {
  fleetSlug: string;
  squadronSlug: string;
  view: SquadronMembersView;
  pendingRequestCount?: number;
};

const props = withDefaults(defineProps<Props>(), {
  pendingRequestCount: undefined,
});

const { t } = useI18n();

const link = (value: SquadronMembersView) => ({
  name: "fleet-squadron-members",
  params: { slug: props.fleetSlug, squadron: props.squadronSlug },
  query: value === "requests" ? { view: "requests" } : {},
});

const label = (value: SquadronMembersView) => {
  const text = t(`labels.fleet.squadrons.views.${value}`);

  return value === "requests" && props.pendingRequestCount
    ? `${text} (${props.pendingRequestCount})`
    : text;
};
</script>

<template>
  <BtnGroup segmented>
    <Btn
      v-for="value in SQUADRON_MEMBERS_VIEWS"
      :key="value"
      :to="link(value)"
      :active="props.view === value"
      :data-test="`squadron-members-view-${value}`"
      mobile-icon-only
    >
      <i
        class="fa-duotone"
        :class="value === 'members' ? 'fa-users' : 'fa-hand'"
      />
      {{ label(value) }}
    </Btn>
  </BtnGroup>
</template>
