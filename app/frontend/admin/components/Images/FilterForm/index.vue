<template>
  <form @submit.prevent="submit">
    <FilterGroup2
      key="admin-images-filter-model"
      v-model="modelIdEq"
      :label="t('labels.filters.images.model')"
      :fetch="fetchModels"
      name="model"
      :searchable="true"
      :paginated="true"
      :no-label="true"
    />

    <FilterGroup2
      key="admin-images-filter-station"
      v-model="stationIdEq"
      :label="t('labels.filters.images.station')"
      :fetch="fetchStations"
      name="station"
      :searchable="true"
      :paginated="true"
      :no-label="true"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>

<script lang="ts" setup>
import Btn from "@/frontend/core/components/Btn/index.vue";
import FilterGroup2 from "@/frontend/core/components/Form/FilterGroup2/index.vue";
import { useRoute } from "vue-router";
import { useFilters } from "@/frontend/composables/useFilters";
import { useI18n } from "@/frontend/composables/useI18n";
import modelsCollection from "@/admin/api/collections/Models";
import stationsCollection from "@/admin/api/collections/Stations";

const { t } = useI18n();

const modelIdEq = ref<string | undefined>(undefined);

const stationIdEq = ref<string | undefined>(undefined);

const { filter, isFilterSelected, resetFilter } = useFilters();

const route = useRoute();

const query = computed(() => (route.query.q || {}) as GalleryFilters);

type GalleryFilters = {
  galleryIdEq?: string;
  galleryTypeEq?: string;
};

const form = ref<GalleryFilters>({
  galleryIdEq: query.value.galleryIdEq,
  galleryTypeEq: query.value.galleryTypeEq,
});

const setupForm = () => {
  form.value = {
    galleryIdEq: query.value.galleryIdEq,
    galleryTypeEq: query.value.galleryTypeEq,
  };
};

watch(
  () => route.query,
  () => {
    setupForm();
  },
  { deep: true }
);

watch(
  () => form.value,
  () => {
    filter(form.value);
    if (!form.value.galleryIdEq && !form.value.galleryTypeEq) {
      modelIdEq.value = undefined;
      stationIdEq.value = undefined;
    }
  },
  { deep: true }
);

watch(
  () => modelIdEq.value,
  (value) => {
    if (value) {
      stationIdEq.value = undefined;
      form.value.galleryIdEq = value;
      form.value.galleryTypeEq = "Model";
    } else if (!stationIdEq.value) {
      form.value.galleryIdEq = undefined;
      form.value.galleryTypeEq = undefined;
    }
  }
);

watch(
  () => stationIdEq.value,
  (value) => {
    if (value) {
      modelIdEq.value = undefined;
      form.value.galleryIdEq = value;
      form.value.galleryTypeEq = "Station";
    } else if (!modelIdEq.value) {
      form.value.galleryIdEq = undefined;
      form.value.galleryTypeEq = undefined;
    }
  }
);

const submit = () => {
  filter(form.value);
};

const fetchModels = async (params?: TFilterGroupParams) => {
  const filters: AdminModelsFilter = {};

  if (params?.search) {
    filters.nameCont = params.search;
  } else if (params?.missing) {
    if (Array.isArray(params.missing)) {
      filters.idIn = params.missing;
    } else {
      filters.idEq = params.missing;
    }
  }

  const data = await modelsCollection.findAll({
    filters,
    page: params?.page || 1,
  });

  if (!data) {
    return [];
  }

  return data.map((model) => ({
    label: model.name,
    value: model.id,
    icon: model.media.storeImage?.small,
  }));
};

const fetchStations = async (params?: TFilterGroupParams) => {
  const filters: AdminStationsFilter = {};

  if (params?.search) {
    filters.nameCont = params.search;
  } else if (params?.missing) {
    if (Array.isArray(params.missing)) {
      filters.idIn = params.missing;
    } else {
      filters.idEq = params.missing;
    }
  }

  const data = await stationsCollection.findAll({
    filters,
    page: params?.page || 1,
  });

  if (!data) {
    return [];
  }

  return data.map((station) => ({
    label: station.name,
    value: station.id,
    icon: station.media.storeImage?.small,
  }));
};
</script>

<script lang="ts">
export default {
  name: "ImagesFilterForm",
};
</script>
