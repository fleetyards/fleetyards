<script lang="ts">
export default {
  name: "HomeDashboardFriendsPanel",
};
</script>

<script lang="ts" setup>
import DashboardPanel from "@/shared/components/Dashboard/Panel/index.vue";
import DashboardEmpty from "@/shared/components/Dashboard/Empty/index.vue";
import { liveQuery } from "@/shared/components/Dashboard/liveQuery";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { RelationshipStateEnum, useFriends } from "@/services/fyApi";
import { useMemberPresence } from "@/frontend/composables/useMemberPresence";
import { usePendingFriendRequests } from "@/frontend/composables/usePendingFriendRequests";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

// The people worth a glance: whoever is online, then whoever was around last.
const SHOWN = 5;

const { data, isLoading, isFetching, isLoadingError } = useFriends(
  { state: RelationshipStateEnum.ACCEPTED, limit: 50 },
  { query: liveQuery },
);

const { onlineFor } = useMemberPresence();
const { count: pendingCount } = usePendingFriendRequests();

const friends = computed(() =>
  (data.value?.items || [])
    .map((friendship) => ({
      ...friendship,
      online: onlineFor({
        userId: friendship.user.id,
        online: friendship.user.online,
        lastActiveAt: friendship.user.lastActiveAt,
      }),
    }))
    .sort((a, b) => {
      if (a.online !== b.online) return a.online ? -1 : 1;

      return (b.user.lastActiveAt || "").localeCompare(
        a.user.lastActiveAt || "",
      );
    })
    .slice(0, SHOWN),
);
</script>

<template>
  <DashboardPanel
    :title="t('home.dashboard.friends.title')"
    :pending="isLoading"
    :fetching="isFetching"
    :failed="isLoadingError"
    :empty="!friends.length && !pendingCount"
    :more="{ name: 'settings-friends' }"
    data-test="home-friends"
  >
    <div class="home-friends">
      <RowListItem
        v-for="friend in friends"
        :key="friend.id"
        :to="{
          name: 'hangar-public',
          params: { username: friend.user.username },
        }"
      >
        <template #leading>
          <Avatar
            :avatar="friend.user.avatar?.smallUrl"
            size="small"
            :online="friend.online"
          />
        </template>
        <template #name>{{ friend.user.username }}</template>
        <template #sub>
          <span v-if="friend.online">{{
            t("home.dashboard.friends.online")
          }}</span>
          <span v-else-if="friend.user.currentLocation?.name">
            {{ friend.user.currentLocation.name }}
          </span>
        </template>
      </RowListItem>
      <div v-if="pendingCount" class="home-friends__pending">
        <Btn
          :size="BtnSizesEnum.SM"
          :to="{ name: 'settings-friends-incoming' }"
        >
          <i class="fa-light fa-user-plus" />
          {{ t("home.dashboard.friends.pending", { count: pendingCount }) }}
        </Btn>
      </div>
    </div>
    <template #empty>
      <DashboardEmpty
        icon="fa-user-group"
        :title="t('home.dashboard.friends.empty.title')"
        :hint="t('home.dashboard.friends.empty.hint')"
      />
    </template>
  </DashboardPanel>
</template>

<style lang="scss" scoped>
.home-friends {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.home-friends__pending {
  margin-top: 4px;
}
</style>
