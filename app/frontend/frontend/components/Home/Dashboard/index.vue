<script lang="ts">
export default {
  name: "HomeDashboard",
};
</script>

<script lang="ts" setup>
import RaffleDashboardPanel from "@/frontend/components/Raffles/DashboardPanel/index.vue";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import DashboardHero from "@/frontend/components/Home/Dashboard/Hero/index.vue";
import PatchTiles from "@/frontend/components/Home/Dashboard/PatchTiles/index.vue";
import InvitesAlert from "@/frontend/components/Home/Dashboard/InvitesAlert/index.vue";
import ComingUpPanel from "@/frontend/components/Home/Dashboard/ComingUpPanel/index.vue";
import ContractsPanel from "@/frontend/components/Home/Dashboard/ContractsPanel/index.vue";
import InventoryPanel from "@/frontend/components/Home/Dashboard/InventoryPanel/index.vue";
import ShipsPanel from "@/frontend/components/Home/Dashboard/ShipsPanel/index.vue";
import WishlistPanel from "@/frontend/components/Home/Dashboard/WishlistPanel/index.vue";
import NewShipsPanel from "@/frontend/components/Home/Dashboard/NewShipsPanel/index.vue";
import FleetPanel from "@/frontend/components/Home/Dashboard/FleetPanel/index.vue";
import PlanPanel from "@/frontend/components/Home/Dashboard/PlanPanel/index.vue";
import NotificationsPanel from "@/frontend/components/Home/Dashboard/NotificationsPanel/index.vue";
import FriendsPanel from "@/frontend/components/Home/Dashboard/FriendsPanel/index.vue";
import { FeatureFlagName } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";

const { isFeatureEnabled } = useFeatures();
</script>

<template>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" />
  </Teleport>

  <DashboardHero />

  <!-- Two columns from 992px. Below that both collapse into one, in the order
       a pilot acts on them: what needs an answer first. -->
  <div class="home-dashboard" data-test="home-dashboard">
    <div class="home-dashboard__main">
      <InvitesAlert class="home-dashboard__invites" />
      <ComingUpPanel class="home-dashboard__coming-up" />
      <ContractsPanel class="home-dashboard__contracts" />
      <ShipsPanel class="home-dashboard__ships" />
      <WishlistPanel class="home-dashboard__wishlist" />
      <NewShipsPanel class="home-dashboard__new-ships" />
    </div>
    <aside class="home-dashboard__side">
      <PatchTiles class="home-dashboard__patch" />
      <FleetPanel class="home-dashboard__fleet" />
      <RaffleDashboardPanel class="home-dashboard__raffle" />
      <PlanPanel
        v-if="isFeatureEnabled(FeatureFlagName.HANGAR_PLANNER)"
        class="home-dashboard__plan"
      />
      <InventoryPanel class="home-dashboard__inventory" />
      <NotificationsPanel class="home-dashboard__notifications" />
      <FriendsPanel class="home-dashboard__friends" />
    </aside>
  </div>
</template>

<style lang="scss" scoped>
.home-dashboard__patch {
  margin-bottom: 16px;
}

.home-dashboard {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.home-dashboard__main,
.home-dashboard__side {
  display: contents;
}

.home-dashboard__invites {
  order: 0;
}

.home-dashboard__coming-up {
  order: 1;
}

.home-dashboard__contracts {
  order: 2;
}

.home-dashboard__ships {
  order: 3;
}

.home-dashboard__wishlist {
  order: 4;
}

.home-dashboard__patch,
.home-dashboard__fleet {
  order: 6;
}

.home-dashboard__raffle {
  order: 7;
}

.home-dashboard__plan {
  order: 8;
}

.home-dashboard__inventory {
  order: 9;
}

.home-dashboard__notifications {
  order: 10;
}

.home-dashboard__friends {
  order: 11;
}

.home-dashboard__new-ships {
  order: 12;
}

@media (min-width: 992px) {
  .home-dashboard {
    display: grid;
    grid-template-columns: minmax(0, 2fr) minmax(0, 1fr);
    gap: 20px;
    align-items: start;
  }

  .home-dashboard__main,
  .home-dashboard__side {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 0;
  }
}
</style>
