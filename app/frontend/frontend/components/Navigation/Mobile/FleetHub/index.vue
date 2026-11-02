<script lang="ts">
export default {
  name: "FrontendNavigationMobileFleetHub",
};
</script>

<script lang="ts" setup>
import type { RouteLocationNamedRaw } from "vue-router";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { type Glyph, isGlyph } from "@/shared/components/DuotoneGlyph/glyph";
import { SHIP_GLYPH } from "@/shared/glyphs/ships";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetNavAccess } from "@/frontend/composables/useFleetNavAccess";
import { fleetInitials } from "@/frontend/utils/fleetInitials";
import { useMyFleets as useMyFleetsQuery, type Fleet } from "@/services/fyApi";

type HubFleet = Pick<
  Fleet,
  | "slug"
  | "name"
  | "logo"
  | "features"
  | "publicFleet"
  | "publicFleetStats"
  | "squadronsEnabled"
>;

type Props = {
  fleet: HubFleet;
};

const props = defineProps<Props>();

const open = defineModel<boolean>("open", { required: true });

const { t } = useI18n();

const route = useRoute();

const switching = ref(false);

const {
  membership,
  showShipsNav,
  shipsNavActive,
  showSquadronsNav,
  squadronsNavActive,
  showBlueprintsNav,
  blueprintsNavActive,
  showLogisticsNav,
  logisticsNavActive,
  showShoppingListsNav,
  shoppingListsNavActive,
  showContractsNav,
  contractsNavActive,
  showEventsNav,
  eventsNavRoute,
  eventsNavActive,
} = useFleetNavAccess(() => props.fleet);

type Tile = {
  key: string;
  to: RouteLocationNamedRaw;
  label: string;
  icon: string | Glyph;
  active: boolean;
};

const routeName = computed(() => String(route.name));

// The same sections, in the same order, as the fleet's desktop navigation.
const tiles = computed<Tile[]>(() => {
  const params = { slug: props.fleet.slug };

  const all: (Tile | false)[] = [
    {
      key: "overview",
      to: { name: "fleet", params },
      label: t("nav.fleets.overview"),
      icon: "fa-duotone fa-home-alt",
      active: routeName.value === "fleet",
    },
    showShipsNav.value && {
      key: "ships",
      to: { name: "fleet-ships", params },
      label: t("nav.fleets.ships"),
      icon: SHIP_GLYPH,
      active: shipsNavActive.value,
    },
    !!membership.value && {
      key: "members",
      to: { name: "fleet-members", params },
      label: t("nav.fleets.members.index"),
      icon: "fa-duotone fa-users",
      active: routeName.value.startsWith("fleet-members"),
    },
    showSquadronsNav.value && {
      key: "squadrons",
      to: { name: "fleet-squadrons", params },
      label: t("nav.fleets.squadrons.index"),
      icon: "fa-duotone fa-shield-halved",
      active: squadronsNavActive.value,
    },
    showBlueprintsNav.value && {
      key: "blueprints",
      to: { name: "fleet-blueprints", params },
      label: t("nav.fleets.blueprints"),
      icon: "fa-duotone fa-notes",
      active: blueprintsNavActive.value,
    },
    showLogisticsNav.value && {
      key: "logistics",
      to: { name: "fleet-logistics", params },
      label: t("nav.fleets.logistics.index"),
      icon: "fa-duotone fa-boxes-stacked",
      active: logisticsNavActive.value,
    },
    showShoppingListsNav.value && {
      key: "shopping-lists",
      to: { name: "fleet-shopping-lists", params },
      label: t("nav.fleets.shoppingLists"),
      icon: "fa-duotone fa-cart-shopping",
      active: shoppingListsNavActive.value,
    },
    showContractsNav.value && {
      key: "contracts",
      to: { name: "fleet-contracts", params },
      label: t("nav.fleets.contracts.index"),
      icon: "fa-duotone fa-clipboard-list",
      active: contractsNavActive.value,
    },
    showEventsNav.value &&
      !!eventsNavRoute.value && {
        key: "events",
        to: { name: eventsNavRoute.value, params },
        label:
          eventsNavRoute.value === "fleet-missions"
            ? t("nav.fleets.missions.index")
            : t("nav.fleets.events.index"),
        icon:
          eventsNavRoute.value === "fleet-missions"
            ? "fa-duotone fa-flag-checkered"
            : "fa-duotone fa-calendar-day",
        active: eventsNavActive.value,
      },
    (!!props.fleet.publicFleetStats || !!membership.value) && {
      key: "stats",
      to: { name: "fleet-stats", params },
      label: t("nav.fleets.stats"),
      icon: "fa-duotone fa-chart-bar",
      active: routeName.value === "fleet-stats",
    },
    !!membership.value && {
      key: "settings",
      to: { name: "fleet-settings", params },
      label: t("nav.fleets.settings.index"),
      icon: "fa-duotone fa-cogs",
      active: routeName.value.startsWith("fleet-settings"),
    },
  ];

  return all.filter((tile): tile is Tile => !!tile);
});

