<script lang="ts">
export default {
  name: "SettingsFriendsPage",
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
  accepted: "settings-friends",
  incoming: "settings-friends-incoming",
  outgoing: "settings-friends-outgoing",
  ignored: "settings-friends-ignored",
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
  { to: { name: "settings" }, label: t("nav.settings.index") },
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
