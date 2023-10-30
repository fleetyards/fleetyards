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
                @click.native="toggleGrouping"
              >
                <template v-if="grouping">
                  {{ $t("actions.disableGrouping") }}
                </template>
                <template v-else>
                  {{ $t("actions.enableGrouping") }}
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
                  {{ $t("actions.hideDetails") }}
                </template>
                <template v-else>
                  {{ $t("actions.showDetails") }}
                </template>
              </Btn>
              <Btn
                size="small"
                data-test="fleetview-fleetchart-button"
                @click.native="toggleFleetchart"
              >
                <template v-if="fleetchart">
                  {{ $t("actions.hideFleetchart") }}
                </template>
                <template v-else>
                  {{ $t("actions.showFleetchart") }}
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

<script>
import { mapGetters } from "vuex";
import ModelList from "@/embed/components/Models/List/index.vue";
import FleetchartList from "@/embed/components/Fleetchart/List/index.vue";
import Loader from "@/embed/components/Loader/index.vue";
import Btn from "@/embed/components/Btn/index.vue";

export default {
  name: "FleetyardsView",

  components: {
    FleetchartList,
    ModelList,
    Loader,
    Btn,
  },

  data() {
    return {
      initialShips: [],
      users: [],
      fleetId: null,
      loading: false,
      fleetchartSlider: false,
      groupedButton: false,
      groupedModels: [],
      ungroupedModels: [],
    };
  },

  computed: {
    ...mapGetters(["details", "grouping", "fleetchart"]),

    models() {
      if (this.grouping) {
        return this.groupedModels;
      }

      return this.ungroupedModels;
    },
  },

  watch: {
    initialShips() {
      this.fetchModels();
    },

    users() {
      this.fetchHangarVehicles();
    },

    fleetId() {
      this.fetchFleetVehicles();
    },
  },

  mounted() {
    this.initialShips = this.$root.ships;
    this.users = this.$root.users;
    this.fleetId = this.$root.fleetId;
    this.fleetchartSlider = this.$root.fleetchartSlider;
    this.groupedButton = this.$root.groupedButton;

    if (this.fleetId) {
      this.fetchFleetVehicles();
    } else if (this.users) {
      this.fetchHangarVehicles();
    } else {
      this.fetchModels();
    }
  },

  methods: {
    sortByName(a, b) {
      if (a.name < b.name) {
        return -1;
      }
      if (a.name > b.name) {
        return 1;
      }
      return 0;
    },

    mapModel(item) {
      if (!item.model) {
        return null;
      }
      return item.model;
    },

    groupModels(models, item, pos) {
      const firstModel = models.find((model) => model.slug === item.slug);
      return models.indexOf(firstModel) === pos;
    },

    enhanceGroupedModel(modelSlugs, model) {
      return {
        ...model,
        count: modelSlugs.filter((slug) => slug === model.slug).length,
      };
    },

    updateShips(ships) {
      this.initialShips = ships;
    },

    updateUsers(users) {
      this.users = users;
    },

    updateFleet(fleetId) {
      this.fleetId = fleetId;
    },

    toggleDetails() {
      this.$store.commit("toggleDetails");
    },

    toggleFleetchart() {
      this.$store.commit("toggleFleetchart");
    },

    toggleGrouping() {
      this.$store.commit("toggleGrouping");
    },

    async fetchModels() {
      this.loading = true;

      const response = await this.$api.get("models/embed", {
        models: this.initialShips.filter((v, i, a) => a.indexOf(v) === i),
      });

      this.loading = false;

      if (!response.error) {
        const models = response.data;
        this.groupedModels = [...models].map((model) =>
          this.enhanceGroupedModel(this.initialShips, model),
        );
        this.ungroupedModels = this.initialShips
          .map((slug) => ({
            slug,
            model: models.find((model) => model.slug === slug),
          }))
          .map(this.mapModel)
          .filter((item) => item)
          .sort(this.sortByName);
      }
    },

    async fetchFleetVehicles() {
      if (!this.fleetId) {
        return;
      }

      this.loading = true;

      const response = await this.$api.get(`fleets/${this.fleetId}/embed`);

      this.loading = false;

      if (!response.error) {
        const models = response.data.map((vehicle) => vehicle.model);
        this.groupedModels = [...models]
          .filter((item, pos) => this.groupModels(models, item, pos))
          .map((model) =>
            this.enhanceGroupedModel(
              models.map((item) => item.slug),
              model,
            ),
          );
        this.ungroupedModels = [...models].sort(this.sortByName);
      }
    },

    async fetchHangarVehicles() {
      this.loading = true;

      const response = await this.$api.get("public/hangars/embed", {
        usernames: this.users,
      });

      this.loading = false;

      if (!response.error) {
        const models = response.data.map((vehicle) => vehicle.model);
        this.groupedModels = [...models]
          .filter((item, pos) => this.groupModels(models, item, pos))
          .map((model) =>
            this.enhanceGroupedModel(
              models.map((item) => item.slug),
              model,
            ),
          );
        this.ungroupedModels = [...models].sort(this.sortByName);
      }
    },
  },
};
</script>
