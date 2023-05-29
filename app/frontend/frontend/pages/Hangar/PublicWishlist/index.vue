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
                  t("headlines.hangar.publicWishlist", {
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
      key="public-wishlist"
      :collection="collection"
      :name="route.name || ''"
      :route-query="route.query"
      :params="route.params"
      :hash="route.hash"
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
              :loaners-hint-visible="user?.publicHangarLoaners"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import { publicHangarRouteGuard } from "@/frontend/utils/RouteGuards/Hangar";
import publicWishlistCollection from "@/frontend/api/collections/PublicWishlist";
import type { PublicWishlistCollection } from "@/frontend/api/collections/PublicWishlist";
import publicUserCollection from "@/frontend/api/collections/PublicUser";
import type { PublicUserCollection } from "@/frontend/api/collections/PublicUser";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";

const collection: PublicWishlistCollection = publicWishlistCollection;

const userCollection: PublicUserCollection = publicUserCollection;

const { t } = useI18n();

const metaTitle = computed(() =>
  t("title.hangar.publicWishlist", {
    user: usernamePlural.value,
  })
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

const filters = computed(() => ({
  username: username.value,
  page: Number(route.query.page),
  filters: route.query.q as TVehiclesFilter,
}));

watch(
  () => route.query,
  () => {
    fetch();
  },
  { deep: true }
);

const { updateMetaInfo } = useMetaInfo();

onMounted(async () => {
  await fetch();

  updateMetaInfo(metaTitle.value);
});

const fetch = async () => {
  await userCollection.findByUsername(username.value);
  await collection.findAll(filters.value);
};
</script>

<script lang="ts">
export default {
  name: "PublicWishlist",
  beforeRouteEnter: publicHangarRouteGuard,
};
</script>
