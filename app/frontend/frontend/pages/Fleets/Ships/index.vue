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
import { useRoute } from "vue-router";
import Btn from "@/frontend/core/components/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { publicFleetShipsRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import PublicShipsList from "@/frontend/components/Fleets/PublicShipsList/index.vue";
import ShipsList from "@/frontend/components/Fleets/ShipsList/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import Store from "@/frontend/lib/Store";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { useI18n } from "@/frontend/composables/useI18n";

const { updateMetaInfo } = useMetaInfo();

const { t } = useI18n();

const mobile = computed(() => Store.getters.mobile);

const fleet = computed(() => fleetsCollection.record);

const metaTitle = computed(() => {
  if (!fleet.value) {
    return undefined;
  }

  return fleet.value.name;
});

const shareUrl = computed(() => {
  if (!fleet.value) {
    return "";
  }
  const host = `${window.location.protocol}//${window.location.host}`;

  return `${host}/fleets/${fleet.value.slug}/ships`;
});

const route = useRoute();

watch(
  () => fleet.value,
  () => {
    updateMetaInfo({ title: metaTitle.value });
  },
);

watch(
  () => route.path,
  () => {
    fetch();
  },
);

onMounted(() => {
  fetch();
});

const toggleFleetchart = () => {
  if (fleet.value?.myFleet) {
    Store.dispatch("fleet/toggleFleetchart");
  } else {
    Store.dispatch("publicFleet/toggleFleetchart");
  }
};

const fetch = async () => {
  await fleetsCollection.findBySlug(route.params.slug);
};
</script>

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
