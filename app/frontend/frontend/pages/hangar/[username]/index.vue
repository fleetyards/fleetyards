<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import HangarPublicHeading from "@/frontend/components/Hangar/PublicHeading/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import HangarEmpty from "@/frontend/components/Hangar/Empty/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import GroupLabels from "@/frontend/components/Hangar/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import debounce from "lodash.debounce";
import Paginator from "@/shared/components/Paginator/index.vue";
import { HangarGroup, type UserPublic } from "@/services/fyApi";
import RsiProfileLink from "@/shared/components/RsiProfileLink/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import {
  usePublicHangar as usePublicHangarQuery,
  getPublicHangarQueryKey,
  usePublicHangarStats,
  usePublicHangarGroups,
  type HangarGroupMetric,
} from "@/services/fyApi";

const { t } = useI18n();

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

const username = computed(() => {
  return props.user.username;
});

const highlightedGroup = ref<string>("");

const mobile = useMobile();

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("hangar"));

const { filters } = useHangarFilters(async () => {
  await refetch();
});

const publicHangarQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
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

const highlightGroup = (group?: HangarGroup) => {
  if (!group) {
    highlightedGroup.value = "";
    return;
  }

  highlightedGroup.value = group.id;
};

useSubscription({
  channelName: ChannelsEnum.HANGAR,
  received: () => debounce(fetch, 500),
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
    <Btn v-if="user.publicHangarStats" :to="{ name: 'hangar-public-stats' }">
      <i class="fa-duotone fa-chart-bar" />
      {{ t("nav.stats") }}
    </Btn>

    <Btn v-if="user.publicWishlist" :to="{ name: 'wishlist-public' }">
      <i class="fa-duotone fa-wand-sparkles" />
      {{ t("labels.wishlist") }}
      <transition name="fade" mode="out-in" appear>
        <span v-if="hangarStats && hangarStats.wishlistTotal">
          ({{ hangarStats.wishlistTotal }})
        </span>
      </transition>
    </Btn>

    <Btn data-test="fleetchart-link" @click="toggleFleetchart">
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
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <Btn
          v-if="user.publicHangarStats"
          :to="{ name: 'hangar-public-stats' }"
          :size="BtnSizesEnum.SMALL"
        >
          <i class="fa-duotone fa-chart-bar" />
          <span>{{ t("nav.stats") }}</span>
        </Btn>

        <Btn
          v-if="user.publicWishlist"
          :to="{ name: 'hangar-wishlist' }"
          :size="BtnSizesEnum.SMALL"
        >
          <i class="fa-duotone fa-wand-sparkles" />
          <span>{{ t("labels.wishlist") }}</span>
        </Btn>

        <Btn
          data-test="fleetchart-link"
          :size="BtnSizesEnum.SMALL"
          @click="toggleFleetchart"
        >
          <i class="fa-duotone fa-starship" />
          <span>{{ t("labels.fleetchart") }}</span>
        </Btn>
      </BtnDropdown>
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
            v-if="vehicles"
            :query-result-ref="vehicles"
            :per-page="perPage"
            :size="BtnSizesEnum.SMALL"
            :update-per-page="updatePerPage"
          />
        </template>
      </FleetchartApp>
    </template>

    <template #pagination-top>
      <Paginator
        v-if="vehicles"
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="vehicles"
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
