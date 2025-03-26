<script lang="ts">
export default {
  name: "ShipImagesPage",
};
</script>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useGallery } from "@/shared/composables/useGallery";
import { useI18n } from "@/shared/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { usePagination } from "@/shared/composables/usePagination";
import { type Model } from "@/services/fyApi";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  useModelImages as useModelImagesQuery,
  getModelImagesQueryKey,
} from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { updateMetaInfo } = useMetaInfo();

const metaTitle = computed(() => {
  if (!props.model) {
    return undefined;
  }

  return t("title.shipImages", {
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
        name: "ships",
        hash: `#${props.model.slug}`,
      },
      label: t("nav.ships.index"),
    },
    {
      to: { name: "ship", param: { slug: route.params.slug } },
      label: props.model.name,
    },
  ];
});

const modelSlug = computed(() => route.params.slug as string);

const modelImagesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
  };
});

const imagesQueryKey = computed(() => {
  return getModelImagesQueryKey(modelSlug, modelImagesQueryParams);
});

const { page, perPage } = usePagination(imagesQueryKey);

const { data: images, ...asyncStatus } = useModelImagesQuery(
  modelSlug,
  modelImagesQueryParams,
);

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

useGallery(".images");
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
    :records="images?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
    class="images"
  >
    <template #default="{ records, loading, filterVisible }">
      <Grid
        :records="records"
        :loading="loading"
        :filter-visible="filterVisible"
        primary-key="id"
      >
        <template #default="{ record }">
          <LazyImage
            :src="record.bigUrl"
            :href="record.url"
            :alt="record.name"
            :width="record.width"
            :height="record.height"
            :title="record.name"
            :caption="record.caption"
            shadow
          />
        </template>
      </Grid>
    </template>
    <template #pagination-bottom>
      <Paginator v-if="images" :query-result-ref="images" :per-page="perPage" />
    </template>
  </FilteredList>
</template>
