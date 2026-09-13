<script lang="ts">
export default {
  name: "FriendsPage",
};
</script>

<script lang="ts" setup>
import type { Crumb } from "@/shared/components/BreadCrumbs/types";
import RelationshipView from "@/frontend/components/Relationships/RelationshipView/index.vue";
import { useRelationshipTab } from "@/frontend/composables/useRelationshipTab";
import { useFriendships } from "@/frontend/composables/useFriendships";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { tab, tabs, state, direction } = useRelationshipTab({
  accepted: "friends",
  incoming: "friends-incoming",
  outgoing: "friends-outgoing",
  ignored: "friends-ignored",
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
} = useFriendships(state, direction);

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "hangar" }, label: t("nav.hangar.index") },
]);
</script>

<template>
  <RelationshipView
    :crumbs="crumbs"
    :heading="t('headlines.relationships.user.index')"
    kind="user"
    :tab="tab"
    :tabs="tabs"
    :rows="rows"
    :async-status="asyncStatus"
    :is-loading="isLoading"
    :busy="busy"
    :on-add="onAdd"
    @update:tab="tab = $event"
    @accept="onAccept"
    @decline="onDecline"
    @ignore="onIgnore"
    @remove="onRemove"
  />
</template>
