<route lang="json">
{
  "name": "model-images"
}
</route>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredGrid from "@/shared/components/FilteredGrid/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Gallery from "@/shared/components/Gallery/index.vue";
import GalleryImage from "@/shared/components/Image/index.vue";
import { useModelQueries } from "@/frontend/composables/useModelQueries";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { type Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo(t);

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.modelImages", {
    name: props.model.name,
  });
});

const metaDescription = computed(() => {
  if (!props.model || !props.model.description) {
    return undefined;
  }

  return props.model.description;
});

const metaImage = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return props.model.media.storeImage?.large;
});

const route = useRoute();

const crumbs = computed(() => {
  if (!props.model) {
    return [];
  }

  return [
    {
      to: {
        name: "models",
        hash: `#${props.model.slug}`,
      },
      label: t("nav.models.index"),
    },
    {
      to: { name: "model", param: { slug: route.params.slug } },
      label: props.model.name,
    },
  ];
});

const { imagesQuery } = useModelQueries(route.params.slug as string);

const { data, ...asyncStatus } = imagesQuery({});

onMounted(() => {
  updateTitle();
});

watch(
  () => props.model,
  () => updateTitle,
);

const updateTitle = () => {
  if (!props.model) {
    return;
  }

  updateMetaInfo({
    title: metaTitle.value,
    description: metaDescription.value,
    image: metaImage.value,
    type: "article",
  });
};

const gallery = ref<InstanceType<typeof Gallery>>();

const openGallery = (index: number) => {
  gallery.value?.open(index);
};
</script>

<template>
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
    id="modelImages"
    name="modelImages"
    :records="data?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
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
            @click.prevent.exact="openGallery(index)"
          />
        </template>
      </FilteredGrid>
    </template>
  </FilteredList>

  <Gallery ref="gallery" :items="data?.items" />
</template>
