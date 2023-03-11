<template>
  <section class="container hangar hangar-public wishlist-public">
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
                {{
                  $t("headlines.hangar.publicWishlist", {
                    user: usernamePlural,
                  })
                }}
              </span>
            </h1>
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
    >
      <template #default="{ records, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <VehiclePanel
              :vehicle="record"
              :loaners-hint-visible="user.publicHangarLoaners"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter } from "vuex-class";
import { publicHangarRouteGuard } from "@/frontend/utils/RouteGuards/Hangar";
import Btn from "@/frontend/core/components/Btn/index.vue";
import publicWishlistCollection from "@/frontend/api/collections/PublicWishlist";
import type { PublicWishlistCollection } from "@/frontend/api/collections/PublicWishlist";
import publicUserCollection from "@/frontend/api/collections/PublicUser";
import type { PublicUserCollection } from "@/frontend/api/collections/PublicUser";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import ModelClassLabels from "@/frontend/components/Models/ClassLabels/index.vue";
import AddonsModal from "@/frontend/components/Vehicles/AddonsModal/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import GroupLabels from "@/frontend/components/Vehicles/GroupLabels/index.vue";
import MetaInfo from "@/frontend/mixins/MetaInfo";

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

  collection: PublicWishlistCollection = publicWishlistCollection;

  userCollection: PublicUserCollection = publicUserCollection;

  @Getter("mobile") mobile;

  @Getter("perPage", { namespace: "publicWishlist" }) perPage;

  get metaTitle() {
    return this.$t("title.hangar.publicWishlist", {
      user: this.usernamePlural,
    });
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

  async fetch() {
    await this.userCollection.findByUsername(this.username);
    await this.collection.findAll(this.filters);
  }
}
</script>
