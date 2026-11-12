<script lang="ts">
export default {
  name: "HomeDashboardHero",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import HomeSearch from "@/frontend/components/Home/Search/index.vue";
import HomeBuildPills from "@/frontend/components/Home/BuildPills/index.vue";
import { useHangar } from "@/services/fyApi";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useSessionStore } from "@/frontend/stores/session";
import { useI18n } from "@/shared/composables/useI18n";
import {
  dashboardHangarOptions,
  dashboardHangarParams,
} from "@/frontend/components/Home/Dashboard/hangarParams";
import { usePatchChangedTag } from "@/frontend/components/Home/Dashboard/usePatchChangedTag";

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

const toVehicle = useVehicleRoute();

const { data } = useHangar(dashboardHangarParams, dashboardHangarOptions);

// Only a ship the pilot marked: the newest one is not a flagship by default.
const flagship = computed(() => {
  const first = data.value?.items[0];

  return first?.flagship ? first : undefined;
});

// Only a render: it stands on the page itself, and a store picture would bring
// a scene and need a frame.
const flagshipImage = computed(() => {
  const media = flagship.value?.model.media;

  return media?.angledViewColored?.largeUrl || media?.angledView?.largeUrl;
});

const tagFor = usePatchChangedTag();

const flagshipTag = computed(() =>
  flagship.value ? tagFor(flagship.value) : undefined,
);
</script>

<template>
  <section
    class="home-hero"
    :class="{ 'home-hero--ship': flagshipImage }"
    data-test="home-hero"
  >
    <img
      v-if="flagshipImage"
      :src="flagshipImage"
      alt=""
      class="home-hero__ship"
      aria-hidden="true"
    />

    <div class="home-hero__top">
      <HomeBuildPills />
      <HomeSearch class="home-hero__search" />
    </div>

    <div class="home-hero__bottom">
      <div class="home-hero__title">
        <span class="home-hero__eyebrow" data-test="home-dashboard-date">
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

      <router-link
        v-if="flagship"
        :to="toVehicle('hangar-vehicle', flagship)"
        class="home-hero__flagship"
        data-test="home-flagship"
      >
        <span class="home-hero__eyebrow">{{ t("labels.yourFlagship") }}</span>
        <span class="home-hero__flagship-name">
          {{ flagship.name || flagship.model.name }}
        </span>
        <span class="home-hero__flagship-sub">
          {{
            flagship.name
              ? flagship.model.name
              : flagship.model.manufacturer?.name
          }}
        </span>
        <span
          v-if="flagshipTag"
          class="home-hero__tag"
          data-test="home-flagship-tag"
        >
          {{ flagshipTag }}
        </span>
      </router-link>
    </div>
  </section>
</template>

<style lang="scss" scoped>
.home-hero {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 32px;
  margin-bottom: 20px;
  padding: 0 0 8px;
  box-sizing: border-box;

  // Room for the ship to stand in; without one the header is only its text.
  &--ship {
    min-height: 360px;
  }
}

// Behind the search, standing on the header's right.
.home-hero__ship {
  position: absolute;
  z-index: -1;
  right: 2%;
  bottom: 12%;
  width: min(62%, 760px);
  max-height: 88%;
  object-fit: contain;
  object-position: right bottom;
  filter: drop-shadow(0 12px 24px rgb(0 0 0 / 0.6));
}

.home-hero__top {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.home-hero__search {
  --home-search-tabs-room: 42px;

  flex: 0 1 480px;
  min-width: 0;
}

.home-hero__bottom {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px 24px;
}

.home-hero__title {
  display: flex;
  flex-direction: column;
  min-width: 0;
}

.home-hero__eyebrow {
  color: var(--color-text, #c8c8c8);
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-shadow: 0 1px 2px rgb(0 0 0 / 0.9);
  text-transform: uppercase;
}

.home-hero__flagship {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  min-width: 0;
  max-width: 100%;
  margin-left: auto;
  color: inherit;
  text-align: right;
  text-decoration: none;
  text-shadow: 0 1px 3px rgb(0 0 0 / 0.9);

  &:hover .home-hero__flagship-name {
    color: var(--color-primary, #428bca);
  }
}

.home-hero__flagship-name {
  max-width: 100%;
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 1.75rem;
  line-height: 1.2;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-hero__flagship-sub {
  color: var(--color-text, #c8c8c8);
  font-size: 0.8125rem;
}

.home-hero__tag {
  margin-top: 4px;
  padding: 2px 8px;
  border: 1px solid rgb(66 139 202 / 0.6);
  border-radius: 11px;
  background: rgb(26 29 33 / 0.9);
  color: #8dbbe3;
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-shadow: none;
  text-transform: uppercase;
  white-space: nowrap;
}

// On a phone the ship fades back so the greeting stays readable over it.
@media (max-width: 767px) {
  .home-hero--ship {
    min-height: 300px;
  }

  .home-hero__search {
    flex-basis: 100%;
  }

  .home-hero__ship {
    width: 90%;
    opacity: 0.5;
  }
}
</style>
