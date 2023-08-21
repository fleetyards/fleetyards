<template>
  <form @submit.prevent="submit">
    <FilterGroup
      key="admin-images-filter-model"
      v-model="modelIdEq"
      :label="t('labels.filters.images.model')"
      :query-fn="fetchModels"
      :query-response-formatter="modelsFormatter"
      name="model"
      :searchable="true"
      :paginated="true"
      :no-label="true"
    />

    <FilterGroup
      key="admin-images-filter-station"
      v-model="stationIdEq"
      :label="t('labels.filters.images.station')"
      :query-fn="fetchStations"
      :query-response-formatter="stationsFormatter"
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
import Btn from "@/shared/components/BaseBtn/index.vue";
import FilterGroup from "@/shared/components/Form/FilterGroup/index.vue";
import type { FilterGroupParams } from "@/shared/components/Form/FilterGroup/index.vue";
import { useRoute } from "vue-router";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/admin/composables/useI18n";
import type {
  ImageQuery,
  ModelMinimal,
  ModelQuery,
  Station,
  StationQuery,
} from "@/services/fyAdminApi";
import { useApiClient } from "@/admin/composables/useApiClient";

const { t } = useI18n();

const modelIdEq = ref<string | undefined>(undefined);

const stationIdEq = ref<string | undefined>(undefined);

const { filter, isFilterSelected, resetFilter } = useFilters<ImageQuery>();

const route = useRoute();

const query = computed(() => (route.query.q || {}) as ImageQuery);

const form = ref<ImageQuery>({
  galleryIdEq: query.value.galleryIdEq,
  galleryTypeEq: query.value.galleryTypeEq,
});

const setupForm = () => {
  form.value = {
    galleryIdEq: query.value.galleryIdEq,
    galleryTypeEq: query.value.galleryTypeEq,
  };
};

onMounted(() => {
  setupForm();
});

watch(
  () => form.value,
  () => {
    filter(form.value);

    if (!form.value.galleryIdEq && !form.value.galleryTypeEq) {
      modelIdEq.value = undefined;
      stationIdEq.value = undefined;
    } else {
      if (form.value.galleryTypeEq === "Model") {
        modelIdEq.value = form.value.galleryIdEq;
      } else if (form.value.galleryTypeEq === "Station") {
        stationIdEq.value = form.value.galleryIdEq;
      }
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

const { models: modelsService, stations: stationsService } = useApiClient();

const modelsFormatter = (models: ModelMinimal[]) => {
  return models.map((model) => {
    return {
      label: model.name,
      value: model.id,
    };
  });
};

const fetchModels = async (params: FilterGroupParams) => {
  const q: ModelQuery = {};

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing) {
    if (Array.isArray(params.missing)) {
      q.idIn = params.missing as string[];
    } else {
      q.idEq = params.missing as string;
    }
  }

  return modelsService.models({
    page: String(params.page || 1),
    s: ["name asc"],
    q,
  });
};

const stationsFormatter = (stations: Station[]) => {
  return stations.map((station) => {
    return {
      label: station.name,
      value: station.id,
    };
  });
};

const fetchStations = async (params: FilterGroupParams) => {
  const q: StationQuery = {};

  if (params.search) {
    q.searchCont = params.search;
  }

  if (params.missing) {
    q.idEq = params.missing as string;
  }

  return stationsService.stations({
    page: String(params.page || 1),
    s: ["name asc"],
    q,
  });
};
</script>

<script lang="ts">
export default {
  name: "ImagesFilterForm",
};
</script>
