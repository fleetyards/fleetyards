<template>
  <section class="container hangar hangar-public">
    <div v-if="user" class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12" />
        </div>
        <div class="row">
          <div class="col-12 col-lg-8">
            <h1>
              <Avatar :avatar="user.avatar" />
              <span>
                {{ t("headlines.hangar.public", { user: usernamePlural }) }}
              </span>
            </h1>
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
        <div class="hangar-header">
          <div class="hangar-labels">
            <GroupLabels
              v-if="hangarStats"
              :hangar-groups="groupsCollection.records"
              :hangar-group-counts="hangarGroupCounts"
              :label="t('labels.groups')"
              @highlight="highlightGroup"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Btn data-test="fleetchart-link" @click.native="toggleFleetchart">
              <i class="fad fa-starship" />
              {{ t("labels.fleetchart") }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
    <FilteredList
      key="public-hangar"
      :collection="collection"
      :name="route.name || ''"
      :route-query="route.query"
      :params="route.params"
      :hash="route.hash"
      :paginated="true"
      :hide-loading="fleetchartVisible"
    >
      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <VehiclePanel
              :vehicle="record"
              :highlight="record.hangarGroupIds.includes(highlightedGroup)"
              :loaners-hint-visible="user?.publicHangarLoaners"
            />
          </template>
        </FilteredGrid>

        <FleetchartApp
          :items="records"
          :loading="loading"
          namespace="publicHangar"
        />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import { publicHangarRouteGuard } from "@/frontend/utils/RouteGuards/Hangar";
import Btn from "@/frontend/core/components/Btn/index.vue";
import publicVehiclesCollection from "@/frontend/api/collections/PublicVehicles";
import publicUserCollection from "@/frontend/api/collections/PublicUser";
import publicHangarGroupsCollection from "@/frontend/api/collections/PublicHangarGroups";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";
import { storeToRefs } from "pinia";
import { useAppStore } from "@/frontend/stores/App";
import { usePublicHangarStore } from "@/frontend/stores/PublicHangar";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import type { PublicVehiclesCollection } from "@/frontend/api/collections/PublicVehicles";
import type { PublicUserCollection } from "@/frontend/api/collections/PublicUser";
import type { PublicHangarGroupsCollection } from "@/frontend/api/collections/PublicHangarGroups";

const { t } = useI18n();

const collection: PublicVehiclesCollection = publicVehiclesCollection;

const userCollection: PublicUserCollection = publicUserCollection;

const groupsCollection: PublicHangarGroupsCollection =
  publicHangarGroupsCollection;

const highlightedGroup = ref<string | null>(null);

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const publicHangarStore = usePublicHangarStore();

const { fleetchartVisible } = storeToRefs(publicHangarStore);

const toggleFleetchart = () => {
  publicHangarStore.toggleFleetchart();
};

const hangarGroupCounts = computed<THangarGroupMetrics[]>(() => {
  if (!hangarStats.value) {
    return [];
  }

  return hangarStats.value.groups;
});

const hangarStats = computed<TPublicVehicleStats | null>(
  () => collection.stats
);

const metaTitle = computed(() =>
  t("title.hangar.public", { user: usernamePlural.value })
);

const user = computed(() => userCollection.record);

const route = useRoute();

const username = computed(() => route.params.username);

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

const userTitle = computed(
  () => username.value[0].toUpperCase() + username.value.slice(1)
);

const filters = computed<TPublicVehicleParams | undefined>(() => {
  if (!username.value) {
    return undefined;
  }

  return {
    username: username.value,
    page: Number(route.query.page),
    filters: route.query.q as TVehiclesFilter,
  };
});

watch(
  () => route.query,
  () => {
    fetch();
  },
  { deep: true }
);

const { updateMetaInfo } = useMetaInfo();

onMounted(() => {
  fetch();

  updateMetaInfo(metaTitle.value);
});

const highlightGroup = (group: THangarGroup) => {
  if (!group) {
    highlightedGroup.value = null;

    return;
  }

  highlightedGroup.value = group.id;
};

const fetch = async () => {
  await userCollection.findByUsername(username.value);
  await groupsCollection.findAll(username.value);

  if (filters.value) {
    await collection.findAll(filters.value);
    await collection.findStats(filters.value);
  }
};
</script>

<script lang="ts">
export default {
  name: "PublicHangar",
  beforeRouteEnter: publicHangarRouteGuard,
};
</script>
