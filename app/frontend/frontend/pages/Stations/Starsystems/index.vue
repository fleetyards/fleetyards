<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t("headlines.starsystems") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Panel>
          <div class="starmap">
            <img :src="mapImageUrl" alt="map" />
            <router-link
              v-for="starsystem in starsystems"
              :key="starsystem.slug"
              :to="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
              :style="{
                left: `${starsystem.mapX}%`,
                top: `${starsystem.mapY}%`,
              }"
              class="starsystem"
            />
          </div>
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="starsystems.length"
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
            v-for="starsystem in starsystems"
            :key="starsystem.slug"
            class="col-12 fade-list-item"
          >
            <StarsystemList
              :item="starsystem"
              :route="{
                name: 'starsystem',
                params: {
                  slug: starsystem.slug,
                },
              }"
            >
              <template v-if="starsystem.celestialObjects.length">
                <h3 class="sr-only">
                  {{ $t("headlines.celestialObjects") }}
                </h3>
                <transition-group name="fade-list" class="row" tag="div" appear>
                  <div
                    v-for="celestialObject in starsystem.celestialObjects"
                    :key="celestialObject.slug"
                    class="col-12 col-lg-3 fade-list-item"
                  >
                    <PlanetPanel
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
              </template>
            </StarsystemList>
          </div>
        </transition-group>
        <Loader :loading="loading" :fixed="true" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Paginator
          v-if="starsystems.length"
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
import StarsystemList from "@/frontend/components/Starsystems/List/index.vue";
import PlanetPanel from "@/frontend/components/Planets/Panel/index.vue";
import mapImageUrl from "@/images/map.png";

export default {
  name: "StarsystemsIndex",

  components: {
    Loader,
    Panel,
    StarsystemList,
    PlanetPanel,
  },

  mixins: [Pagination],

  data() {
    return {
      loading: false,
      mapImageUrl,
      starsystems: [],
    };
  },

  watch: {
    $route() {
      this.fetch();
    },
  },

  created() {
    this.fetch();
  },

  methods: {
    async fetch() {
      this.loading = true;
      const response = await this.$api.get("starsystems", {
        q: this.$route.query.q,
        page: this.$route.query.page,
      });
      this.loading = false;
      if (!response.error) {
        this.starsystems = response.data;

        this.$nextTick(() => {
          scrollToAnchor(this.$route.hash);
        });
      }
      this.setPages(response.meta);
    },
  },
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
