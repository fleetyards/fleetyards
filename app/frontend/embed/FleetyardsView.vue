<template>
  <div id="fleetyards-view">
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12">
            <div class="page-actions page-actions-right">
              <Btn
                v-show="groupedButton"
                data-test="fleetview-grouped-button"
                size="small"
                @click="toggleGrouping"
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
                @click="toggleDetails"
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
                @click="toggleFleetchart"
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
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/embed/components/Btn/index.vue";
import FleetchartList from "@/embed/components/Fleetchart/List/index.vue";
import Loader from "@/embed/components/Loader/index.vue";
import ModelList from "@/embed/components/Models/List/index.vue";
import { useEmbedStore } from "@/embed/stores/Embed";
import { storeToRefs } from "pinia";
import { useI18n } from "@/frontend/composables/useI18n";

const { t } = useI18n();

const initialShips = ref<string[]>([]);
const users = ref<TUser[]>([]);
const fleetId = ref<string | null>(null);
const loading = ref(false);
const fleetchartSlider = ref(false);
const groupedButton = ref(false);
const groupedModels = ref<TModel[]>([]);
const ungroupedModels = ref<TModel[]>([]);

const embedStore = useEmbedStore();

const { details, fleetchart, grouping } = storeToRefs(embedStore);

const models = computed(() => {
  if (grouping.value) {
    return groupedModels.value;
  }

  return ungroupedModels.value;
});

watch(
  () => initialShips.value,
  () => {
    fetchModels();
  }
);

watch(
  () => users.value,
  () => {
    fetchHangarVehicles();
  }
);

watch(
  () => fleetId.value,
  () => {
    fetchFleetVehicles();
  }
);

onMounted(() => {
  checkStoreVersion();

  // initialShips.value = this.$root.ships;
  // users.value = this.$root.users;
  // this.fleetId = this.$root.fleetId;
  // this.fleetchartSlider = this.$root.fleetchartSlider;
  // this.groupedButton = this.$root.groupedButton;

  // if (this.fleetId) {
  //   this.fetchFleetVehicles();
  // } else if (this.users) {
  //   this.fetchHangarVehicles();
  // } else {
  //   this.fetchModels();
  // }
});

const checkStoreVersion = () => {
  if (embedStore.storeVersion !== window.STORE_VERSION) {
    console.info("Updating Store Version and resetting Store");

    embedStore.$reset();
    embedStore.storeVersion = window.STORE_VERSION;
  }
};

const sortByName = (a: TModel, b: TModel) => {
  if (a.name < b.name) {
    return -1;
  }
  if (a.name > b.name) {
    return 1;
  }
  return 0;
};

// updateShips(ships: TModel) {
//   const fleetview = (this.$children || [])[0];
//   if (fleetview) {
//     fleetview.updateShips(ships);
//   }
// },

// updateUsers(users: TUser) {
//   const fleetview = (this.$children || [])[0];
//   if (fleetview) {
//     fleetview.updateUsers(users);
//   }
// },

// updateFleet(fleetID: string) {
//   const fleetview = (this.$children || [])[0];
//   if (fleetview) {
//     fleetview.updateFleet(fleetID);
//   }
// },

const mapModel = (item: TVehicle) => {
  if (!item.model) {
    return null;
  }
  return item.model;
};

const groupModels = (models: TModel[], item: TModel, pos: number) => {
  const firstModel = models.find((model) => model.slug === item.slug);

  if (!firstModel) {
    return false;
  }

  return models.indexOf(firstModel) === pos;
};

const enhanceGroupedModel = (modelSlugs: string[], model: TModel) => {
  return {
    ...model,
    count: modelSlugs.filter((slug) => slug === model.slug).length,
  };
};

const updateShips = (ships: string[]) => {
  initialShips.value = ships;
};

const updateUsers = (newUsers: TUser[]) => {
  users.value = newUsers;
};

const updateFleet = (newFleetId: string) => {
  fleetId.value = newFleetId;
};

const toggleDetails = () => {
  embedStore.toggleDetails();
};

const toggleFleetchart = () => {
  embedStore.toggleFleetchart();
};

const toggleGrouping = () => {
  embedStore.toggleGrouping();
};

const fetchModels = async () => {
  loading.value = true;

  const response = await this.$api.get("models/embed", {
    models: initialShips.value.filter((v, i, a) => a.indexOf(v) === i),
  });

  loading.value = false;

  if (!response.error) {
    const models = response.data as TModel[];
    groupedModels.value = [...models].map((model) =>
      enhanceGroupedModel(initialShips.value, model)
    );

    ungroupedModels.value = initialShips.value
      .map((slug) => ({
        slug,
        model: models.find((model) => model.slug === slug),
      }))
      .map(mapModel)
      .filter((item) => item)
      .sort(sortByName);
  }
};

const fetchFleetVehicles = async () => {
  if (!fleetId.value) {
    return;
  }

  loading.value = true;

  const response = await this.$api.get(`fleets/${fleetId.value}/embed`);

  loading.value = false;

  if (!response.error) {
    const models = response.data.map((vehicle: TVehicle) => vehicle.model);
    groupedModels.value = [...models]
      .filter((item, pos) => groupModels(models, item, pos))
      .map((model) =>
        enhanceGroupedModel(
          models.map((item: TModel) => item.slug),
          model
        )
      );
    ungroupedModels.value = [...models].sort(sortByName);
  }
};

const fetchHangarVehicles = async () => {
  loading.value = true;

  const response = await this.$api.get("public/hangars/embed", {
    usernames: users.value,
  });

  loading.value = false;

  if (!response.error) {
    const models = response.data.map((vehicle: TVehicle) => vehicle.model);
    groupedModels.value = [...models]
      .filter((item, pos) => groupModels(models, item, pos))
      .map((model) =>
        enhanceGroupedModel(
          models.map((item: TModel) => item.slug),
          model
        )
      );
    ungroupedModels.value = [...models].sort(sortByName);
  }
};
</script>

<script lang="ts">
export default {
  name: "FleetyardsView",
};
</script>
```
