<script lang="ts">
export default {
  name: "AppNavigationContextSwitcher",
};
</script>

<script lang="ts" setup>
import NavMenu from "@/shared/components/AppNavigation/NavMenu/index.vue";
import NavMenuItem from "@/shared/components/AppNavigation/NavMenu/Item/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useNavContext } from "@/frontend/composables/useNavContext";
import {
  useFleet as useFleetQuery,
  usePublicFleet as usePublicFleetQuery,
  useMyFleets as useMyFleetsQuery,
  useFleetInvites as useFleetInvitesQuery,
} from "@/services/fyApi";

type Props = {
  logo: string;
  title: string;
};

defineProps<Props>();

const { t } = useI18n();

const { fleetSlug: contextSlug } = useNavContext();

const open = ref(false);

const inFleet = computed(() => !!contextSlug.value);

const fleetSlug = computed(() => contextSlug.value ?? "");

// The same queries the fleet's own navigation reads, so they share its cache.
const { data: fleet } = useFleetQuery(fleetSlug, {
  query: { retry: false, enabled: inFleet },
});

const { data: publicFleet } = usePublicFleetQuery(fleetSlug, {
  query: {
    retry: false,
    enabled: computed(() => inFleet.value && !fleet.value),
  },
});

const currentFleet = computed(() =>
  inFleet.value ? fleet.value || publicFleet.value : undefined,
);

const fleetInitials = (name: string) =>
  name
    .split(/\s+/)
    .slice(0, 2)
    .map((word) => word.charAt(0))
    .join("");

const { data: fleets } = useMyFleetsQuery({
  query: { refetchOnWindowFocus: false },
});

// Only asked for once somebody looks, the way the old fleets section did.
const { data: invites } = useFleetInvitesQuery({
  query: { enabled: open },
});
</script>

<template>
  <!-- The logo row is the switcher: it already heads the navigation, so it is
       where the reader looks to see whose things they are looking at. -->
  <NavMenu
    v-model:open="open"
    class="context-switcher"
    data-test="nav-switcher"
  >
    <template #trigger="{ slim }">
      <!-- Inside a fleet the mark is the fleet's, so the rail says whose pages
           these are even collapsed to the icon. -->
      <img
        v-if="!currentFleet || currentFleet.logo?.smallUrl"
        :src="currentFleet?.logo?.smallUrl || logo"
        class="context-switcher__logo"
        :class="{ 'context-switcher__logo--fleet': currentFleet }"
        alt=""
        data-test="nav-switcher-logo"
      />
      <span
        v-else
        class="context-switcher__logo context-switcher__initials"
        data-test="nav-switcher-logo"
      >
        {{ fleetInitials(currentFleet.name) }}
      </span>
      <span class="sr-only">{{ t("nav.switcher.label") }}:</span>
      <span
        class="context-switcher__text"
        :class="{ 'sr-only': slim }"
        data-test="nav-switcher-current"
      >
        <span class="context-switcher__title">{{ title }}</span>
        <span class="context-switcher__current">
          {{ currentFleet ? currentFleet.name : t("nav.switcher.personal") }}
        </span>
      </span>
      <i
        v-if="!slim"
        class="context-switcher__chevron fa-light fa-chevron-down"
        aria-hidden="true"
      />
    </template>

    <NavMenuItem
      :to="{ name: 'hangar' }"
      :label="t('nav.switcher.personal')"
      icon="fa-duotone fa-warehouse"
      :active="!currentFleet"
      data-test="nav-switcher-personal"
    />
    <template v-if="fleets?.length">
      <NavMenuItem heading :label="t('nav.switcher.yourFleets')" />
      <NavMenuItem
        v-for="item in fleets"
        :key="item.slug"
        :to="{ name: 'fleet', params: { slug: item.slug } }"
        :label="item.name"
        :image="item.logo?.smallUrl || undefined"
        :active="currentFleet?.slug === item.slug"
        :data-test="`nav-switcher-fleet-${item.slug}`"
      />
    </template>
    <NavMenuItem divider />
    <!-- Always there: the page also lists the requests the reader sent, which
         they may want to check with no invitation waiting. -->
    <NavMenuItem
      :to="{ name: 'fleet-invites' }"
      :label="t('nav.fleets.invites')"
      icon="fa-light fa-envelope-open-text"
      :badge="invites?.length || 0"
      data-test="nav-fleet-invites"
    />
    <NavMenuItem
      :to="{ name: 'fleet-directory' }"
      :label="t('nav.switcher.fleetDirectory')"
      icon="fa-light fa-magnifying-glass"
      data-test="nav-fleet-directory"
    />
    <NavMenuItem
      :to="{ name: 'fleet-add' }"
      :label="t('nav.fleets.add')"
      icon="fa-light fa-plus"
      data-test="nav-fleet-add"
    />
  </NavMenu>
</template>

<style lang="scss" scoped>
@import "index";
</style>
