<template>
  <div v-if="currentFleet">
    <NavItem
      :to="{ name: 'home' }"
      :label="$t('nav.back')"
      icon="fal fa-chevron-left"
      :exact="true"
    />
    <NavItem
      :to="{ name: 'fleet', params: { slug: currentFleet.slug } }"
      :label="currentFleet.name"
      :image="currentFleet.logo"
      :active="$route.name === 'fleet'"
      prefix="00"
      :exact="true"
    />
    <NavItem
      v-if="currentFleet.publicFleet || currentFleet.myFleet"
      :to="{ name: 'fleet-ships', params: { slug: currentFleet.slug } }"
      :label="$t('nav.fleets.ships')"
      :active="shipsNavActive"
      prefix="01"
      icon="fad fa-starship"
    />
    <template v-if="currentFleet.myFleet">
      <NavItem
        :to="{ name: 'fleet-members', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.members')"
        :active="$route.name === 'fleet-members'"
        icon="fad fa-users"
        prefix="02"
      />
      <NavItem
        :to="{ name: 'fleet-stats', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.stats')"
        :active="$route.name === 'fleet-stats'"
        icon="fad fa-chart-bar"
        prefix="03"
      />
      <NavItem
        :to="{ name: 'fleet-settings', params: { slug: currentFleet.slug } }"
        :label="$t('nav.fleets.settings.index')"
        :active="$route.name === 'fleet-settings'"
        icon="fad fa-cogs"
        prefix="04"
      />
    </template>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component } from "vue-property-decorator";
import NavItem from "@/frontend/core/components/Navigation/NavItem/index.vue";
import fleetsCollection from "@/frontend/api/collections/Fleets";

@Component<FleetNav>({
  components: {
    NavItem,
  },
})
export default class FleetNav extends Vue {
  collection: FleetsCollection = fleetsCollection;

  get currentFleet(): Fleet | null {
    return this.collection.record;
  }

  get shipsNavActive() {
    return ["fleet-ships", "fleet-fleetchart"].includes(this.$route.name);
  }

  mounted() {
    this.fetch();
    this.$comlink.$on("fleet-update", this.fetch);
  }

  async fetch() {
    await this.collection.findBySlug(this.$route.params.slug);
  }
}
</script>
