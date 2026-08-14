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

import {
  PanelAlignmentsEnum,
  PanelTonesEnum,
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
  return model.value?.media?.storeImage?.mediumUrl;
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
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
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
    bundled: false,
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

// The widths the grid actually produces, down to where the outer end-caps have
// no room left at their fixed 80px inset.
const panelWidths = ["160px", "200px", "258px", "290px", "600px"];

const gridBodies = [
  { title: "Short", text: "One line." },
  {
    title: "A heading long enough to wrap onto a second line",
    text: "Accusamus laborum necessitatibus obcaecati exercitationem perferendis ad cupiditate dolorem quam autem. At qui eum temporibus ad similique ipsa id sed eos iure, quos veritatis.",
  },
  { title: "Short", text: "One line." },
];

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
          <PanelBody>
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
            <PanelBody>
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
            <PanelBody>
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
        <Panel :alignment="PanelAlignmentsEnum.LEFT">
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
            <PanelBody>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :alignment="PanelAlignmentsEnum.RIGHT">
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Image Right</PanelHeading
            >
            <PanelBody>
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
    <h2>Panel widths</h2>
    <p>
      The end-caps are inset <code>max(10px, 12%)</code>, so one pair holds 76%
      of the width at every size instead of shortening as the panel narrows —
      the old fixed 80px inset left nothing at all below 160px. These are the
      widths the grid actually produces: <code>col-3xl-2</code> and
      <code>col-lg-4</code> land near 290px, <code>col-sm-6</code> near 258px.
    </p>
    <div class="row">
      <div class="col-12">
        <div class="panel-widths">
          <div v-for="width in panelWidths" :key="width" :style="{ width }">
            <Panel>
              <PanelBody>{{ width }}</PanelBody>
            </Panel>
          </div>
        </div>
      </div>
    </div>

    <hr />
    <h2>Equal heights in a grid</h2>
    <p>
      The cards used to line up because of a 286px floor on
      <code>.panel-inner</code>, not because the grid equalises them —
      <code>base/Grid</code> is a Bootstrap row and the panel inside the column
      is not <code>height: 100%</code> on its own. The floor is gone;
      <code>fill-height</code> does the job instead, and better, since 286px was
      both too tall for a row of short panels and too short for one whose
      heading wraps. The middle panel carries extra content on purpose.
    </p>
    <div class="row">
      <div v-for="body in gridBodies" :key="body.title" class="col-12 col-md-4">
        <Panel fill-height>
          <PanelHeading :level="HeadingLevelEnum.H2">{{
            body.title
          }}</PanelHeading>
          <PanelBody>{{ body.text }}</PanelBody>
        </Panel>
      </div>
    </div>

    <hr />
    <h2>Panel Variants</h2>
    <div class="row">
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.ERROR">
          <PanelHeading :level="HeadingLevelEnum.H2">Panel Error</PanelHeading>
          <PanelBody>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus
            laborum necessitatibus obcaecati exercitationem perferendis ad
            cupiditate dolorem quam autem. At qui eum temporibus ad similique
            ipsa id sed eos iure.
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.ERROR" animated>
          <PanelHeading :level="HeadingLevelEnum.H2"
            >Panel Error Animated</PanelHeading
          >
          <PanelBody>
            Lorem ipsum dolor sit amet, consectetur adipisicing elit. Accusamus
            laborum necessitatibus obcaecati exercitationem perferendis ad
            cupiditate dolorem quam autem. At qui eum temporibus ad similique
            ipsa id sed eos iure.
          </PanelBody>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.PRIMARY">
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Primary Tone</PanelHeading
            >
            <PanelBody>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.SUCCESS">
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Success</PanelHeading
            >
            <PanelBody>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.SUCCESS" animated>
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Success Animated</PanelHeading
            >
            <PanelBody>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.PRIMARY">
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Primary</PanelHeading
            >
            <PanelBody>
              Lorem ipsum dolor sit amet, consectetur adipisicing elit.
              Accusamus laborum necessitatibus obcaecati exercitationem
              perferendis ad cupiditate dolorem quam autem. At qui eum
              temporibus ad similique ipsa id sed eos iure.
            </PanelBody>
          </div>
        </Panel>
      </div>
      <div class="col-12 col-md-4">
        <Panel :tone="PanelTonesEnum.HIGHLIGHT">
          <div>
            <PanelHeading :level="HeadingLevelEnum.H2"
              >Panel Highlight</PanelHeading
            >
            <PanelBody>
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
      <div class="col-12 vt-row">
        <Btn @click="toggleModelPanel"> Toggle </Btn>
        <Btn @click="toggleModelOnSale"> Toggle on Sale </Btn>
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
      <div class="col-12 vt-row">
        <Btn @click="toggleVehiclePanel"> Toggle </Btn>
        <Btn @click="toggleVehiclePanelModelOnSale">
          Toggle on Sale: {{ vehiclePanelModelOnSale }}
        </Btn>
        <Btn @click="toggleVehiclePanelEditable">
          Toggle Edtiable: {{ vehiclePanelEditable ? "editable" : "read-only" }}
        </Btn>
        <Btn @click="toggleVehiclePanelFlagship">
          Toggle Flagship: {{ vehiclePanelFlagship }}
        </Btn>
        <Btn @click="toggleVehiclePanelLoaner">
          Toggle Loaner: {{ vehiclePanelLoaner }}
        </Btn>
        <Btn @click="toggleVehiclePanelLoanerHint">
          Toggle Loaner Hint: {{ vehiclePanelLoanerHint }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
/* Btn ships no margins - spacing is the container's job. Matches the .vt-row on
   visual-tests/buttons.vue rather than inventing a second convention. */
.vt-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
}

.panel-widths {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 20px;
}
</style>
