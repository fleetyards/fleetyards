<template>
  <FleetWrapper :fleet-slug="String(route.params.slug)">
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
              @click="toggleFleetchart"
            >
              <i class="fad fa-starship" />
              {{ t("labels.fleetchart") }}
            </Btn>

            <ShareBtn
              v-if="fleet.myFleet && fleet.publicFleet"
              :url="shareUrl"
              :title="shareTitle"
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
          :share-title="shareTitle"
        />
        <PublicShipsList v-else-if="fleet.publicFleet" :fleet="fleet" />
      </template>
    </section>
  </FleetWrapper>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import PublicShipsList from "@/frontend/components/Fleets/PublicShipsList/index.vue";
import ShipsList from "@/frontend/components/Fleets/ShipsList/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import FleetWrapper from "@/frontend/components/Fleets/FleetWrapper/index.vue";
import { useFleetQuery } from "@/frontend/composables/useFleetQuery";
import { useFleetchartStore } from "@/shared/stores/fleetchart";

const route = useRoute();

const { fleet } = useFleetQuery(String(route.params.slug));

const { t } = useI18n();

const { getTitle } = useMetaInfo(t);

const mobile = useMobile();

const shareUrl = computed(() => {
  if (!fleet.value) {
    return "";
  }
  const host = `${window.location.protocol}//${window.location.host}`;

  return `${host}/fleets/${fleet.value.slug}/ships`;
});

const shareTitle = computed(() => {
  const title = getTitle();

  if (!title) {
    return fleet.value?.name || "";
  }

  return title;
});

const fleetchartStore = useFleetchartStore();

const toggleFleetchart = () => {
  if (fleet.value?.myFleet) {
    fleetchartStore.toggleFleetchart("fleet");
  } else {
    fleetchartStore.toggleFleetchart("publicFleet");
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetShipsPage",
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
