<script lang="ts">
export default {
  name: "VehicleHero",
};
</script>

<script lang="ts" setup>
import { VehicleEditTabsEnum } from "@/frontend/components/Vehicles/EditModal/types";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import LocationName from "@/frontend/components/LocationName/index.vue";
import VehicleContextMenu from "@/frontend/components/Vehicles/ContextMenu/index.vue";
import Specs from "@/frontend/components/Vehicles/Overview/Specs/index.vue";
import { useVehicleViewStore } from "@/frontend/stores/vehicleView";
import {
  ModelStateEnum,
  modelStateHolo,
  modelStateMetrics,
} from "@/frontend/composables/useModelStates";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";
import { isLowPowerDevice } from "@/shared/composables/useLowPowerDevice";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useVehicleCargo } from "@/frontend/composables/useVehicleCargo";
import type { Vehicle } from "@/services/fyApi";

type Props = {
  vehicle: Vehicle;
  // The slim banner the other tabs show. The header animates between the two
  // in place, so switching tabs shrinks the picture rather than swapping it.
  compact?: boolean;
};

// Loaded on demand: three.js is the heaviest thing the page could carry, and
// most visits show the picture.
const HoloViewer = defineAsyncComponent(
  () => import("@/shared/components/HoloViewer/index.vue"),
);

const props = withDefaults(defineProps<Props>(), {
  compact: false,
});

const { t, l } = useI18n();
const comlink = useComlink();
const mobile = useMobile();
const { displayAlert } = useAppNotifications();

const { useUpdateMutation } = useVehicleMutations();

const updateMutation = useUpdateMutation(computed(() => props.vehicle));

// The one setting a wishlist ship has, switched where it is shown.
const toggleSaleNotify = async () => {
  await updateMutation
    .mutateAsync({
      id: props.vehicle.id,
      data: { saleNotify: !props.vehicle.saleNotify },
    })
    .catch(() => {
      displayAlert({ text: t("messages.vehicleOverview.setting.failure") });
    });
};

// The owner's picture first -- uploaded, then picked from the model's
// gallery -- then the render the ship is wearing, then the
// model's own.
const picture = computed(
  () =>
    props.vehicle.image ||
    props.vehicle.upgrade?.media.storeImage ||
    props.vehicle.model.media.storeImage,
);

const pictureUrl = computed(
  () =>
    picture.value?.xlargeUrl || picture.value?.largeUrl || picture.value?.url,
);

const title = computed(() => props.vehicle.name || props.vehicle.model.name);

// Decided once, as on the ship page: a resize should not swap the file.
const preferLiteHolo = isLowPowerDevice();

// The ship in flight, the way the ship page opens it.
const holoModel = computed(() => {
  const holo = modelStateHolo(props.vehicle.model, ModelStateEnum.FLIGHT, {
    lite: preferLiteHolo,
  });
  const path = holo?.url;
  const length = modelStateMetrics(
    props.vehicle.model,
    ModelStateEnum.FLIGHT,
  ).fleetchartLength;

  if (!path || !length) return undefined;

  return { path, length, size: holo?.size };
});

const { cargoLabel } = useVehicleCargo();

// Remembered per vehicle, apart from the ship page's switch.
const vehicleViewStore = useVehicleViewStore();

const holoVisible = computed(
  () =>
    vehicleViewStore.holoVisible(props.vehicle.id) &&
    !!holoModel.value &&
    !props.compact,
);

// Over this page rather than on the ship's viewer page, so closing it lands
// back on the vehicle.
const openFullscreenHolo = () => {
  if (!holoModel.value) return;

  comlink.emit("open-modal", {
    component: () => import("@/shared/components/HoloViewer/Modal/index.vue"),
    fullscreen: true,
    props: { models: [holoModel.value] },
  });
};

const { openEditModal: openVehicleEdit } = useVehicleModals();

const activeLoadout = computed(() => props.vehicle.activeLoadout);

const vehicleRoute = useVehicleRoute();

// A fleetyards loadout has a page of its own; a linked build lives on the site
// it links to.
const activeLoadoutPage = computed(() =>
  activeLoadout.value && !activeLoadout.value.url
    ? vehicleRoute("hangar-vehicle-loadout", props.vehicle, {
        loadout: activeLoadout.value.id,
      })
    : undefined,
);

