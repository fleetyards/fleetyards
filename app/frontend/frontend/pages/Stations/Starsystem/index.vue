<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1 v-if="starsystem">
          {{ $t("headlines.starsystem", { starsystem: starsystem.name }) }}
        </h1>
      </div>
    </div>
    <div v-if="starsystem" class="row">
      <div class="col-12 col-lg-8">
        <blockquote v-if="starsystem.description" class="description">
          <p v-html="starsystem.description" />
        </blockquote>
      </div>
      <div class="col-12 col-lg-4">
        <Panel>
          <StarsystemBaseMetrics :starsystem="starsystem" padding />
          <StarsystemLevelsMetrics :starsystem="starsystem" padding />
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="celestialObjects.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="celestialObject in celestialObjects"
            :key="celestialObject.slug"
            class="col-12 fade-list-item"
          >
            <PlanetList
              :item="celestialObject"
              :route="{
                name: 'celestial-object',
                params: {
                  starsystem: celestialObject.starsystem.slug,
                  slug: celestialObject.slug,
                },
              }"
            />
          </div>
        </transition-group>
        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="celestialObjects.length"
          :page="currentPage"
          :total="totalPages"
          right
        />
      </div>
    </div>
  </section>
</template>

<script>
import Loader from "@/frontend/core/components/Loader/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import Pagination from "@/frontend/mixins/Pagination";
import { scrollToAnchor } from "@/frontend/utils/scrolling";
import PlanetList from "@/frontend/components/Planets/List/index.vue";
import StarsystemBaseMetrics from "@/frontend/components/Starsystems/BaseMetrics/index.vue";
import StarsystemLevelsMetrics from "@/frontend/components/Starsystems/LevelsMetrics/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";

export default {
  name: "StarsystemDetail",

  components: {
    Loader,
    PlanetList,
    StarsystemBaseMetrics,
    StarsystemLevelsMetrics,
    Panel,
    BreadCrumbs,
  },

  mixins: [Pagination],

  data() {
    return {
      loading: false,
      starsystem: null,
      celestialObjects: [],
    };
  },

  computed: {
    starsystemName() {
      if (this.celestialObjects.length === 0) {
        return "";
      }
      return this.celestialObjects[0].starsystem.name;
    },

    metaTitle() {
      if (!this.starsystem) {
        return null;
      }
      return this.$t("title.starsystem", { starsystem: this.starsystem.name });
    },

    crumbs() {
      if (!this.starsystem) {
        return null;
      }

      return [
        {
          to: {
            name: "starsystems",
            hash: `#${this.starsystem.slug}`,
          },
          label: this.$t("nav.starsystems"),
        },
      ];
    },
  },

  watch: {
    $route() {
      this.fetchCelestialObjects();
    },
  },

  created() {
    this.fetch();
    this.fetchCelestialObjects();
  },

  methods: {
    async fetch() {
      const response = await this.$api.get(
        `starsystems/${this.$route.params.slug}`
      );
      if (!response.error) {
        this.starsystem = response.data;
      }
    },

    async fetchCelestialObjects() {
      this.loading = true;
      const response = await this.$api.get("celestial-objects", {
        q: {
          ...this.$route.query.q,
          starsystemEq: this.$route.params.slug,
          main: true,
        },
        page: this.$route.query.page,
      });
      this.loading = false;
      if (!response.error) {
        this.celestialObjects = response.data;

        this.$nextTick(() => {
          scrollToAnchor(this.$route.hash);
        });
      }
      this.setPages(response.meta);
    },
  },
};
</script>
