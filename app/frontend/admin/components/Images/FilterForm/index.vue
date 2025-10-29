<script lang="ts">
export default {
  name: "ImagesFilterForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import type { FilterGroupParams } from "@/shared/components/base/FilterGroup/index.vue";
import { useRoute } from "vue-router";
import { useImageFilters } from "@/admin/composables/useImageFilters";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  ImageQuery,
  Models,
  ModelQuery,
  Model,
} from "@/services/fyAdminApi";
import { models } from "@/services/fyAdminApi";

const { t } = useI18n();

const modelIdEq = ref<string | undefined>(undefined);

const stationIdEq = ref<string | undefined>(undefined);

const { filter, isFilterSelected, resetFilter } = useImageFilters();

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
  { deep: true },
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
  },
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
  },
);

const submit = () => {
  filter(form.value);
};

const modelsFormatter = (response: Models) => {
  return response.items.map((model) => {
    return {
      label: model.name,
      value: model.id,
    };
  });
};

const fetchModels = async (params: FilterGroupParams<Model>) => {
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

  return models({
    page: String(params.page || 1),
    s: ["name asc"],
    q,
  });
};
</script>

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

    <Btn :disabled="!isFilterSelected" :block="true" @click="resetFilter">
      <i class="fal fa-times" />
      {{ t("actions.resetFilter") }}
    </Btn>
  </form>
</template>