const openImageModal = () =>
  openVehicleEdit(props.vehicle, { tab: VehicleEditTabsEnum.IMAGE });
</script>

<template>
  <section
    class="vehicle-hero"
    :class="{ 'vehicle-hero--compact': compact }"
    :aria-label="title"
    data-test="vehicle-hero"
  >
    <div class="vehicle-hero__stage">
      <HoloViewer
        v-if="holoVisible && holoModel"
        :key="holoModel.path"
        :models="[holoModel]"
        class="vehicle-hero__holo"
      />
      <img
        v-else-if="pictureUrl"
        :src="pictureUrl"
        :alt="title"
        class="vehicle-hero__image"
      />

      <div class="vehicle-hero__top">
        <span v-if="vehicle.imageUploaded" class="vehicle-hero__own-picture">
          <i class="fa-duotone fa-camera" />
          {{ t("labels.vehicleOverview.ownPicture") }}
        </span>
        <span v-else />
        <div v-if="!vehicle.loaner" class="vehicle-hero__actions">
          <Btn
            v-if="!vehicle.wanted"
            data-test="vehicle-image-edit"
            @click="openImageModal"
          >
            <i class="fa-duotone fa-camera" />
            <span class="vehicle-hero__action-label">
              {{
                vehicle.image
                  ? t("actions.vehicleOverview.changePicture")
                  : t("actions.vehicleOverview.uploadPicture")
              }}
            </span>
          </Btn>
          <VehicleContextMenu
            :vehicle="vehicle"
            :wishlist="vehicle.wanted"
            editable
            on-vehicle-page
            :hide-ship-page="!compact && !mobile"
          />
        </div>
      </div>

      <div class="vehicle-hero__bottom">
        <div class="vehicle-hero__identity">
          <div class="vehicle-hero__badges">
            <span
              v-if="vehicle.flagship"
              class="vehicle-hero__badge vehicle-hero__badge--flagship"
              data-test="vehicle-badge-flagship"
            >
              <i class="fa fa-certificate" />
              {{ t("labels.vehicle.flagship") }}
            </span>
            <span
              v-if="vehicle.public && !vehicle.wanted"
              class="vehicle-hero__badge vehicle-hero__badge--public"
              data-test="vehicle-badge-public"
            >
              {{ t("labels.vehicle.publicShort") }}
            </span>
            <span v-if="vehicle.wanted" class="vehicle-hero__badge">
              {{ t("labels.vehicle.wanted") }}
            </span>
            <button
              v-if="vehicle.wanted"
              type="button"
              class="vehicle-hero__badge vehicle-hero__badge--toggle"
              :class="{
                'vehicle-hero__badge--sale-notify': vehicle.saleNotify,
              }"
              :aria-pressed="vehicle.saleNotify"
              :disabled="updateMutation.isPending.value"
              :tabindex="compact ? -1 : undefined"
              data-test="vehicle-badge-sale-notify"
              @click="toggleSaleNotify"
            >
              <i
                class="fa-duotone"
                :class="vehicle.saleNotify ? 'fa-bell' : 'fa-bell-slash'"
              />
              {{
                vehicle.saleNotify
                  ? t("labels.vehicle.saleNotifyOn")
                  : t("labels.vehicle.saleNotifyOff")
              }}
            </button>
            <component
              :is="activeLoadoutPage ? 'router-link' : 'a'"
              v-if="activeLoadout"
              v-bind="
                activeLoadoutPage
                  ? { to: activeLoadoutPage }
                  : {
                      href: activeLoadout.url,
                      target: '_blank',
                      rel: 'noopener',
                    }
              "
              :tabindex="compact ? -1 : undefined"
              class="vehicle-hero__badge vehicle-hero__badge--toggle vehicle-hero__badge--loadout"
              data-test="vehicle-badge-loadout"
            >
              <i class="fa-duotone fa-crosshairs" />
              {{ t("labels.loadout.marker", { name: activeLoadout.name }) }}
            </component>
            <span v-if="vehicle.loaner" class="vehicle-hero__badge">
              {{ t("labels.vehicle.loaner") }}
            </span>
            <span v-if="vehicle.boughtViaLabel" class="vehicle-hero__badge">
              {{ vehicle.boughtViaLabel }}
            </span>
          </div>
          <h1 class="vehicle-hero__title">{{ title }}</h1>
          <p class="vehicle-hero__subline">
            <router-link
              v-if="vehicle.name"
              :to="{ name: 'ship', params: { slug: vehicle.model.slug } }"
              class="vehicle-hero__model"
            >
              {{ vehicle.model.manufacturer?.name }} {{ vehicle.model.name }}
            </router-link>
            <span v-if="vehicle.location" data-test="vehicle-hero-location">
              <i class="fa-duotone fa-location-dot" />
              <LocationName
                :text="vehicle.location"
                :linked="vehicle.linkedLocation"
              />
            </span>
            <span v-if="vehicle.serial">
              {{
                t("labels.vehicleOverview.serial", { serial: vehicle.serial })
              }}
            </span>
            <span>
              {{
                t("labels.vehicleOverview.since", {
                  date: l(vehicle.createdAt, "datetime.formats.date"),
                })
              }}
            </span>
          </p>
        </div>
        <div class="vehicle-hero__links">
          <!-- The ship page's pair: the switch, and beside it while the model
               shows, the full-screen viewer. -->
          <BtnGroup v-if="holoModel">
            <Btn
              v-if="holoVisible"
              v-tooltip="t('actions.vehicleOverview.fullscreenHolo')"
              :aria-label="t('actions.vehicleOverview.fullscreenHolo')"
              data-test="vehicle-hero-holo-viewer"
              @click="openFullscreenHolo"
            >
              <i class="fa-light fa-expand" />
            </Btn>
            <Btn
              :active="holoVisible"
              :aria-pressed="holoVisible"
              data-test="vehicle-hero-holo"
              @click="vehicleViewStore.toggleHolo(vehicle.id)"
            >
              <i class="fa-duotone fa-cube" />
              {{ t("labels.3dView") }}
            </Btn>
          </BtnGroup>
          <Btn :to="{ name: 'ship', params: { slug: vehicle.model.slug } }">
            {{ t("actions.vehicleOverview.shipDatabase") }}
          </Btn>
        </div>
      </div>
    </div>
    <Specs
      :model="vehicle.model"
      :cargo-label="String(cargoLabel(vehicle))"
      overlay
      class="vehicle-hero__specs"
    />
  </section>
