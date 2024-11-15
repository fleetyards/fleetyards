<script lang="ts">
export default {
  name: "PublicHangarPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import VehiclesEmpty from "@/frontend/components/Vehicles/Empty/index.vue";
import FilterForm from "@/frontend/components/Hangar/FilterForm/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { debounce } from "ts-debounce";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  type HangarGroupMetric,
  HangarGroup,
  type UserPublic,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { usePagination } from "@/shared/composables/usePagination";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { usePublicHangarQueries } from "@/frontend/composables/usePublicHangarQueries";
import { useHangarFilters } from "@/frontend/composables/useHangarFilters";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  ChannelsEnum,
  useSubscription,
} from "@/shared/composables/useSubscription";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";

const { t } = useI18n();

type Props = {
  user: UserPublic;
};

const props = defineProps<Props>();

const username = computed(() => {
  return props.user.username;
});

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

const userTitle = computed(() => {
  return username.value[0].toUpperCase() + username.value.slice(1);
});

const comlink = useComlink();

const highlightedGroup = ref<string>("");

const mobile = useMobile();

const fleetchartStore = useFleetchartStore();

const fleetchartVisible = computed(() => fleetchartStore.isVisible("hangar"));

const { publicHangarQuery } = usePublicHangarQueries(username.value);

const { filters } = useHangarFilters(() => refetch());

const { perPage, page, updatePerPage } = usePagination("hangar");

const {
  data: vehicles,
  refetch,
  ...asyncStatus
} = publicHangarQuery({
  page,
  perPage,
  filters,
});

// const { data: hangarStats, refetch: refetchStats } = publicStatsQuery(filters);

// const { data: hangarGroups, refetch: refetchGroups } = publicGroupsQuery();

const fetch = () => {
  refetch();
  // refetchStats();
  // refetchGroups();
};

// const hangarGroupCounts = computed<HangarGroupMetric[]>(() => {
//   if (!hangarStats.value) {
//     return [];
//   }

//   return hangarStats.value.groups;
// });

const route = useRoute();

watch(
  () => route.query.q,
  () => {
    fetch();
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
  <div class="row">
    <div class="col-12 col-lg-8">
      <Heading>
        <Avatar :avatar="user.avatar" />
        <span>
          {{ t("headlines.hangar.public", { user: usernamePlural }) }}
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
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="hangar-header">
        <div class="hangar-labels">
          <GroupLabels
            v-if="hangarStats && hangarGroups"
            :hangar-groups="hangarGroups"
            :hangar-group-counts="hangarGroupCounts"
            :label="t('labels.groups')"
            :editable="true"
            @highlight="highlightGroup"
          />
        </div>
      </div>
    </div>
  </div>

  <Teleport v-if="!mobile" to="#header-right">
    <Btn v-if="user.publicWishlist" :to="{ name: 'hangar-wishlist' }">
      <i class="fad fa-wand-sparkles" />
      {{ t("labels.wishlist") }}
      <transition name="fade" mode="out-in" appear>
        <span v-if="hangarStats && hangarStats.wishlistTotal">
          ({{ hangarStats.wishlistTotal }})
        </span>
      </transition>
    </Btn>

    <Btn data-test="fleetchart-link" @click="toggleFleetchart">
      <i class="fad fa-starship" />
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
          v-if="user.publicWishlist"
          :to="{ name: 'hangar-wishlist' }"
          :size="BtnSizesEnum.SMALL"
        >
          <i class="fad fa-wand-sparkles" />
          <span>{{ t("labels.wishlist") }}</span>
        </Btn>

        <Btn
          data-test="fleetchart-link"
          :size="BtnSizesEnum.SMALL"
          @click="toggleFleetchart"
        >
          <i class="fad fa-starship" />
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

    <template #pagination-bottom>
      <Paginator
        v-if="vehicles"
        :query-result-ref="vehicles"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #empty="{ hideEmptyBox, emptyBoxVisible }">
      <VehiclesEmpty
        v-if="!hideEmptyBox && emptyBoxVisible"
        :variant="EmptyVariantsEnum.BOX"
      />
    </template>
  </FilteredList>
</template>
