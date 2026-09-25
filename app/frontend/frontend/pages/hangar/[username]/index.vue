<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import { useVehicleSortFields } from "@/frontend/composables/useVehicleSortFields";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarPublicHeading from "@/frontend/components/Hangar/PublicHeading/index.vue";
import FriendButton from "@/frontend/components/Relationships/FriendButton/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import HangarEmpty from "@/frontend/components/Hangar/Empty/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import GroupLabels from "@/frontend/components/Hangar/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  HangarGroup,
  type HangarGroupPublic,
  type UserPublic,
} from "@/services/fyApi";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useSubscription } from "@/shared/composables/useSubscription";
import { HangarChannel } from "@/services/fyCable/channels/HangarChannel";
import { useDebouncedRefresh } from "@/shared/composables/useDebouncedRefresh";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  usePublicHangar as usePublicHangarQuery,
  getPublicHangarQueryKey,
  usePublicHangarStats,
  usePublicHangarGroups,
  type HangarGroupMetric,
} from "@/services/fyApi";

const { t } = useI18n();

const sortFields = useVehicleSortFields({ rank: true });

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

// The owner's chosen order is the one the server answers with while the URL
// names no sort, so it is the chip shown as chosen.
const defaultSort = computed(() => props.user.hangarDefaultSort ?? "name asc");

const username = computed(() => {
  return props.user.username;
});

const highlightedGroup = ref<string>("");

const mobile = useMobile();

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("hangar"));

const { filters, getQuery } = useHangarFilters(async () => {
  await refetch();
});

const publicHangarQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: getQuery(),
  };
});

const publicHangarQueryKey = computed(() => {
  return getPublicHangarQueryKey(username.value, publicHangarQueryParams.value);
});

const { perPage, page, updatePerPage } = usePagination(publicHangarQueryKey);

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = usePublicHangarQuery(username, publicHangarQueryParams);

const publicHangarStatsQueryParams = computed(() => {
  return { q: filters.value };
});

const { data: hangarStats, refetch: refetchStats } = usePublicHangarStats(
  username,
  publicHangarStatsQueryParams,
);

const { data: hangarGroups, refetch: refetchGroups } =
  usePublicHangarGroups(username);

const fetch = async () => {
  await refetch();
  await refetchStats();
  await refetchGroups();
};

const hangarGroupCounts = computed<HangarGroupMetric[]>(() => {
  if (!hangarStats.value) {
    return [];
  }

  return hangarStats.value.groups;
});

const route = useRoute();

watch(
  () => route.query.q,
  async () => {
    await fetch();
  },
);

const toggleFleetchart = () => {
  fleetchartStore.toggleFleetchart("hangar");
};

const highlightGroup = (group?: HangarGroup | HangarGroupPublic) => {
  if (!group) {
    highlightedGroup.value = "";
    return;
  }

  highlightedGroup.value = group.id;
};

const refresh = useDebouncedRefresh(fetch);

useSubscription({
  channel: HangarChannel,
  received: refresh,
  // The channel replays nothing it broadcast while the socket was down, so
  // the hangar is read again on the way back rather than waiting for whatever
  // changes next.
  connected: ({ reconnect }) => {
    if (reconnect) {
      refresh();
    }
  },
});
</script>

