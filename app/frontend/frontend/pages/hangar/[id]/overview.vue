<script lang="ts">
export default {
  name: "HangarVehicleOverviewPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import HangarGroups from "@/frontend/components/Vehicles/HangarGroups/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { type Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const uploaded = computed(() => props.vehicle.image);

const picture = computed(
  () =>
    uploaded.value ||
    props.vehicle.paint?.media.storeImage ||
    props.vehicle.upgrade?.media.storeImage ||
    props.vehicle.model.media.storeImage,
);

type Fact = {
  key: string;
  label: string;
  value: string;
};

const facts = computed<Fact[]>(() =>
  [
    {
      key: "name",
      label: t("labels.vehicle.name"),
      value: props.vehicle.name,
    },
    {
      key: "serial",
      label: t("labels.vehicle.serial"),
      value: props.vehicle.serial,
    },
    {
      key: "boughtVia",
      label: t("labels.vehicle.boughtViaSelect.label"),
      value: props.vehicle.boughtViaLabel,
    },
    {
      key: "paint",
      label: t("labels.vehicle.modelPaintSelect.label"),
      value: props.vehicle.paint?.name,
    },
    {
      key: "modulePackage",
      label: t("labels.model.modulePackages"),
      value: props.vehicle.modulePackage?.name,
    },
    {
      key: "upgrade",
      label: t("labels.model.upgrades"),
      value: props.vehicle.upgrade?.name,
    },
    {
      key: "bundledParent",
      label: t("labels.vehicle.bundled"),
      value: props.vehicle.bundledParent?.customName
        ? `${props.vehicle.bundledParent.customName} (${props.vehicle.bundledParent.name})`
        : props.vehicle.bundledParent?.name,
    },
  ].filter((fact): fact is Fact => !!fact.value),
);

type Setting = {
  key: string;
  label: string;
};

// What the owner decided about this ship, as opposed to what it is. Sale
// alerts are only ever sent for a ship on the wishlist, so the switch says
// nothing about one in the hangar.
const settings = computed<Setting[]>(() =>
  [
    props.vehicle.flagship && {
      key: "flagship",
      label: t("labels.vehicle.flagship"),
    },
    props.vehicle.public && {
      key: "public",
      label: props.vehicle.nameVisible
        ? t("labels.vehicle.fullPublic")
        : t("labels.vehicle.public"),
    },
    props.vehicle.wanted &&
      props.vehicle.saleNotify && {
        key: "saleNotify",
        label: t("labels.vehicleOverview.saleNotify"),
      },
    props.vehicle.loaner && {
      key: "loaner",
      label: t("labels.vehicle.loaner"),
    },
  ].filter((setting): setting is Setting => !!setting),
);

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () => import("@/frontend/components/Vehicles/Modal/index.vue"),
    props: {
      vehicle: props.vehicle,
      wishlist: props.vehicle.wanted,
    },
  });
};

const openImageModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/ImageModal/index.vue"),
    props: {
      vehicle: props.vehicle,
    },
  });
};
</script>

<template>
  <div class="vehicle-overview">
    <div class="vehicle-overview__picture">
      <ViewImage
        :image="picture"
        size="large"
        :alt="vehicle.name || vehicle.model.name"
        shadow
      />
      <Btn
        v-if="!vehicle.loaner"
        class="vehicle-overview__picture-action"
        data-test="vehicle-image-edit"
        @click="openImageModal"
      >
        <i class="fa-duotone fa-camera" />
        {{
          uploaded
            ? t("actions.vehicleOverview.changePicture")
            : t("actions.vehicleOverview.uploadPicture")
        }}
      </Btn>
    </div>

    <div class="vehicle-overview__details">
      <div class="vehicle-overview__model">
        <router-link
          :to="{ name: 'ship', params: { slug: vehicle.model.slug } }"
          class="vehicle-overview__model-name"
        >
          {{ vehicle.model.name }}
        </router-link>
        <span
          v-if="vehicle.model.manufacturer"
          class="vehicle-overview__manufacturer"
        >
          {{ vehicle.model.manufacturer.name }}
        </span>
      </div>

      <div v-if="settings.length" class="vehicle-overview__settings">
        <Pill
          v-for="setting in settings"
          :key="setting.key"
          :data-test="`vehicle-setting-${setting.key}`"
        >
          {{ setting.label }}
        </Pill>
      </div>

      <dl class="vehicle-overview__facts">
        <div
          v-for="fact in facts"
          :key="fact.key"
          class="vehicle-overview__fact"
          :data-test="`vehicle-fact-${fact.key}`"
        >
          <dt>{{ fact.label }}</dt>
          <dd>{{ fact.value }}</dd>
        </div>
        <div
          v-if="vehicle.hangarGroups.length"
          class="vehicle-overview__fact"
          data-test="vehicle-fact-hangarGroups"
        >
          <dt>{{ t("labels.vehicle.hangarGroups") }}</dt>
          <dd>
            <HangarGroups :groups="vehicle.hangarGroups" />
          </dd>
        </div>
      </dl>

      <div v-if="!vehicle.loaner" class="vehicle-overview__actions">
        <Btn data-test="vehicle-overview-edit" @click="openEditModal">
          <i class="fa fa-pencil" />
          {{ t("actions.edit") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.vehicle-overview {
  display: grid;
  grid-template-columns: minmax(0, 3fr) minmax(0, 2fr);
  gap: 30px;

  @media (max-width: $desktop-breakpoint) {
    grid-template-columns: minmax(0, 1fr);
    gap: 20px;
  }

  &__picture {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  &__picture-action {
    align-self: flex-start;
  }

  &__details {
    display: flex;
    flex-direction: column;
    gap: 15px;
  }

  &__model {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  &__model-name {
    font-size: 1.4rem;
    font-weight: 600;
  }

  &__manufacturer {
    color: var(--color-text-dim);
  }

  &__settings {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  &__facts {
    display: flex;
    flex-direction: column;
    gap: 10px;
    margin: 0;
  }

  &__fact {
    display: flex;
    flex-direction: column;
    gap: 2px;

    dt {
      font-weight: normal;
      color: var(--color-text-dim);
      font-size: 0.85rem;
    }

    dd {
      margin: 0;
    }
  }

  &__actions {
    display: flex;
    gap: 10px;
  }
}
</style>
