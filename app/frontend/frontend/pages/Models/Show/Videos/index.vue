<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <BreadCrumbs :crumbs="crumbs" />
            <h1>
              {{ metaTitle }}
            </h1>
          </div>
        </div>
        <div class="row">
          <div class="col-12">
            <Paginator
              v-if="videos.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <transition-group
          v-if="videos"
          name="fade-list"
          class="row flex-center videos"
          tag="div"
          appear
        >
          <div
            v-for="video in videos"
            :key="video.id"
            class="col-12 col-lg-6 col-lgx-3 fade-list-item"
          >
            <VideoEmbed :video="video" />
          </div>
        </transition-group>
        <div class="row">
          <div class="col-12">
            <Paginator
              v-if="videos.length"
              :page="currentPage"
              :total="totalPages"
            />
          </div>
        </div>
        <Loader :loading="loading" />
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import VideoEmbed from "@/frontend/core/components/Video/index.vue";

// data() {
//   return {
//     videos: [],
//     model: null,
//     loading: false,
//   };
// },

// computed: {
//   ...mapGetters("cookies", ["cookies"]),

//   metaTitle() {
//     if (!this.model) {
//       return null;
//     }

//     return this.$t("title.modelVideos", {
//       name: this.model.name,
//     });
//   },

//   crumbs() {
//     if (!this.model) {
//       return null;
//     }

//     return [
//       {
//         to: {
//           name: "models",
//           hash: `#${this.model.slug}`,
//         },
//         label: this.$t("nav.models.index"),
//       },
//       {
//         to: { name: "model", param: { slug: this.$route.params.slug } },
//         label: this.model.name,
//       },
//     ];
//   },
// },

// watch: {
//   $route() {
//     this.fetch();
//   },
// },

// created() {
//   this.fetchModel();
//   this.fetch();
// }

// async fetch() {
//   this.loading = true;

//   const response = await this.$api.get(
//     `models/${this.$route.params.slug}/videos`,
//     {
//       page: this.$route.query.page,
//     }
//   );

//   this.loading = false;

//   if (!response.error) {
//     this.videos = response.data;
//   }

//   this.setPages(response.meta);
// },

// async fetchModel() {
//   const response = await this.$api.get(`models/${this.$route.params.slug}`);

//   if (!response.error) {
//     this.model = response.data;
//   } else if (response.error.response.status === 404) {
//     this.$router.replace({ name: "404" });
//   }
// }
</script>

<script lang="ts">
export default {
  name: "ModelVideos",
};
</script>
