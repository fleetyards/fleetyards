<script lang="ts">
export default {
  name: "VehiclePlaque",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle, type VehiclePublic } from "@/services/fyApi";
import { inUniverseLaunchDate } from "./launchDate";

type Props = {
  vehicle: Vehicle | VehiclePublic;
  // The owner's name: the public payload carries it only when the owner shows
  // it, and the owner's own payload never does.
  captain?: string;
};

const props = withDefaults(defineProps<Props>(), {
  captain: undefined,
});

const { t, currentLocale } = useI18n();

const manufacturer = computed(() => props.vehicle.model.manufacturer);

const logo = computed(
  () => manufacturer.value?.logo?.smallUrl || manufacturer.value?.logo?.url,
);

const shipName = computed(() => props.vehicle.name || props.vehicle.model.name);

const classLine = computed(() =>
  manufacturer.value
    ? t("texts.vehiclePlaque.classLine", {
        model: props.vehicle.model.name,
        manufacturer: manufacturer.value.longName || manufacturer.value.name,
      })
    : props.vehicle.model.name,
);

const launchDate = computed(() => {
  if (!props.vehicle.launchedOn) {
    return undefined;
  }

  return t(
    "texts.vehiclePlaque.year",
    inUniverseLaunchDate(props.vehicle.launchedOn, currentLocale()),
  );
});

const launchLine = computed(() => {
  const port = props.vehicle.launchPort;

  if (launchDate.value && port) {
    return t("texts.vehiclePlaque.launchedAt", {
      date: launchDate.value,
      port,
    });
  }
  if (launchDate.value) {
    return t("texts.vehiclePlaque.launched", { date: launchDate.value });
  }
  if (port) {
    return t("texts.vehiclePlaque.launchedFrom", { port });
  }

  return undefined;
});

const captainLine = computed(() => {
  if (!props.captain) {
    return undefined;
  }

  return props.vehicle.affiliation
    ? t("texts.vehiclePlaque.captainOf", {
        name: props.captain,
        affiliation: props.vehicle.affiliation,
      })
    : t("texts.vehiclePlaque.captain", { name: props.captain });
});

const lines = computed(() =>
  [
    { key: "class", text: classLine.value },
    {
      key: "registry",
      text:
        props.vehicle.serial &&
        t("texts.vehiclePlaque.registry", { serial: props.vehicle.serial }),
    },
    {
      key: "shipyard",
      text:
        props.vehicle.shipyard &&
        t("texts.vehiclePlaque.commissioned", {
          shipyard: props.vehicle.shipyard,
        }),
    },
    { key: "launch", text: launchLine.value },
    { key: "captain", text: captainLine.value },
  ].filter((line): line is { key: string; text: string } => !!line.text),
);
</script>

<template>
  <figure class="vehicle-plaque" data-test="vehicle-plaque">
    <img v-if="logo" :src="logo" alt="" class="vehicle-plaque__logo" />
    <h3 class="vehicle-plaque__name" data-test="vehicle-plaque-name">
      {{ shipName }}
    </h3>
    <ul class="vehicle-plaque__lines">
      <li
        v-for="line in lines"
        :key="line.key"
        :data-test="`vehicle-plaque-${line.key}`"
      >
        {{ line.text }}
      </li>
    </ul>
    <blockquote
      v-if="vehicle.dedication"
      class="vehicle-plaque__dedication"
      data-test="vehicle-plaque-dedication"
    >
      “{{ vehicle.dedication }}”
    </blockquote>
  </figure>
</template>

<style lang="scss" scoped>
// A brass plate whatever the theme: it is an object on a bulkhead, not page
// chrome, so it keeps its own colours.
.vehicle-plaque {
  --plaque-metal: #c9924a;
  --plaque-metal-light: #e8b874;
  --plaque-metal-dark: #8a5a24;
  --plaque-ink: #2b2420;

  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  margin: 0;
  padding: 24px 28px;
  border: 1px solid var(--plaque-metal-dark);
  border-radius: 6px;
  outline: 1px solid var(--plaque-ink);
  outline-offset: -10px;
  background: linear-gradient(
    160deg,
    var(--plaque-metal-light) 0%,
    var(--plaque-metal) 45%,
    var(--plaque-metal-dark) 100%
  );
  box-shadow:
    inset 0 1px 0 rgb(255 255 255 / 0.35),
    0 6px 18px rgb(0 0 0 / 0.45);
  color: var(--plaque-ink);
  text-align: center;

  &__logo {
    max-width: 120px;
    max-height: 56px;
    object-fit: contain;
    filter: brightness(0.2);
  }

  &__name {
    margin: 0;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: clamp(1.25rem, 4vw, 2rem);
    font-weight: 700;
    letter-spacing: 0.04em;
    overflow-wrap: anywhere;
    text-transform: uppercase;
  }

  &__lines {
    display: flex;
    flex-direction: column;
    gap: 2px;
    margin: 0;
    padding: 0;
    list-style: none;
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.03em;
    text-transform: uppercase;
  }

  &__dedication {
    max-width: 36em;
    margin: 6px 0 0;
    padding: 0;
    border: 0;
    font-size: 0.95rem;
    font-style: italic;
    font-weight: 600;
    overflow-wrap: anywhere;
  }
}
</style>
