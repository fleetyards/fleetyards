<template>
  <section class="container fleet-detail">
    <div v-if="fleet" class="row">
      <div class="col-12 col-lg-8">
        <h1 class="heading">
          <Avatar
            v-if="fleet.logo"
            :avatar="fleet.logo"
            :transparent="!!fleet.logo"
            icon="fad fa-image"
          />
          {{ fleet.name }} ({{ fleet.fid }})
        </h1>
      </div>
      <div
        class="col-12 col-lg-4 d-flex justify-content-end align-items-center"
      >
        <div v-if="!mobile" class="page-actions">
          <Btn
            :inline="true"
            data-test="fleetchart-link"
            @click.native="toggleFleetchart"
          >
            <i class="fad fa-starship" />
            {{ t("labels.fleetchart") }}
          </Btn>

          <ShareBtn
            v-if="fleet.myFleet && fleet.publicFleet"
            :url="shareUrl"
            :title="metaTitle || ''"
            :inline="true"
          />
        </div>
      </div>
    </div>

    <br />

    <template v-if="fleet">
      <ShipsList
        v-if="fleet.myFleet"
        :fleet="fleet"
        :share-url="shareUrl"
        :meta-title="metaTitle"
      />
      <PublicShipsList v-else-if="fleet.publicFleet" :fleet="fleet" />
    </template>
  </section>
</template>

<script lang="ts" setup>
import { computed, watch, onMounted } from "vue";
import { useRoute } from "vue-router/composables";
import { storeToRefs } from "pinia";
import Btn from "@/frontend/core/components/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { publicFleetShipsRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import PublicShipsList from "@/frontend/components/Fleets/PublicShipsList/index.vue";
import ShipsList from "@/frontend/components/Fleets/ShipsList/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import { useAppStore } from "@/frontend/stores/App";
import { useFleetStore } from "@/frontend/stores/Fleet";
import { usePublicFleetStore } from "@/frontend/stores/PublicFleet";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";

useHangarItems();
useWishlistItems();

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const fleet = computed(() => fleetsCollection.record);

const metaTitle = computed(() => {
  if (!fleet.value) {
    return undefined;
  }

  return fleet.value.name;
});

const { updateMetaInfo } = useMetaInfo();

const shareUrl = () => {
  if (!fleet.value) {
    return "";
  }
  const host = `${window.location.protocol}//${window.location.host}`;

  return `${host}/fleets/${fleet.value.slug}/ships`;
};

const route = useRoute();

const fetch = async () => {
  await fleetsCollection.findBySlug(route.params.slug);
};

watch(
  () => route,
  () => {
    fetch();
  },
  { deep: true }
);

watch(
  () => fleet.value,
  () => {
    updateMetaInfo(metaTitle.value);
  }
);

onMounted(() => {
  fetch();
});

const fleetStore = useFleetStore();
const publicFleetStore = usePublicFleetStore();

const toggleFleetchart = () => {
  if (fleet.value?.myFleet) {
    fleetStore.toggleFleetchart();
  } else {
    publicFleetStore.toggleFleetchart();
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetShipsPage",
  beforeRouteEnter: publicFleetShipsRouteGuard,
};
<script lang="ts">
export default {
  name: "FleetShipsPage",
  beforeRouteEnter: publicFleetShipsRouteGuard,
};
</script>

<style lang="scss" scoped>
.heading {
  display: flex;
  align-items: center;
  justify-content: flex-start;

  .avatar {
    margin-right: 20px;
  }
}
</style>
