<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <div class="page-actions page-actions-right">
            <Btn
              v-show="groupedButton"
              data-test="fleetview-grouped-button"
              size="small"
              @click.native="toggleGrouping"
            >
              <template v-if="grouping">
                {{ t("actions.disableGrouping") }}
              </template>
              <template v-else>
                {{ t("actions.enableGrouping") }}
              </template>
            </Btn>
            <Btn
              v-show="!fleetchart"
              :active="details"
              data-test="fleetview-details-button"
              size="small"
              @click.native="toggleDetails"
            >
              <template v-if="details">
                {{ t("actions.hideDetails") }}
              </template>
              <template v-else>
                {{ t("actions.showDetails") }}
              </template>
            </Btn>
            <Btn
              size="small"
              data-test="fleetview-fleetchart-button"
              @click.native="toggleFleetchart"
            >
              <template v-if="fleetchart">
                {{ t("actions.hideFleetchart") }}
              </template>
              <template v-else>
                {{ t("actions.showFleetchart") }}
              </template>
            </Btn>
          </div>
        </div>
      </div>
      <FleetchartList
        v-if="fleetchart"
        :models="models"
        :slider="fleetchartSlider"
      />
      <ModelList v-else :models="models" />
      <Loader :loading="loading" :fixed="true" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import ModelList from "@/embed/components/Models/List/index.vue";
import FleetchartList from "@/embed/components/Fleetchart/List/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Btn from "@/shared/components/BaseBtn/index.vue";
import { useEmbedStore } from "@/embed/stores/embed";
import { storeToRefs } from "pinia";
import { useApiClient } from "@/embed/composables/useApiClient";
import type { Model } from "@/services/fyApi";
import { useI18n } from "@/embed/composables/useI18n";

export interface EnhancedModelMinimal extends Model {
  count: number;
}

const { t } = useI18n();

const { models: modelsService, publicHangar: hangarService } = useApiClient();

type Props = {
  ships?: string[];
  users?: string[];
  fleetId?: string;
  fleetchartSlider?: boolean;
  groupedButton?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  ships: () => [],
  users: () => [],
  fleetId: undefined,
  fleetchartSlider: false,
  groupedButton: false,
});

const loading = ref<boolean>(false);
const groupedModels = ref<EnhancedModelMinimal[]>([]);
const ungroupedModels = ref<Model[]>([]);

const embedStore = useEmbedStore();
const { details, fleetchart, grouping } = storeToRefs(embedStore);

const models = computed(() => {
  if (grouping.value) {
    return groupedModels.value;
  }

  return ungroupedModels.value;
});

watch(
  () => props.ships,
  () => {
    fetchModels();
  }
);

watch(
  () => props.users,
  () => {
    fetchHangarVehicles();
  }
);

watch(
  () => props.fleetId,
  () => {
    fetchFleetVehicles();
  }
);

onMounted(() => {
  if (props.fleetId) {
    fetchFleetVehicles();
  } else if (props.users?.length) {
    fetchHangarVehicles();
  } else {
    fetchModels();
  }
});

const sortByName = (a?: Model, b?: Model) => {
  if (!a || !b) {
    return 0;
  }

  if (a.name < b.name) {
    return -1;
  }

  if (a.name > b.name) {
    return 1;
  }

  return 0;
};

const groupModels = (models: Model[], item: Model, pos: number) => {
  const firstModel = models.find((model) => model.slug === item.slug);

  if (!firstModel) {
    return false;
  }

  return models.indexOf(firstModel) === pos;
};

const enhanceGroupedModel = (
  modelSlugs: string[],
  model: Model
): EnhancedModelMinimal => ({
  ...model,
  count: modelSlugs.filter((slug) => slug === model.slug).length,
});

const toggleDetails = () => {
  embedStore.details = !embedStore.details;
};

const toggleFleetchart = () => {
  embedStore.fleetchart = !embedStore.fleetchart;
};

const toggleGrouping = () => {
  embedStore.grouping = !embedStore.grouping;
};

const fetchModels = async () => {
  loading.value = true;

  try {
    const models = await modelsService.embed({
      models: props.ships?.filter((v, i, a) => a.indexOf(v) === i),
    });

    groupedModels.value = [...models].map((model) =>
      enhanceGroupedModel(props.ships || [], model)
    );

    ungroupedModels.value = props.ships
      ?.map((slug) => models.find((model: Model) => model.slug === slug))
      .filter((item) => item)
      .sort(sortByName) as Model[];
  } catch (error) {
    console.error(error);
  }

  loading.value = false;
};

const fetchFleetVehicles = async () => {
  // if (!props.fleetId) {
  //   return;
  // }
  // loading.value = true;
  // const response = await this.$api.get(`fleets/${props.fleetId}/embed`);
  // loading.value = false;
  // if (!response.error) {
  //   const models = response.data.map((vehicle: Vehicle) => vehicle.model);
  //   groupedModels.value = [...models]
  //     .filter((item, pos) => groupModels(models, item, pos))
  //     .map((model) =>
  //       enhanceGroupedModel(
  //         models.map((item: Model) => item.slug),
  //         model
  //       )
  //     );
  //   ungroupedModels.value = [...models].sort(sortByName);
  // }
};

const fetchHangarVehicles = async () => {
  loading.value = true;

  try {
    const vehicles = await hangarService.publicHangarEmbed({
      usernames: props.users,
    });

    const models = vehicles.map((vehicle) => vehicle.model);

    groupedModels.value = [...models]
      .filter((item, pos) => groupModels(models, item, pos))
      .map((model) =>
        enhanceGroupedModel(
          models.map((item: Model) => item.slug),
          model
        )
      );
    ungroupedModels.value = [...models].sort(sortByName);
  } catch (error) {
    console.error(error);
  }

  loading.value = false;
};
</script>

<script lang="ts">
export default {
  name: "HomePage",
};
</script>
