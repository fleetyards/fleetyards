<script lang="ts">
export default {
  name: "VisualTestsPanelsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import PanelImage from "@/shared/components/base/Panel/Image/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import VehiclePanel from "@/frontend/components/Vehicles/Panel/index.vue";
import { BoughtViaEnum, type Vehicle } from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  PanelAlignmentsEnum,
  PanelBgColorsEnum,
  PanelVariantsEnum,
} from "@/shared/components/base/Panel/types";
import { useModel as useModelQuery } from "@/services/fyApi";

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

const { data: model } = useModelQuery("galaxy");

const modelImage = computed(() => {
  return model.value?.media?.storeImage?.medium;
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

const vehicle = computed<Vehicle | undefined>(() => {
  if (!model.value) {
    return undefined;
  }

  return {
    id: "1",
    boughtVia: BoughtViaEnum.pledge_store,
    wanted: false,
    flagship: vehiclePanelFlagship.value,
    name: "USS Enterprise",
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

const vehicleTruncated = computed<Vehicle | undefined>(() => {
  if (!vehicle.value) {
    return undefined;
  }

  return {
    ...vehicle.value,
    name: "My Awesome Ship with a truncated name",
  };
});
</script>

<template>
  <div>
    <div class="row">
      <div class="col-12 col-md-4">
        <Panel>
          <PanelHeading :level="HeadingLevelEnum.H2">Panel</PanelHeading>
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
        <Panel>
          <PanelImage :image="modelImage" rounded="top" alt="Odyssey" />
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Image Top</PanelHeading
            >
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
        <Panel>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Image Bottom</PanelHeading
            >
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
    <div class="row">
      <div class="col-12 col-md-4">
        <Panel :alignment="PanelAlignmentsEnum.LEFT" slim>
          <PanelImage
            :image="modelImage"
            image-size="auto"
            rounded="left"
            alt="Odyssey"
          />
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Image Left</PanelHeading
            >
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
        <Panel :alignment="PanelAlignmentsEnum.RIGHT" slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Image Right</PanelHeading
            >
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
    <h2>Panel Variants</h2>
    <div class="row">
      <div class="col-12 col-md-4">
        <Panel :variant="PanelVariantsEnum.ERROR" slim>
          <PanelHeading :level="HeadingLevelEnum.H2">Panel Error</PanelHeading>
          <PanelBody no-min-height>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus
            laborum necessitatibus obcaecati exercitationem perferendis ad
            cupiditate dolorem quam autem. At qui eum temporibus ad similique
            ipsa id sed eos iure.
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :variant="PanelVariantsEnum.ERROR" animated slim>
          <PanelHeading :level="HeadingLevelEnum.H2"
            >Panel Error Animated</PanelHeading
          >
          <PanelBody no-min-height>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus
            laborum necessitatibus obcaecati exercitationem perferendis ad
            cupiditate dolorem quam autem. At qui eum temporibus ad similique
            ipsa id sed eos iure.
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :bg-color="PanelBgColorsEnum.PRIMARY" slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Primary Background</PanelHeading
            >
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
        <Panel :variant="PanelVariantsEnum.SUCCESS" slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Success</PanelHeading
            >
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
        <Panel :variant="PanelVariantsEnum.SUCCESS" animated slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Success Animated</PanelHeading
            >
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
        <Panel :variant="PanelVariantsEnum.PRIMARY" slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Primary</PanelHeading
            >
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
        <Panel highlight slim>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Highlight</PanelHeading
            >
            <PanelBody no-min-height no-padding-top>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
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
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleModelPanel"> Toggle </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleModelOnSale">
          Toggle on Sale
        </Btn>
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
          <div class="col-12 col-md-4">
            <h2>Vehicle Panel with truncated name</h2>
            <VehiclePanel
              v-if="vehicleTruncated"
              :vehicle="vehicleTruncated"
              :details="vehiclePanelDetails"
              :editable="vehiclePanelEditable"
              :loaners-hint-visible="vehiclePanelLoanerHint"
            />
          </div>
        </div>
      </div>
      <div class="col-12">
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanel">
          Toggle
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanelModelOnSale">
          Toggle on Sale: {{ vehiclePanelModelOnSale }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanelEditable">
          Toggle Edtiable: {{ vehiclePanelEditable ? "editable" : "read-only" }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanelFlagship">
          Toggle Flagship: {{ vehiclePanelFlagship }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanelLoaner">
          Toggle Loaner: {{ vehiclePanelLoaner }}
        </Btn>
        <Btn :size="BtnSizesEnum.SMALL" @click="toggleVehiclePanelLoanerHint">
          Toggle Loaner Hint: {{ vehiclePanelLoanerHint }}
        </Btn>
      </div>
    </div>
  </div>
</template>