const { data: myFleets } = useMyFleetsQuery({
  query: { refetchOnWindowFocus: false, enabled: open },
});

const close = () => {
  open.value = false;
};

watch(open, (value) => {
  if (!value) {
    switching.value = false;
  }
});

watch(
  () => route.path,
  () => close(),
);

const onKeydown = (event: KeyboardEvent) => {
  if (event.key === "Escape") {
    close();
  }
};

watch(open, (value) => {
  const method = value ? "addEventListener" : "removeEventListener";

  document[method]("keydown", onKeydown as EventListener);
});

onBeforeUnmount(() => {
  document.removeEventListener("keydown", onKeydown);
});
</script>

<template>
  <Transition name="fleet-hub">
    <div v-if="open" class="fleet-hub" data-test="fleet-hub">
      <div class="fleet-hub__scrim" aria-hidden="true" @click="close" />
      <div
        id="fleet-hub-sheet"
        class="fleet-hub__sheet"
        role="dialog"
        :aria-label="fleet.name"
      >
        <div class="fleet-hub__header">
          <h2 class="fleet-hub__title">{{ fleet.name }}</h2>
          <button
            type="button"
            class="fleet-hub__switch"
            data-test="fleet-hub-switch"
            :aria-pressed="switching"
            @click="switching = !switching"
          >
            <i
              :class="
                switching
                  ? 'fa-light fa-chevron-left'
                  : 'fa-light fa-arrow-right-arrow-left'
              "
              aria-hidden="true"
            />
            {{ switching ? t("nav.back") : t("nav.switcher.switch") }}
          </button>
        </div>

        <ul v-if="!switching" class="fleet-hub__grid">
          <li v-for="tile in tiles" :key="tile.key">
            <router-link
              :to="tile.to"
              class="fleet-hub__tile"
              :class="{ 'fleet-hub__tile--active': tile.active }"
              :aria-current="tile.active ? 'page' : undefined"
              :data-test="`fleet-hub-${tile.key}`"
            >
              <DuotoneGlyph
                v-if="isGlyph(tile.icon)"
                :glyph="tile.icon"
                class="fleet-hub__icon"
              />
              <i
                v-else
                :class="tile.icon"
                class="fleet-hub__icon"
                aria-hidden="true"
              />
              <span class="fleet-hub__label">{{ tile.label }}</span>
            </router-link>
          </li>
        </ul>

        <ul v-else class="fleet-hub__list" data-test="fleet-hub-switcher">
          <li>
            <router-link :to="{ name: 'hangar' }" class="fleet-hub__row">
              <i class="fa-duotone fa-warehouse" aria-hidden="true" />
              {{ t("nav.switcher.personal") }}
            </router-link>
          </li>
          <li v-if="myFleets?.length" class="fleet-hub__heading">
            {{ t("nav.switcher.yourFleets") }}
          </li>
          <li v-for="item in myFleets" :key="item.slug">
            <router-link
              :to="{ name: 'fleet', params: { slug: item.slug } }"
              class="fleet-hub__row"
              :class="{
                'fleet-hub__row--active': item.slug === fleet.slug,
              }"
              :aria-current="item.slug === fleet.slug ? 'true' : undefined"
            >
              <img
                v-if="item.logo?.smallUrl"
                :src="item.logo.smallUrl"
                alt=""
                class="fleet-hub__logo"
              />
              <span v-else class="fleet-hub__logo" aria-hidden="true">
                {{ fleetInitials(item.name) }}
              </span>
              {{ item.name }}
            </router-link>
          </li>
          <li>
            <router-link
              :to="{ name: 'fleet-directory' }"
              class="fleet-hub__row fleet-hub__row--bare"
            >
              <i class="fa-light fa-magnifying-glass" aria-hidden="true" />
              {{ t("nav.switcher.fleetDirectory") }}
            </router-link>
          </li>
          <li>
            <router-link
              :to="{ name: 'fleet-add' }"
              class="fleet-hub__row fleet-hub__row--bare"
            >
              <i class="fa-light fa-plus" aria-hidden="true" />
              {{ t("nav.fleets.add") }}
            </router-link>
          </li>
        </ul>
      </div>
    </div>
  </Transition>
</template>

<style lang="scss" scoped>
@import "index";
</style>
