<script lang="ts">
export default {
  name: "VisualTestsNotificationsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useNotificationsStore } from "@/shared/stores/notifications";
import {
  MessageTypesEnum,
  type AppNotification,
} from "@/shared/components/AppNotifications/types";
import { type Vehicle } from "@/services/fyApi";
import { v4 as uuidv4 } from "uuid";
import sampleImage from "@/images/logo.png";

const { displayInfo, displaySuccess, displayWarning, displayAlert } =
  useAppNotifications();

const notificationsStore = useNotificationsStore();

const fireInfo = () => {
  displayInfo({ text: "This is an informational message." });
};

const fireSuccess = () => {
  displaySuccess({ text: "Operation completed successfully." });
};

const fireWarning = () => {
  displayWarning({ text: "Heads up — something needs your attention." });
};

const fireAlert = () => {
  displayAlert({ text: "Something went wrong. Please try again." });
};

const fireInfoPersistent = () => {
  displayInfo({
    text: "This message stays until you dismiss it.",
    persist: true,
    timeout: false,
  });
};

const fireInfoLong = () => {
  displayInfo({
    text: "FleetYards keeps a public roster of all known Star Citizen ships and their loadouts. The data is community-curated and updated as soon as new patches drop.",
    timeout: 8000,
  });
};

const fireWithImage = () => {
  displaySuccess({
    text: "Ship added to your hangar.",
    component: () =>
      import("@/frontend/pages/visual-tests/notifications/ImageDemo.vue"),
    componentProps: {
      title: "FleetYards",
      body: "An example notification rendering a component with an image alongside the text.",
      image: sampleImage,
    },
    timeout: 6000,
  });
};

const fireWithCta = () => {
  const notificationId = uuidv4();
  const payload: AppNotification = {
    id: notificationId,
    type: MessageTypesEnum.INFO,
    visible: true,
    persist: true,
    timeout: false,
    component: () =>
      import("@/frontend/pages/visual-tests/notifications/CtaDemo.vue"),
    componentProps: {
      title: "Action required",
      body: "An example notification with a primary call-to-action button.",
      ctaLabel: "Do the thing",
      notificationId,
    },
  };
  notificationsStore.addMessage(payload);
};

const fireVehicleAdded = () => {
  const sampleVehicle = {
    wanted: false,
    model: {
      name: "Aegis Avenger Titan",
      slug: "avenger-titan",
      media: {
        storeImage: {
          mediumUrl: sampleImage,
          smallUrl: sampleImage,
        },
      },
    },
  } as unknown as Vehicle;

  displaySuccess({
    text: "Aegis Avenger Titan added to your hangar.",
    component: () =>
      import("@/frontend/components/Models/AddToHangar/Notifications/Success/index.vue"),
    componentProps: {
      vehicle: sampleVehicle,
    },
    icon: sampleImage,
  });
};
</script>

<template>
  <Heading :level="HeadingLevelEnum.H2">Notification types</Heading>
  <p>Each button triggers a notification of the given type.</p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-info"
        @click="fireInfo"
      >
        Info
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-success"
        @click="fireSuccess"
      >
        Success
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-warning"
        @click="fireWarning"
      >
        Warning
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-alert"
        @click="fireAlert"
      >
        Alert
      </Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Variants</Heading>
  <p>Persistent notifications and long-text wrapping.</p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-persistent"
        @click="fireInfoPersistent"
      >
        Persistent Info
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-long"
        @click="fireInfoLong"
      >
        Long Info
      </Btn>
    </div>
  </div>

  <Heading :level="HeadingLevelEnum.H2">Custom components</Heading>
  <p>
    Notifications rendered via the <code>component</code> prop — image attached,
    inline CTA, or the actual add-vehicle success notification.
  </p>
  <div class="row">
    <div class="col-12">
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-image"
        @click="fireWithImage"
      >
        With image
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-cta"
        @click="fireWithCta"
      >
        With CTA
      </Btn>
      <Btn
        :size="BtnSizesEnum.SMALL"
        data-test="trigger-notification-vehicle-added"
        @click="fireVehicleAdded"
      >
        Vehicle added
      </Btn>
    </div>
  </div>
</template>
