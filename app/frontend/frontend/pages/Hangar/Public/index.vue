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
                {{ $t("headlines.hangar.public", { user: usernamePlural }) }}
              </span>
            </h1>
          </div>
          <div class="col-12 col-lg-4 hangar-profile-links">
            <a
              v-if="user.homepage"
              v-tooltip="$t('labels.homepage')"
              :href="`//${user.homepage}`"
              target="_blank"
              rel="noopener"
            >
              <i class="fal fa-globe globe-rotate" />
            </a>
            <a
              v-if="user.rsiHandle"
              v-tooltip="$t('nav.rsiProfile')"
              :href="`https://robertsspaceindustries.com/citizens/${user.rsiHandle}`"
              target="_blank"
              rel="noopener"
            >
              <i class="icon icon-rsi" />
            </a>
            <a
              v-if="user.guilded"
              v-tooltip="$t('labels.guilded')"
              :href="`//${user.guilded}`"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-guilded" />
            </a>
            <a
              v-if="user.discord"
              v-tooltip="$t('labels.discord')"
              :href="`//${user.discord}`"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-discord" />
            </a>
            <a
              v-if="user.youtube"
              v-tooltip="$t('labels.youtube')"
              :href="`//${user.youtube}`"
              target="_blank"
              rel="noopener"
            >
              <i class="fab fa-youtube" />
            </a>
            <a
              v-if="user.twitch"
              v-tooltip="$t('labels.twitch')"
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
              :label="$t('labels.groups')"
              @highlight="highlightGroup"
            />
          </div>
          <div v-if="!mobile" class="page-actions page-actions-right">
            <Btn data-test="fleetchart-link" @click.native="toggleFleetchart">
              <i class="fad fa-starship" />
              {{ $t("labels.fleetchart") }}
            </Btn>
          </div>
        </div>
      </div>
    </div>
    <FilteredList
      key="hangar"
      :collection="collection"
      :name="$route.name"
      :route-query="$route.query"
      :params="$route.params"
      :hash="$route.hash"
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
              :loaners-hint-visible="user.publicHangarLoaners"
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

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter, Action } from "vuex-class";
import { publicHangarRouteGuard } from "@/frontend/utils/RouteGuards/Hangar";
import Btn from "@/frontend/core/components/Btn/index.vue";
import publicVehiclesCollection from "@/frontend/api/collections/PublicVehicles";
import publicUserCollection from "@/frontend/api/collections/PublicUser";
import publicHangarGroupsCollection from "@/frontend/api/collections/PublicHangarGroups";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";

@Component<PublicHangar>({
  beforeRouteEnter: publicHangarRouteGuard,
  components: {
    Btn,
    AddonsModal,
    FilteredList,
    FilteredGrid,
    FleetchartApp,
    VehiclePanel,
    ModelClassLabels,
    Avatar,
    GroupLabels,
  },
})
export default class PublicHangar extends Vue {
  loading = false;

  collection: PublicVehiclesCollection = publicVehiclesCollection;

  userCollection: PublicUserCollection = publicUserCollection;

  highlightedGroup: string = null;

  groupsCollection: PublicHangarGroupsCollection = publicHangarGroupsCollection;

  @Getter("mobile") mobile;

  @Getter("fleetchartVisible", { namespace: "publicHangar" }) fleetchartVisible;

  @Getter("perPage", { namespace: "publicHangar" }) perPage;

  @Action("toggleFleetchart", { namespace: "publicHangar" })
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  toggleFleetchart: any;

  get hangarGroupCounts(): HangarGroupMetrics[] {
    if (!this.hangarStats) {
      return [];
    }

    return this.hangarStats.groups;
  }

  get hangarStats(): VehicleStats | null {
    return this.collection.stats;
  }

  get metaTitle() {
    return this.$t("title.hangar.public", { user: this.usernamePlural });
  }

  get user() {
    return this.userCollection.record;
  }

  get username() {
    return this.$route.params.username;
  }

  get usernamePlural() {
    if (
      this.userTitle.endsWith("s") ||
      this.userTitle.endsWith("x") ||
      this.userTitle.endsWith("z")
    ) {
      return this.userTitle;
    }

    return `${this.userTitle}'s`;
  }

  get userTitle() {
    return this.username[0].toUpperCase() + this.username.slice(1);
  }

  get filters() {
    return {
      username: this.username,
      page: this.$route.query.page,
      filters: this.$route.query.q,
    };
  }

  @Watch("$route")
  onRouteChange() {
    this.fetch();
  }

  @Watch("perPage")
  onPerPageChange() {
    this.fetch();
  }

  created() {
    this.fetch();
  }

  highlightGroup(group) {
    if (!group) {
      this.highlightedGroup = null;
      return;
    }

    this.highlightedGroup = group.id;
  }

  async fetch() {
    await this.userCollection.findByUsername(this.username);
    await this.groupsCollection.findAll(this.username);
    await this.collection.findAll(this.filters);
    await this.collection.findStatsByUsername(this.username, this.filters);
  }
}
</script>
