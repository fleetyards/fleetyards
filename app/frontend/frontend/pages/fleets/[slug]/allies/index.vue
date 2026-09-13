<script lang="ts">
export default {
  name: "FleetAlliesPage",
};
</script>

<script lang="ts" setup>
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import RelationshipView from "@/frontend/components/Relationships/RelationshipView/index.vue";
import { useRelationshipTab } from "@/frontend/composables/useRelationshipTab";
import { useFleetAlliances } from "@/frontend/composables/useFleetAlliances";
import { type Fleet, type FleetMember } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

// Handed down by `allies.vue`, which gates the branch on the fleet's flag and
// on the reader's capability -- so this never renders for somebody who cannot
// see it.
type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { tab, tabs, state, direction } = useRelationshipTab({
  accepted: "fleet-allies",
  incoming: "fleet-allies-incoming",
  outgoing: "fleet-allies-outgoing",
  ignored: "fleet-allies-ignored",
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

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
]);
</script>

<template>
  <RelationshipView
    :crumbs="crumbs"
    :heading="t('headlines.relationships.fleet.index')"
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
