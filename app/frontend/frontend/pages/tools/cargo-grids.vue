<script lang="ts">
export default {
  name: "ToolsCargoGridsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import CargoGridViewer, {
  computeGreedyFill,
} from "@/frontend/components/CargoGridViewer/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup, {
  type FilterGroupParams,
  type ValueType,
} from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useModel as useModelQuery,
  models as fetchModels,
  type Model,
  type ModelQuery,
  type Models,
} from "@/services/fyApi";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import type { ContainerRequest } from "@/frontend/components/CargoGridViewer/index.vue";

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const CONTAINER_SIZES = [1, 2, 4, 8, 16, 24, 32] as const;

const selectedSlug = ref<string | undefined>(
  (route.query.ship as string) || undefined,
);
const selectedModel = ref<Model>();

// Container requests: how many of each size the user wants to load
const containerRequests = ref<Record<number, number>>(
  Object.fromEntries(CONTAINER_SIZES.map((s) => [s, 0])),
);

const hasContainerRequests = computed(() =>
  Object.values(containerRequests.value).some((v) => Number(v) > 0),
);

const requestedContainers = computed<ContainerRequest[]>(() => {
  return CONTAINER_SIZES.filter(
    (s) => Number(containerRequests.value[s]) > 0,
  ).map((s) => ({
    size: s,
    quantity: Number(containerRequests.value[s]),
  }));
});

const fillGreedy = () => {
  if (!selectedModel.value?.cargoHolds?.length) return;
  const counts = computeGreedyFill(selectedModel.value.cargoHolds);
  for (const size of CONTAINER_SIZES) {
    containerRequests.value[size] = counts[size] || 0;
  }
};

const clearContainers = () => {
  for (const size of CONTAINER_SIZES) {
    containerRequests.value[size] = 0;
  }
};

// Model filter that only shows ships with cargo
const fetchCargoModels = async (params: FilterGroupParams<Model>) => {
  const q: ModelQuery = { withCargo: true };

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing && !params.search) {
    q.slugEq = params.missing as string;
  }

  return fetchModels({
    page: String(params.page || 1),
    q,
  });
};

const formatModels = (response: Models) => {
  return response.items.map((model) => ({
    label: model.name,
    value: model.slug,
    object: model,
  }));
};

const { data: modelData } = useModelQuery(
  computed(() => selectedSlug.value || ""),
  {
    query: {
      enabled: computed(() => !!selectedSlug.value),
    },
  },
);

watch(
  modelData,
  (data) => {
    if (data) {
      selectedModel.value = data;
      if (data.cargoHolds?.length) {
        fillGreedy();
      } else {
        clearContainers();
      }
    }
  },
  { immediate: true },
);

watch(selectedModel, (model) => {
  if (model?.cargoHolds?.length) {
    fillGreedy();
  } else {
    clearContainers();
  }
});

const onModelSelect = (value: ValueType<Model> | undefined) => {
  selectedSlug.value = (value as string) || undefined;
  if (!value) {
    selectedModel.value = undefined;
  }

  const query = { ...route.query };
  if (value) {
    query.ship = value as string;
  } else {
    delete query.ship;
  }
  router.replace({ query });
};
</script>

<template>
  <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <div class="row">
    <div class="col-12 col-md-4">
      <FilterGroup
        :model-value="selectedSlug"
        :label="t('labels.selectModel')"
        :search-label="t('labels.findModel')"
        :query-fn="fetchCargoModels"
        :query-response-formatter="formatModels"
        name="cargo-grid-model"
        :paginated="true"
        :searchable="true"
        :multiple="false"
        :no-label="false"
        @update:model-value="onModelSelect"
      />
    </div>
    <template v-if="selectedModel?.cargoHolds?.length">
      <div class="col-12 col-md-8">
        <div class="container-fields">
          <div
            v-for="size in CONTAINER_SIZES"
            :key="size"
            style="width: 5rem; flex-shrink: 0"
            class="container-field"
          >
            <FormInput
              v-model.number="containerRequests[size]"
              :name="`container-${size}`"
              :label="`${size} SCU`"
              :type="InputTypesEnum.NUMBER"
              :min="0"
              :step="1"
              :alignment="InputAlignmentsEnum.RIGHT"
            />
          </div>
          <div class="container-fields__actions">
            <Btn
              v-if="hasContainerRequests"
              :size="BtnSizesEnum.SMALL"
              inline
              @click="clearContainers"
            >
              {{ t("actions.clear") }}
            </Btn>
            <Btn :size="BtnSizesEnum.SMALL" inline @click="fillGreedy">
              {{ t("actions.reset") }}
            </Btn>
          </div>
        </div>
      </div>
    </template>
  </div>

  <template v-if="selectedModel">
    <div v-if="selectedModel.cargoHolds?.length">
      <div class="row">
        <div class="col-12">
          <CargoGridViewer
            :cargo-holds="selectedModel.cargoHolds"
            :container-requests="requestedContainers"
          />
        </div>
      </div>
    </div>
    <div v-else class="row mt-3">
      <div class="col-12">
        <p>{{ t("messages.cargoGridViewer.noCargoHolds") }}</p>
      </div>
    </div>
  </template>
</template>

<style lang="scss" scoped>
@import "./cargo-grids.scss";
</style>
