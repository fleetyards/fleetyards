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
        <FilteredList
          v-if="model"
          key="model-videos"
          :collection="collection"
          :name="route.name"
          :route-query="route.query"
          :params="{
            modelSlug: model.slug,
          }"
          :hash="route.hash"
          :paginated="true"
        >
          <template #default="{ records }">
            <transition-group
              name="fade-list"
              class="row flex-center videos"
              tag="div"
              appear
            >
              <div
                v-for="video in records"
                :key="video.id"
                class="col-12 col-lg-6 col-lgx-3 fade-list-item"
              >
                <VideoEmbed :video="video" />
              </div>
            </transition-group>
          </template>
        </FilteredList>
      </div>
    </div>
  </section>
</template>

<script lang="ts" setup>
import { ref, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import VideoEmbed from "@/frontend/core/components/Video/index.vue";
import modelVideosCollection from "@/frontend/api/collections/ModelVideos";
import modelsCollection from "@/frontend/api/collections/Models";
import { useI18n } from "@/frontend/composables/useI18n";
import { modelRouteGuard } from "@/frontend/utils/RouteGuards/Models";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";

const collection = modelVideosCollection;

const model = ref<TModel | null>(null);

const { t } = useI18n();

const metaTitle = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return t("title.modelVideos", {
    name: model.value.name,
  });
});

useMetaInfo(metaTitle);

const route = useRoute();

const crumbs = computed(() => {
  if (!model.value) {
    return null;
  }

  return [
    {
      to: {
        name: "models",
        hash: `#${model.value.slug}`,
      },
      label: t("nav.models.index"),
    },
    {
      to: { name: "model", param: { slug: route.params.slug } },
      label: model.value.name,
    },
  ];
});

const router = useRouter();

const fetchModel = async () => {
  const response = await modelsCollection.findBySlug(route.params.slug);

  if (response.data) {
    model.value = response.data;
  } else {
    router.replace({ name: "404" });
  }
};

fetchModel();
</script>

<script lang="ts">
export default {
  name: "ModelVideosPage",
  beforeRouteEnter: modelRouteGuard,
};
</script>