</template>

<style lang="scss" scoped>
.vehicle-hero {
  // The strip's height on the picture, which the title block sits above.
  --vehicle-hero-specs-h: 68px;

  position: relative;
  overflow: hidden;
  border: 1px solid var(--color-edge-soft);
  border-radius: 10px;
  background: var(--color-gray-black);
  margin-bottom: 20px;

  &__stage {
    position: relative;
    height: clamp(300px, 42vw, 560px);
    transition: height 0.35s ease;

    // Held at 560px a page-wide picture is a sliver of the ship.
    @media (min-width: map-get($grid-breakpoints, xxl)) {
      height: clamp(560px, 21vw, 820px);
    }
  }

  &__specs {
    position: absolute;
    right: 0;
    bottom: 0;
    left: 0;
    z-index: 2;
    transition:
      opacity 0.25s ease,
      transform 0.35s ease;
  }

  // The scrim the title and actions read against; the picture is the owner's,
  // so nothing about its brightness can be assumed.
  &__stage::after {
    content: "";
    position: absolute;
    inset: 0;
    background: linear-gradient(
      180deg,
      rgb(0 0 0 / 0.55) 0%,
      rgb(0 0 0 / 0) 22%,
      rgb(0 0 0 / 0) 48%,
      rgb(0 0 0 / 0.88) 100%
    );
    pointer-events: none;
  }

  // Above the scrim, so the model can be turned; the title and actions sit
  // above it again.
  &__holo {
    position: absolute;
    inset: 0;
    z-index: 1;
  }

  &__image {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  &__top,
  &__bottom {
    position: absolute;
    left: 16px;
    right: 16px;
    z-index: 2;
    display: flex;
    justify-content: space-between;
    gap: 12px;
    flex-wrap: wrap;
  }

  &__top {
    top: 16px;
    align-items: center;
    transition:
      top 0.35s ease,
      transform 0.35s ease;
  }

  &__bottom {
    bottom: calc(var(--vehicle-hero-specs-h) + 20px);
    left: 24px;
    right: 24px;
    align-items: flex-end;
    transition: bottom 0.35s ease;
  }

  &__badges,
  &__own-picture,
  &__links {
    transition: opacity 0.2s ease;
  }

  &__own-picture {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 4px 10px;
    border-radius: 999px;
    background: rgb(0 0 0 / 0.55);
    font-size: 0.75rem;
  }

  &__actions,
  &__links {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }

  &__identity {
    display: flex;
    flex-direction: column;
    gap: 6px;
    min-width: 0;
  }

  &__badges {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
  }

  &__badge {
    display: inline-flex;
    align-items: center;
    gap: 5px;
    padding: 2px 8px;
    border-radius: 4px;
    background: rgb(58 63 68 / 0.9);
    color: #e6e6e6;
    font-size: 0.7rem;
    font-weight: 700;
    letter-spacing: 0.08em;
    text-transform: uppercase;

    &--flagship {
      background: var(--color-gold);
      color: var(--color-gray-black);
    }

    &--public {
      background: rgb(66 139 202 / 0.85);
    }

    &--toggle {
      border: 0;
      font-family: inherit;
      line-height: inherit;
      cursor: pointer;
      transition:
        background 150ms ease,
        color 150ms ease;

      &:hover,
      &:focus-visible {
        background: rgb(78 84 90 / 0.95);
      }

      &:focus-visible {
        outline: 2px solid var(--color-primary);
        outline-offset: 2px;
      }

      &:disabled {
        cursor: progress;
      }
    }

    &--loadout {
      text-decoration: none;

      &:hover,
      &:focus-visible {
        color: #fff;
        text-decoration: none;
      }
    }

    &--sale-notify {
      background: color-mix(in srgb, var(--color-primary) 85%, transparent);

      &:hover,
      &:focus-visible {
        background: var(--color-primary);
      }
    }
  }

  &__title {
    transition: font-size 0.35s ease;
    margin: 0;
    font-family: Orbitron, sans-serif;
    font-size: clamp(1.75rem, 4vw, 2.75rem);
    line-height: 1.1;
    color: #fff;
    overflow-wrap: anywhere;
  }

  &__subline {
    display: flex;
    flex-wrap: wrap;
    gap: 4px 14px;
    margin: 0;
    color: #d6d6d6;
  }

  &__model {
    color: #fff;
    font-weight: 600;
  }

  // The banner: the picture cropped to a strip, the name and the actions on
  // it, everything else faded out of the way.
  &--compact {
    --vehicle-hero-specs-h: 0px;

    .vehicle-hero__stage {
      height: 96px;
    }

    .vehicle-hero__specs {
      opacity: 0;
      transform: translateY(100%);
      pointer-events: none;
    }

    .vehicle-hero__top {
      top: 50%;
      left: auto;
      transform: translateY(-50%);
    }

    .vehicle-hero__bottom {
      bottom: 14px;
      right: 220px;
    }

    .vehicle-hero__badges,
    .vehicle-hero__own-picture,
    .vehicle-hero__links {
      position: absolute;
      opacity: 0;
      pointer-events: none;
    }

    .vehicle-hero__title {
      font-size: 1.35rem;
    }

    .vehicle-hero__stage::after {
      background: linear-gradient(
        90deg,
        rgb(0 0 0 / 0.85) 0%,
        rgb(0 0 0 / 0.35) 60%,
        rgb(0 0 0 / 0.6) 100%
      );
    }
  }

  @media (prefers-reduced-motion: reduce) {
    &__stage,
    &__specs,
    &__top,
    &__bottom,
    &__title,
    &__badges,
    &__own-picture,
    &__links {
      transition: none;
    }
  }

  // A phone's picture is too small to carry six figures, so the strip follows
  // it instead.
  @media (max-width: $desktop-breakpoint) {
    --vehicle-hero-specs-h: 0px;

    border-radius: 0;
    border-inline: 0;
    margin-inline: -15px;

    &__specs {
      position: static;
    }

    &__bottom {
      left: 16px;
      right: 16px;
    }

    &__action-label,
    &__links {
      display: none;
    }

    // A phone's banner keeps the name alone, on one line: the stage is 96px
    // and the actions take the right, so the details would wrap out of it.
    &--compact {
      .vehicle-hero__specs,
      .vehicle-hero__subline {
        display: none;
      }

      .vehicle-hero__bottom {
        top: 0;
        bottom: 0;
        right: 150px;
        align-items: center;
      }

      .vehicle-hero__title {
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
      }
    }
  }
}
</style>
