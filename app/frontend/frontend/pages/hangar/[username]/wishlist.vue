<script setup lang="ts">
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useGet as usePublicWishlist } from "@/services/fyApi";
import type { UserPublic, Vehicle } from "@/services/fyApi";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";

import Btn from "@/shared/components/base/Btn/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import GroupLabels from "@/frontend/components/Hangar/GroupLabels/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";

const { t } = useI18n();
const mobile = useMobile();
const route = useRoute();

// Accept user as a prop
const props = defineProps<{ user: UserPublic }>();

const username = computed(() => props.user.username);
const userTitle = computed(
  () => username.value.charAt(0).toUpperCase() + username.value.slice(1),
);
const usernamePlural = computed(() => {
  if (
    userTitle.value.endsWith("s") ||
    userTitle.value.endsWith("x") ||
    userTitle.value.endsWith("z")
  ) {
    return userTitle.value;
  }
  return `${userTitle.value}'s`;
});

const wishlistQuery = usePublicWishlist(username);
const asyncStatus: AsyncStatus = {
  fetchStatus: wishlistQuery.fetchStatus,
  isError: wishlistQuery.isError,
  isLoading: wishlistQuery.isLoading,
  isFetching: wishlistQuery.isFetching,
  isRefetching: wishlistQuery.isRefetching,
  error: wishlistQuery.error,
  refetch: wishlistQuery.refetch,
};
const wishlist = wishlistQuery.data;
const refetch = wishlistQuery.refetch;
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-8">
      <Heading>
        <Avatar :avatar="user.avatar" />
        <span>
          {{ t("headlines.hangar.publicWishlist", { user: usernamePlural }) }}
        </span>
      </Heading>
    </div>
    <div class="col-12 col-lg-4 hangar-profile-links">
      <a
        v-if="user.homepage"
        v-tooltip="t('labels.homepage')"
        :href="`//${user.homepage}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fal fa-globe globe-rotate" />
      </a>
      <a
        v-if="user.rsiHandle"
        v-tooltip="t('nav.rsiProfile')"
        :href="`https://robertsspaceindustries.com/citizens/${user.rsiHandle}`"
        target="_blank"
        rel="noopener"
      >
        <i class="icon icon-rsi" />
      </a>
      <a
        v-if="user.guilded"
        v-tooltip="t('labels.guilded')"
        :href="`//${user.guilded}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-guilded" />
      </a>
      <a
        v-if="user.discord"
        v-tooltip="t('labels.discord')"
        :href="`//${user.discord}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-discord" />
      </a>
      <a
        v-if="user.youtube"
        v-tooltip="t('labels.youtube')"
        :href="`//${user.youtube}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-youtube" />
      </a>
      <a
        v-if="user.twitch"
        v-tooltip="t('labels.twitch')"
        :href="`//${user.twitch}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fab fa-twitch" />
      </a>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn :to="{ name: 'hangar-public' }">
      <i class="fad fa-ship" />
      {{ t("labels.hangar") }}
    </Btn>
  </Teleport>

  <FilteredList
    :key="`public-wishlist-${username}`"
    :records="wishlist?.items || []"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
  >
    <template v-if="mobile" #actions-right>
      <BtnDropdown>
        <Btn :to="{ name: 'hangar-public' }">
          <i class="fad fa-ship" />
          <span>{{ t("labels.hangar") }}</span>
        </Btn>
      </BtnDropdown>
    </template>

    <template #default="{ records }">
      <Grid
        :records="records as Vehicle[]"
        :primary-key="'id'"
        :filter-visible="false"
      >
        <template #default="{ record }">
          <VehiclePanel :vehicle="record" :details="false" :editable="false" />
        </template>
      </Grid>
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="wishlist"
        :query-result-ref="wishlist"
        :per-page="wishlist?.meta?.pagination?.defaultPerPage || 20"
        :update-per-page="() => refetch()"
      />
    </template>

    <template #empty="{ hideEmpty, emptyVisible }">
      <div v-if="!hideEmpty && emptyVisible" class="wishlist-empty">
        {{ t("messages.empty.wishlist") }}
      </div>
    </template>
  </FilteredList>
</template>
