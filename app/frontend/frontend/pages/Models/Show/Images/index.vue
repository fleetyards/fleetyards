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
      </div>
    </div>
    <FilteredList
      :collection="collection"
      collection-method="findAllForGallery"
      name="modelImages"
      :route-query="route.query"
      :hash="route.hash"
      :params="routeParams"
      :paginated="true"
      class="images"
    >
      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :loading="loading"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record, index }">
            <GalleryImage
              :src="record.smallUrl"
              :href="record.url"
              :alt="record.name"
              :title="record.caption || record.name"
              @click.native.prevent.exact="openGallery(index)"
            />
          </template>
        </FilteredGrid>
      </template>
    </FilteredList>

    <Gallery ref="gallery" :items="collection.records" />
  </section>
</template>

<script lang="ts" setup>
import { computed, ref } from "vue";
import { useRoute, useRouter } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import BreadCrumbs from "@/frontend/core/components/BreadCrumbs/index.vue";
import Gallery from "@/frontend/core/components/Gallery/index.vue";
import GalleryImage from "@/frontend/core/components/Gallery/Image/index.vue";
import imagesCollection from "@/frontend/api/collections/Images";
import type { ImagesCollection } from "@/frontend/api/collections/Images";
import modelsCollection from "@/frontend/api/collections/Models";
import { useMetaInfo } from "@/frontend/composables/useMetaInfo";
import { modelRouteGuard } from "@/frontend/utils/RouteGuards/Models";

const collection: ImagesCollection = imagesCollection;

const model = ref<TModel | null>(null);

const { t } = useI18n();

const metaTitle = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return t("title.modelImages", {
    name: model.value.name,
  });
});

const route = useRoute();

const routeParams = computed(() => ({
  ...route.params,
  galleryType: "models",
}));

const crumbs = computed(() => {
  if (!model.value) {
    return undefined;
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

const { updateMetaInfo } = useMetaInfo();

const fetchModel = async () => {
  const response = await modelsCollection.findBySlug(route.params.slug);

  if (response.data) {
    model.value = response.data;
    updateMetaInfo(metaTitle.value);
  } else {
    router.replace({ name: "404" });
  }
};

fetchModel();

const gallery = ref<InstanceType<typeof Gallery> | null>(null);

const openGallery = (index: number) => {
  if (gallery.value) {
    gallery.value.open(index);
  }
};
</script>

<script lang="ts">
export default {
  name: "ModelImagesPage",
  beforeRouteEnter: modelRouteGuard,
};
</script>
