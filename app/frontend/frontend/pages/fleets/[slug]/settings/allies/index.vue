<script lang="ts">
export default {
  name: "FleetSettingsAlliesPage",
};
</script>

<script lang="ts" setup>
import RelationshipView from "@/frontend/components/Relationships/RelationshipView/index.vue";
import { useRelationshipTab } from "@/frontend/composables/useRelationshipTab";
import { useFleetAlliances } from "@/frontend/composables/useFleetAlliances";
import { type Fleet, type FleetMember } from "@/services/fyApi";

// Handed down by `settings/allies.vue`, which gates the branch on the fleet's
// flag and on the reader's capability -- so this never renders for somebody who
// cannot see it.
type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { tab, tabs, state, direction } = useRelationshipTab({
  accepted: "fleet-settings-allies",
  incoming: "fleet-settings-allies-incoming",
  outgoing: "fleet-settings-allies-outgoing",
  ignored: "fleet-settings-allies-ignored",
});

const {
  rows,
  asyncStatus,
  busy,
  isLoading,
  onAdd,
  onAccept,
  onDecline,
  onIgnore,
  onRemove,
} = useFleetAlliances(() => props.fleet.slug, state, direction);

// An officer reads the list. Only `fleet:allies:manage` changes it, and the
// client gates on the evaluated capability rather than on a privilege string.
const canManage = computed(
  () => props.membership.capabilities?.manageAllies ?? false,
);
</script>

<template>
  <RelationshipView
    kind="fleet"
    :tab="tab"
    :tabs="tabs"
    :rows="rows"
    :async-status="asyncStatus"
    :is-loading="isLoading"
    :busy="busy"
    :can-manage="canManage"
    :on-add="onAdd"
    @update:tab="tab = $event"
    @accept="onAccept"
    @decline="onDecline"
    @ignore="onIgnore"
    @remove="onRemove"
  />
</template>
