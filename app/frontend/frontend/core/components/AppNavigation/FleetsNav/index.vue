<template>
  <NavItem
    :label="$t('nav.fleets.index')"
    :submenu-active="active"
    menu-key="fleets-menu"
    icon="fad fa-users"
    prefix="04"
  >
    <template #submenu>
      <NavItem
        v-for="fleet in collection.records"
        :key="fleet.slug"
        :menu-key="fleet.slug"
        :to="{ name: 'fleet', params: { slug: fleet.slug } }"
        :label="fleet.name"
        :image="fleet.logo"
      />
      <NavItem
        v-if="isAuthenticated && invitesCollection.records.length"
        :to="{ name: 'fleet-invites' }"
        :label="$t('nav.fleets.invites')"
        icon="fad fa-envelope-open-text"
      />
      <NavItem
        v-if="isAuthenticated || !fleetPreview"
        :to="{ name: 'fleet-add' }"
        :label="$t('nav.fleets.add')"
        icon="fal fa-plus"
      />
      <NavItem
        v-else
        :to="{ name: 'fleet-preview' }"
        :label="$t('nav.fleets.add')"
        icon="fal fa-plus"
      />
    </template>
  </NavItem>
</template>

<script lang="ts">
import fleetsCollection from "@/frontend/api/collections/Fleets";
import fleetInvitesCollection from "@/frontend/api/collections/FleetInvites";
import NavItem from "../NavItem/index.vue";

@Component<FleetsNav>({
  components: {
    NavItem,
  },
})
export default class FleetsNav extends Vue {
  collection: FleetsCollection = fleetsCollection;

  invitesCollection: FleetInvitesCollection = fleetInvitesCollection;

  @Getter("preview", { namespace: "fleet" }) fleetPreview;

  @Getter("isAuthenticated", { namespace: "session" }) isAuthenticated;

  get active() {
    return ["fleets", "fleet-add", "fleet-preview", "fleet-invites"].includes(
      this.$route.name
    );
  }

  @Watch("$route")
  onRouteChange() {
    this.fetch();
  }

  mounted() {
    this.fetch();
  }

  async fetch() {
    if (!this.isAuthenticated) {
      return;
    }

    await this.collection.findAllForCurrent("nav");
    await this.invitesCollection.findAllForCurrent("nav");
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
