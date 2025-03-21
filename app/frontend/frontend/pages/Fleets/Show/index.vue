<template>
  <section v-if="fleet" class="container fleet-detail">
    <div class="row">
      <div class="col-12">
        <h1 class="large heading">
          <Avatar
            v-if="fleet.logo"
            :avatar="fleet.logo"
            :transparent="!!fleet.logo"
            :round="false"
            size="large"
            icon="fad fa-image"
          />
          <span class="title">{{ fleet.name }} ({{ fleet.fid }})</span>
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12 links">
        <a
          v-if="fleet.homepage"
          v-tooltip="$t('labels.homepage')"
          :href="`//${fleet.homepage}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fal fa-globe globe-rotate" />
        </a>
        <a
          v-if="fleet.rsiSid"
          v-tooltip="$t('nav.rsiProfile')"
          :href="`https://robertsspaceindustries.com/orgs/${fleet.rsiSid}`"
          target="_blank"
          rel="noopener"
        >
          <i class="icon icon-rsi icon-large" />
        </a>
        <a
          v-if="fleet.guilded"
          v-tooltip="$t('labels.guilded')"
          :href="`//${fleet.guilded}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-guilded" />
        </a>
        <a
          v-if="fleet.discord"
          v-tooltip="$t('labels.discord')"
          :href="`//${fleet.discord}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-discord" />
        </a>
        <a
          v-if="fleet.ts"
          v-tooltip="$t('labels.fleet.ts')"
          :href="fleet.ts"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-teamspeak" />
        </a>
        <a
          v-if="fleet.youtube"
          v-tooltip="$t('labels.youtube')"
          :href="`//${fleet.youtube}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-youtube" />
        </a>
        <a
          v-if="fleet.twitch"
          v-tooltip="$t('labels.twitch')"
          :href="`//${fleet.twitch}`"
          target="_blank"
          rel="noopener"
        >
          <i class="fab fa-twitch" />
        </a>
      </div>
    </div>
    <div v-if="description" class="row justify-content-md-center">
      <div class="col-12 col-sm-8">
        <p class="description" v-html="description" />
      </div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { publicFleetRouteGuard } from "@/frontend/utils/RouteGuards/Fleets";
import fleetsCollection from "@/frontend/api/collections/Fleets";
import Avatar from "@/frontend/core/components/Avatar/index.vue";

@Component<FleetDetail>({
  beforeRouteEnter: publicFleetRouteGuard,
  components: {
    Avatar,
  },
})
export default class FleetDetail extends Vue {
  get fleet() {
    return fleetsCollection.record;
  }

  get description(): string | null {
    if (!this.fleet || !this.fleet.description) {
      return null;
    }

    return this.fleet.description.replaceAll("\n", "<br>");
  }

  get metaTitle() {
    if (!this.fleet) {
      return null;
    }

    return this.fleet.name;
  }

  @Watch("$route")
  onRouteChange() {
    this.fetch();
  }

  mounted() {
    this.fetch();
  }

  async fetch() {
    if (!this.$route.params.slug) {
      return;
    }

    await fleetsCollection.findBySlug(this.$route.params.slug);
  }
}
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
