<script lang="ts">
export default {
  name: "HomeDashboard",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
import PatchSummary from "@/frontend/components/Home/Dashboard/PatchSummary/index.vue";
import InvitesAlert from "@/frontend/components/Home/Dashboard/InvitesAlert/index.vue";
import ComingUpPanel from "@/frontend/components/Home/Dashboard/ComingUpPanel/index.vue";
import MyFleetsPanel from "@/frontend/components/Home/Dashboard/MyFleetsPanel/index.vue";
import PatchChangesPanel from "@/frontend/components/Home/Dashboard/PatchChangesPanel/index.vue";
import HangarPanel from "@/frontend/components/Home/Dashboard/HangarPanel/index.vue";
import NotificationsPanel from "@/frontend/components/Home/Dashboard/NotificationsPanel/index.vue";
import FriendsPanel from "@/frontend/components/Home/Dashboard/FriendsPanel/index.vue";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const { currentUser } = storeToRefs(useSessionStore());
</script>

<template>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" page />
  </Teleport>

  <div class="home-dashboard__head">
    <Heading hero :size="HeadingSizeEnum.HERO_SM">
      {{
        currentUser
          ? t("home.dashboard.welcome", { name: currentUser.username })
          : t("home.dashboard.welcomeAnonymous")
      }}
    </Heading>
    <HomeSearch class="home-dashboard__search" />
  </div>

  <PatchSummary />

  <!-- Two columns from 992px. Below that both collapse into one, in the order
       a pilot acts on them: what needs an answer first. -->
  <div class="home-dashboard" data-test="home-dashboard">
    <div class="home-dashboard__main">
      <InvitesAlert class="home-dashboard__invites" />
      <ComingUpPanel class="home-dashboard__coming-up" />
      <MyFleetsPanel class="home-dashboard__fleets" />
      <PatchChangesPanel class="home-dashboard__changes" />
    </div>
    <aside class="home-dashboard__side">
      <HangarPanel class="home-dashboard__hangar" />
      <NotificationsPanel class="home-dashboard__notifications" />
      <FriendsPanel class="home-dashboard__friends" />
    </aside>
  </div>
</template>

<style lang="scss" scoped>
.home-dashboard__head {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
}

.home-dashboard__search {
  flex: 0 1 380px;
  min-width: 0;
  margin-bottom: 15px;
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

.home-dashboard__fleets {
  order: 2;
}

.home-dashboard__notifications {
  order: 3;
}

.home-dashboard__hangar {
  order: 4;
}

.home-dashboard__friends {
  order: 5;
}

.home-dashboard__changes {
  order: 6;
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

@media (max-width: 991px) {
  .home-dashboard__search {
    flex-basis: 100%;
  }
}
</style>
