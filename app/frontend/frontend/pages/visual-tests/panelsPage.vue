<template>
  <div>
    <div class="row">
      <div class="col-12 col-md-4">
        <h2>Panel</h2>
        <Panel>
          <PanelHeading level="h2">Panel Heading</PanelHeading>
          <PanelImage :image="modelImage" alt="Odyssey" />
          <PanelBody no-min-height>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus
            laborum necessitatibus obcaecati exercitationem perferendis ad
            cupiditate dolorem quam autem. At qui eum temporibus ad similique
            ipsa id sed eos iure.
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <h2>Panel Image Top</h2>
        <Panel>
          <PanelImage :image="modelImage" rounded="top" alt="Odyssey" />
          <div>
            <PanelHeading level="h2">Panel Heading</PanelHeading>
            <PanelBody no-min-height no-padding-top>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <h2>Panel Image Bottom</h2>
        <Panel>
          <div>
            <PanelHeading level="h2">Panel Heading</PanelHeading>
            <PanelBody no-min-height no-padding-top>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
          <PanelImage :image="modelImage" rounded="bottom" alt="Odyssey" />
        </Panel>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12 col-md-4">
        <h2>Panel Image Left</h2>
        <Panel alignment="left" slim>
          <PanelImage
            :image="modelImage"
            image-size="auto"
            rounded="left"
            alt="Odyssey"
          />
          <div>
            <PanelHeading level="h2">Panel Heading</PanelHeading>
            <PanelBody no-min-height no-padding-top>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <h2>Panel Image Right</h2>
        <Panel alignment="right" slim>
          <div>
            <PanelHeading level="h2">Panel Heading</PanelHeading>
            <PanelBody no-min-height no-padding-top>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
          <PanelImage
            :image="modelImage"
            image-size="auto"
            rounded="right"
            alt="Odyssey"
          />
        </Panel>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Model Panel</h2>
            <ModelPanel
              v-if="internalModel"
              :model="internalModel"
              :details="modelPanelDetails"
            />
          </div>
        </div>
      </div>
      <div class="col-12">
        <Btn size="small" @click="toggleModelPanel"> Toggle </Btn>
        <Btn size="small" @click="toggleModelOnSale"> Toggle on Sale </Btn>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Vehicle Panel</h2>
            <VehiclePanel
              v-if="vehicle"
              :vehicle="vehicle"
              :details="vehiclePanelDetails"
              :editable="vehiclePanelEditable"
              :loaners-hint-visible="vehiclePanelLoanerHint"
            />
          </div>
        </div>
      </div>
      <div class="col-12">
        <Btn size="small" @click="toggleVehiclePanel"> Toggle </Btn>
        <Btn size="small" @click="toggleVehiclePanelModelOnSale">
          Toggle on Sale: {{ vehiclePanelModelOnSale }}
        </Btn>
        <Btn size="small" @click="toggleVehiclePanelEditable">
          Toggle Edtiable: {{ vehiclePanelEditable ? "editable" : "read-only" }}
        </Btn>
        <Btn size="small" @click="toggleVehiclePanelFlagship">
          Toggle Flagship: {{ vehiclePanelFlagship }}
        </Btn>
        <Btn size="small" @click="toggleVehiclePanelLoaner">
          Toggle Loaner: {{ vehiclePanelLoaner }}
        </Btn>
        <Btn size="small" @click="toggleVehiclePanelLoanerHint">
          Toggle Loaner Hint: {{ vehiclePanelLoanerHint }}
        </Btn>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Station Panel</h2>
            <StationPanel v-if="station" :station="station" />
          </div>
          <div class="col-12 col-md-8">
            <h2>Station Panel with Stats</h2>
            <StationPanel v-if="station" :station="station" with-stats />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Shop Panel</h2>
            <ShopPanel v-if="shop" :shop="shop" />
          </div>
          <div class="col-12 col-md-4">
            <h2>Shop Panel with Location</h2>
            <ShopPanel v-if="shop" :shop="shop" with-location />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Celestial Object Panel</h2>
            <CelestialObjectPanel
              v-if="celestialObject"
              :celestial-object="celestialObject"
            />
          </div>
          <div class="col-12 col-md-8">
            <h2>Celestial Object with Moons</h2>
            <CelestialObjectPanel
              v-if="celestialObject"
              :celestial-object="celestialObject"
              with-moons
            />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Starsystem Panel</h2>
            <StarsystemPanel v-if="starsystem" :starsystem="starsystem" />
          </div>
          <div class="col-12 col-md-8">
            <h2>Starsystem with main Celestial Objects</h2>
            <StarsystemPanel
              v-if="starsystem"
              :starsystem="starsystem"
              with-celestial-objects
            />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Shop Commodity Panel</h2>
            <!-- <ShopCommodityPanel :shop-commodity="shopCommodity" /> -->
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Commodity Panel</h2>
            <!-- <CommodityPanel :commodity="commodity" /> -->
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Component Panel</h2>
            <ComponentPanel
              v-if="component && component.items.length"
              :component="component.items[0]"
            />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-6">
            <h2>Equipment Panel</h2>
            <EquipmentPanel v-if="equipment" :equipment="equipment[1]" />
          </div>
        </div>
      </div>
    </div>
    <hr />
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Search Panel</h2>
            <SearchPanel v-if="searchResult" :item="searchResult[0]" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import ShopPanel from "@/frontend/components/Shops/Panel/index.vue";
