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
    id="modelVideos"
    name="modelVideos"
    :records="data?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
    class="videos"
  >
    <template #default="{ records, loading, filterVisible, primaryKey }">
      <FilteredGrid
        :records="records"
        :loading="loading"
        :filter-visible="filterVisible"
        :primary-key="primaryKey"
        grid-base="2"
      >
        <template #default="{ record }">
          <VideoEmbed :video="record" />
        </template>
      </FilteredGrid>
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredGrid from "@/shared/components/FilteredGrid/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import VideoEmbed from "@/shared/components/Video/index.vue";
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

  return t("title.modelVideos", {
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

const { videosQuery } = useModelQueries(route.params.slug as string);

const { data, ...asyncStatus } = videosQuery({});

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
</script>

<script lang="ts">
export default {
  name: "ModelVideos",
};
</script>
