<script lang="ts">
export default {
  name: "HomeDashboard",
};
</script>

<script lang="ts" setup>
import RaffleDashboardPanel from "@/frontend/components/Raffles/DashboardPanel/index.vue";
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import SupportBtn from "@/frontend/components/SupportBtn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
import HomeBuildPills from "@/frontend/components/Home/BuildPills/index.vue";
import HomeFlagship from "@/frontend/components/Home/Dashboard/Flagship/index.vue";
import DashboardTiles from "@/frontend/components/Home/Dashboard/Tiles/index.vue";
import InvitesAlert from "@/frontend/components/Home/Dashboard/InvitesAlert/index.vue";
import ComingUpPanel from "@/frontend/components/Home/Dashboard/ComingUpPanel/index.vue";
import ShipsPanel from "@/frontend/components/Home/Dashboard/ShipsPanel/index.vue";
import WishlistPanel from "@/frontend/components/Home/Dashboard/WishlistPanel/index.vue";
import NewShipsPanel from "@/frontend/components/Home/Dashboard/NewShipsPanel/index.vue";
import FleetPanel from "@/frontend/components/Home/Dashboard/FleetPanel/index.vue";
import PlanPanel from "@/frontend/components/Home/Dashboard/PlanPanel/index.vue";
import NotificationsPanel from "@/frontend/components/Home/Dashboard/NotificationsPanel/index.vue";
import FriendsPanel from "@/frontend/components/Home/Dashboard/FriendsPanel/index.vue";
import { FeatureFlagName } from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";

const { t, currentLocale } = useI18n();

// The 'verse runs 930 years ahead of us.
const IN_GAME_YEAR_OFFSET = 930;

// Today in the reader's language, in the game's calendar.
const today = computed(() =>
  new Intl.DateTimeFormat(currentLocale(), {
    weekday: "long",
    day: "numeric",
    month: "long",
    year: "numeric",
  })
    .formatToParts(new Date())
    .map((part) =>
      part.type === "year"
        ? String(Number(part.value) + IN_GAME_YEAR_OFFSET)
        : part.value,
    )
    .join(""),
);

const { currentUser } = storeToRefs(useSessionStore());

const { isFeatureEnabled } = useFeatures();
</script>

<template>
  <Teleport to="#header-right">
    <SupportBtn :size="BtnSizesEnum.MD" />
  </Teleport>

  <div class="home-dashboard__head">
    <div class="home-dashboard__title">
      <HomeBuildPills />
      <span class="home-dashboard__date" data-test="home-dashboard-date">
        {{ today }}
      </span>
      <Heading hero :size="HeadingSizeEnum.HERO_SM">
        {{
          currentUser
            ? t("home.dashboard.welcome", { name: currentUser.username })
            : t("home.dashboard.welcomeAnonymous")
        }}
      </Heading>
    </div>
    <HomeSearch class="home-dashboard__search" />
  </div>

  <DashboardTiles class="home-dashboard__tiles" />

  <!-- Two columns from 992px. Below that both collapse into one, in the order
       a pilot acts on them: what needs an answer first. -->
  <div class="home-dashboard" data-test="home-dashboard">
    <div class="home-dashboard__main">
      <InvitesAlert class="home-dashboard__invites" />
      <ComingUpPanel class="home-dashboard__coming-up" />
      <ShipsPanel class="home-dashboard__ships" />
      <WishlistPanel class="home-dashboard__wishlist" />
      <NewShipsPanel class="home-dashboard__new-ships" />
    </div>
    <aside class="home-dashboard__side">
      <HomeFlagship class="home-dashboard__flagship" />
      <FleetPanel class="home-dashboard__fleet" />
      <RaffleDashboardPanel class="home-dashboard__raffle" />
      <PlanPanel
        v-if="isFeatureEnabled(FeatureFlagName.HANGAR_PLANNER)"
        class="home-dashboard__plan"
      />
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

.home-dashboard__title {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  min-width: 0;
}

.home-dashboard__date {
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.home-dashboard__tiles {
  margin-bottom: 20px;
}

.home-dashboard__search {
  --home-search-tabs-room: 42px;

  flex: 0 1 600px;
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

.home-dashboard__ships {
  order: 2;
}

.home-dashboard__wishlist {
  order: 3;
}

.home-dashboard__flagship {
  order: 4;
  margin-bottom: 16px;
}

.home-dashboard__fleet {
  order: 5;
}

.home-dashboard__raffle {
  order: 6;
}

.home-dashboard__plan {
  order: 7;
}

.home-dashboard__notifications {
  order: 8;
}

.home-dashboard__friends {
  order: 9;
}

.home-dashboard__new-ships {
  order: 10;
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
