<template>
  <div>
    <div class="row">
      <div class="col-12 col-md-4">
        <h2>Panel</h2>
        <Panel>
          <PanelHeading>
            <h2>Panel Heading</h2>
          </PanelHeading>
          <PanelImage :image="model.media.storeImage?.small" alt="Odyssey" />
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
          <PanelImage
            :image="model.media.storeImage?.small"
            rounded="top"
            alt="Odyssey"
          />
          <div>
            <PanelHeading>
              <h2>Panel Heading</h2>
            </PanelHeading>
            <PanelBody no-min-height>
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
            <PanelHeading>
              <h2>Panel Heading</h2>
            </PanelHeading>
            <PanelBody no-min-height>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
          <PanelImage
            :image="model.media.storeImage?.small"
            rounded="bottom"
            alt="Odyssey"
          />
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12 col-md-4">
        <h2>Panel Image Left</h2>
        <Panel align="left">
          <PanelImage
            :image="model.media.storeImage?.small"
            image-size="auto"
            rounded="left"
            alt="Odyssey"
          />
          <div>
            <PanelHeading>
              <h2>Panel Heading</h2>
            </PanelHeading>
            <PanelBody no-min-height>
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
        <Panel align="right">
          <div>
            <PanelHeading>
              <h2>Panel Heading</h2>
            </PanelHeading>
            <PanelBody no-min-height>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
          <PanelImage
            :image="model.media.storeImage?.small"
            image-size="auto"
            rounded="right"
            alt="Odyssey"
          />
        </Panel>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Model Panel</h2>
            <ModelPanel :model="internalModel" :details="modelPanelDetails" />
          </div>
          <div class="col-12 col-md-4">
            <h2>Model Panel v2</h2>
            <ModelPanel2 :model="internalModel" :details="modelPanelDetails" />
          </div>
        </div>
      </div>
      <div class="col-12">
        <Btn size="small" @click="toggleModelPanel"> Toggle </Btn>
        <Btn size="small" @click="toggleModelOnSale"> Toggle on Sale </Btn>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="row">
          <div class="col-12 col-md-4">
            <h2>Vehicle Panel</h2>
            <VehiclePanel
              :vehicle="vehicle"
              :details="vehiclePanelDetails"
              :editable="vehiclePanelEditable"
              :loaners-hint-visible="vehiclePanelLoanerHint"
            />
          </div>
          <div class="col-12 col-md-4">
            <h2>Vehicle Panel v2</h2>
            <VehiclePanel2
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
  </div>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import PanelImage from "@/shared/components/Panel/Image/index.vue";
import PanelBody from "@/shared/components/Panel/Body/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelPanel2 from "@/frontend/components/Models/Panel2/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import VehiclePanel2 from "@/frontend/components/Vehicles/Panel2/index.vue";
import { BoughtViaEnum, type Model, type Vehicle } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";

const modelPanelDetails = ref(false);

const toggleModelPanel = () => {
  modelPanelDetails.value = !modelPanelDetails.value;
};

const modelOnSale = ref(false);

const toggleModelOnSale = () => {
  modelOnSale.value = !modelOnSale.value;
};

const model = ref<Model>({
  id: "1",
  name: "Galaxy",
  slug: "galaxy",
  crew: {},
  hasImages: true,
  hasModules: true,
  hasPaints: true,
  hasUpgrades: true,
  hasVideos: true,
  links: {},
  loaners: [],
  media: {},
  metrics: {},
  onSale: modelOnSale.value,
  speeds: {},
  availability: {
    listedAt: [],
    boughtAt: [],
    rentalAt: [],
    soldAt: [],
  },
  focus: "Touring",
  manufacturer: {
    name: "Origin Jumpworks GmbH",
    slug: "origin-jumpworks-gmbh",
    createdAt: "2021-03-03T14:00:00.000Z",
    updatedAt: "2021-03-03T14:00:00.000Z",
  },
  createdAt: "2021-03-03T14:00:00.000Z",
  updatedAt: "2021-03-03T14:00:00.000Z",
});

const internalModel = computed(() => {
  return {
    ...model.value,
    onSale: modelOnSale.value,
  };
});

const { models: modelsService } = useApiClient();

const fetchModel = async () => {
  try {
    const response = await modelsService.model({
      slug: "galaxy",
    });

    model.value = response;
  } catch (error) {
    console.error(error);
  }
};

onMounted(() => {
  fetchModel();
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

const vehicle = computed<Vehicle>(() => ({
  id: "1",
  boughtVia: BoughtViaEnum.PLEDGE_STORE,
  wanted: false,
  flagship: vehiclePanelFlagship.value,
  name: "My Awesome Ship",
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
}));
</script>

<script lang="ts">
export default {
  name: "VisualTestsPanelsPage",
};
</script>