<template>
  <div class="row hangar-public">
    <div class="col-12 col-lg-8">
      <HangarPublicHeading :user="props.user" />
    </div>

    <div class="col-12 col-lg-4 hangar-profile-links">
      <a
        v-if="user.homepage"
        v-tooltip="t('labels.homepage')"
        :aria-label="t('labels.homepage')"
        :href="`//${user.homepage}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-light fa-globe globe-rotate" />
      </a>
      <RsiProfileLink
        v-if="user.rsiHandle"
        :handle="user.rsiHandle"
        :citizenid-profile-url="user.citizenidProfileUrl"
        icon-only
      />
      <a
        v-if="user.guilded"
        v-tooltip="t('labels.guilded')"
        :aria-label="t('labels.guilded')"
        :href="`//${user.guilded}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-guilded" />
      </a>
      <a
        v-if="user.discord"
        v-tooltip="t('labels.discord')"
        :aria-label="t('labels.discord')"
        :href="`//${user.discord}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-discord" />
      </a>
      <a
        v-if="user.youtube"
        v-tooltip="t('labels.youtube')"
        :aria-label="t('labels.youtube')"
        :href="`//${user.youtube}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-youtube" />
      </a>
      <a
        v-if="user.twitch"
        v-tooltip="t('labels.twitch')"
        :aria-label="t('labels.twitch')"
        :href="`//${user.twitch}`"
        target="_blank"
        rel="noopener"
      >
        <i class="fa-brands fa-twitch" />
      </a>
    </div>
  </div>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="hangar-header">
        <div class="hangar-labels">
          <GroupLabels
            v-if="hangarStats && hangarGroups"
            :hangar-groups="hangarGroups"
            :hangar-group-counts="hangarGroupCounts"
            :label="t('labels.groups')"
            @highlight="highlightGroup"
          />
        </div>
      </div>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <FriendButton :username="username" :size="BtnSizesEnum.MD" />

    <Btn
      :size="BtnSizesEnum.MD"
      v-if="user.publicHangarStats"
      :to="{ name: 'hangar-public-stats' }"
    >
      <i class="fa-duotone fa-chart-bar" />
      {{ t("nav.stats") }}
    </Btn>

    <Btn
      :size="BtnSizesEnum.MD"
      v-if="user.publicWishlist"
      :to="{ name: 'wishlist-public' }"
    >
      <i class="fa-duotone fa-wand-sparkles" />
      {{ t("labels.wishlist") }}
      <transition name="fade" mode="out-in" appear>
        <span v-if="hangarStats && hangarStats.wishlistTotal">
          ({{ hangarStats.wishlistTotal }})
        </span>
      </transition>
    </Btn>

    <Btn
      :size="BtnSizesEnum.MD"
      data-test="fleetchart-link"
      @click="toggleFleetchart"
    >
      <i class="fa-duotone fa-starship" />
      {{ t("labels.fleetchart") }}
    </Btn>
  </Teleport>

  <FilteredList
    :key="`public-hangar-${username}`"
    :hide-loading="fleetchartVisible"
    :records="vehicles?.items || []"
    :name="route.name?.toString() || ''"
    :async-status="asyncStatus"
  >
    <template v-if="mobile" #actions-right>
      <BtnDropdown>
        <FriendButton :username="username" />

        <Btn
          v-if="user.publicHangarStats"
          :to="{ name: 'hangar-public-stats' }"
        >
          <i class="fa-duotone fa-chart-bar" />
          <span>{{ t("nav.stats") }}</span>
        </Btn>

        <Btn v-if="user.publicWishlist" :to="{ name: 'hangar-wishlist' }">
          <i class="fa-duotone fa-wand-sparkles" />
          <span>{{ t("labels.wishlist") }}</span>
        </Btn>

        <Btn data-test="fleetchart-link" @click="toggleFleetchart">
          <i class="fa-duotone fa-starship" />
          <span>{{ t("labels.fleetchart") }}</span>
        </Btn>
      </BtnDropdown>
    </template>

    <template #skeleton="{ filterVisible }">
      <GridSkeleton :filter-visible="filterVisible" />
    </template>

    <template #sort>
      <!-- A public hangar is only ever cards, so this is the whole
      sort control rather than a second way to reach one. -->
      <SortBar :columns="sortFields" :default-sort="defaultSort" />
    </template>

    <template #default="{ records, loading }">
      <Grid :records="records" :filter-visible="false" primary-key="id">
        <template #default="{ record }">
          <VehiclePanel
            :vehicle="record"
            :details="false"
            :editable="false"
            :highlight="record.hangarGroupIds.includes(highlightedGroup)"
            :loaners-hint-visible="user.publicHangarLoaners"
          />
        </template>
      </Grid>

      <FleetchartApp
        :items="vehicles?.items || []"
        namespace="hangar"
        :loading="loading"
        download-name="my-hangar-fleetchart"
      >
        <template #filter>
          <FilterForm hide-quicksearch />
        </template>
        <template #pagination>
          <Paginator
            :query-result-ref="vehicles"
            :per-page="perPage"
            :size="BtnSizesEnum.SM"
            :update-per-page="updatePerPage"
          />
        </template>
      </FleetchartApp>
    </template>

    <template #pagination-top>
      <Paginator
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #empty="{ hideEmpty, emptyVisible }">
      <HangarEmpty
        v-if="!hideEmpty && emptyVisible"
        :variant="EmptyVariantsEnum.BOX"
      />
    </template>
  </FilteredList>
</template>