import CelestialObjectPanel from "@/frontend/components/CelestialObjects/Panel/index.vue";
import StarsystemPanel from "@/frontend/components/Starsystems/Panel/index.vue";
import SearchPanel from "@/frontend/components/Search/Panel/index.vue";
import EquipmentPanel from "@/frontend/components/Equipment/Panel/index.vue";
import ComponentPanel from "@/frontend/components/Components/Panel/index.vue";
import { BoughtViaEnum } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";

const modelPanelDetails = ref(false);

const toggleModelPanel = () => {
  modelPanelDetails.value = !modelPanelDetails.value;
};

const modelOnSale = ref(false);

const toggleModelOnSale = () => {
  modelOnSale.value = !modelOnSale.value;
};

const internalModel = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return {
    ...model.value,
    onSale: modelOnSale.value,
  };
});

const {
  models: modelsService,
  shops: shopsService,
  celestialObjects: celestialObjectsService,
  stations: stationsService,
  starsystems: starsystemsService,
  search: searchService,
  equipment: equipmentService,
  components: componentsService,
} = useApiClient();

const { data: model } = useQuery({
  queryKey: ["models", "galaxy"],
  queryFn: () =>
    modelsService.model({
      slug: "galaxy",
    }),
});

const modelImage = computed(() => {
  return model.value?.media?.storeImage?.medium;
});

const { data: shop } = useQuery({
  queryKey: ["shops", "port-olisar", "casaba-outlet"],
  queryFn: () =>
    shopsService.shop({
      stationSlug: "port-olisar",
      slug: "casaba-outlet",
    }),
});

const { data: station } = useQuery({
  queryKey: ["stations", "port-olisar"],
  queryFn: () =>
    stationsService.station({
      slug: "port-olisar",
    }),
});

const { data: celestialObject } = useQuery({
  queryKey: ["celestialObjects", "crusader"],
  queryFn: () =>
    celestialObjectsService.detail({
      slug: "crusader",
    }),
});

const { data: starsystem } = useQuery({
  queryKey: ["starsystems", "stanton"],
  queryFn: () =>
    starsystemsService.starsystem({
      slug: "stanton",
    }),
});

const { data: searchResult } = useQuery({
  queryKey: ["search", "600i"],
  queryFn: () =>
    searchService.search({
      q: {
        search: "600i",
      },
    }),
});

const { data: equipment } = useQuery({
  queryKey: ["equipment", "scalpel"],
  queryFn: () =>
    equipmentService.equipment({
      q: {
        nameCont: "scalpel",
      },
    }),
});

const { data: component } = useQuery({
  queryKey: ["components"],
  queryFn: () => componentsService.components({}),
});

const vehiclePanelDetails = ref(false);

const toggleVehiclePanel = () => {
  vehiclePanelDetails.value = !vehiclePanelDetails.value;
};

const vehiclePanelEditable = ref(false);

const toggleVehiclePanelEditable = () => {
  vehiclePanelEditable.value = !vehiclePanelEditable.value;
};

const vehiclePanelFlagship = ref(false);

const toggleVehiclePanelFlagship = () => {
  vehiclePanelFlagship.value = !vehiclePanelFlagship.value;
};

const vehiclePanelLoaner = ref(false);

const toggleVehiclePanelLoaner = () => {
  vehiclePanelLoaner.value = !vehiclePanelLoaner.value;
};

const vehiclePanelLoanerHint = ref(false);

const toggleVehiclePanelLoanerHint = () => {
  vehiclePanelLoanerHint.value = !vehiclePanelLoanerHint.value;
};

const vehiclePanelModelOnSale = ref(false);

const toggleVehiclePanelModelOnSale = () => {
  vehiclePanelModelOnSale.value = !vehiclePanelModelOnSale.value;
};

const vehicle = computed(() => {
  if (!model.value) {
    return undefined;
  }

  return {
    id: "1",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
    wanted: false,
    flagship: vehiclePanelFlagship.value,
    name: "My Awesome Ship",
    serial: "L8-4261-HA",
    alternativeNames: [],
    hangarGroupIds: [],
    hangarGroups: [
      {
        id: "2bba3297-b8b7-4e54-948b-4a0734457620",
        name: "Main",
        slug: "main",
        color: "#2980B9",
        public: false,
        sort: 0,
        createdAt: "2018-12-10T13:06:42Z",
        updatedAt: "2023-05-25T20:52:49Z",
      },
      {
        id: "78285233-fd10-45b5-b572-ee09d1500696",
        name: "cc",
        slug: "cc",
        color: "#F2C511",
        public: false,
        createdAt: "2022-11-21T14:50:41Z",
        updatedAt: "2022-11-27T16:11:57Z",
      },
    ],
    loaner: vehiclePanelLoaner.value,
    modelModuleIds: [],
    modelUpgradeIds: [],
    nameVisible: false,
    public: false,
    saleNotify: false,
    model: {
      ...model.value,
      onSale: vehiclePanelModelOnSale.value,
    },
    createdAt: "2021-03-03T14:00:00.000Z",
    updatedAt: "2021-03-03T14:00:00.000Z",
  };
});
</script>

<script lang="ts">
export default {
  name: "VisualTestsPanelsPage",
};
</script>
