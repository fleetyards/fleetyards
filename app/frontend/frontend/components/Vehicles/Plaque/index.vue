<script lang="ts">
export default {
  name: "VehiclePlaque",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type Vehicle, type VehiclePublic } from "@/services/fyApi";
import { inUniverseLaunchDate } from "./launchDate";
import { PLAQUE_CREDITS } from "./credits";

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

const credits = computed(() =>
  PLAQUE_CREDITS.map((group) => ({
    ...group,
    heading: t(`texts.vehiclePlaque.credits.${group.role}`),
  })),
);

// What the download button captures.
const elementId = computed(() => `vehicle-plaque-${props.vehicle.id}`);

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
  <div class="vehicle-plaque-frame">
    <figure :id="elementId" class="vehicle-plaque" data-test="vehicle-plaque">
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
      <div
        v-if="credits.length"
        class="vehicle-plaque__credits"
        data-test="vehicle-plaque-credits"
      >
        <section
          v-for="group in credits"
          :key="group.role"
          class="vehicle-plaque__credit-group"
        >
          <h4>{{ group.heading }}</h4>
          <ul>
            <li v-for="name in group.names" :key="name">{{ name }}</li>
          </ul>
        </section>
      </div>
      <blockquote
        v-if="vehicle.dedication"
        class="vehicle-plaque__dedication"
        data-test="vehicle-plaque-dedication"
      >
        “{{ vehicle.dedication }}”
      </blockquote>
    </figure>
  </div>
</template>

<style lang="scss" scoped>
// One layout at every width: the frame is the size container and every
// measure below is a share of its width, so a phone shows the desktop plaque
// scaled down, line breaks and all. The numbers are px on a 720px plaque.
.vehicle-plaque-frame {
  container-type: inline-size;
}

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
  gap: 1.4cqw;
  margin: 0;
  padding: 4.4cqw 5cqw;
  border: 1px solid var(--plaque-metal-dark);
  border-radius: 0.8cqw;
  outline: 1px solid var(--plaque-ink);
  outline-offset: -1.6cqw;
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
    max-width: 16cqw;
    max-height: 7.8cqw;
    object-fit: contain;
    filter: brightness(0.2);
  }

  &__name {
    margin: 0;
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 4.6cqw;
    font-weight: 700;
    letter-spacing: 0.04em;
    line-height: 1.15;
    overflow-wrap: anywhere;
    text-transform: uppercase;
  }

  &__lines {
    display: flex;
    flex-direction: column;
    gap: 0.3cqw;
    margin: 0;
    padding: 0;
    list-style: none;
    font-size: 1.8cqw;
    font-weight: 700;
    letter-spacing: 0.03em;
    line-height: 1.35;
    text-transform: uppercase;
  }

  // Always five columns, as on the reference plaques.
  &__credits {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 1.4cqw;
    align-self: stretch;
    margin-top: 0.8cqw;
  }

  &__credit-group {
    h4 {
      margin: 0 0 0.5cqw;
      color: inherit;
      font-size: 1.15cqw;
      font-weight: 800;
      letter-spacing: 0.04em;
      line-height: 1.3;
      text-decoration: underline;
      text-transform: uppercase;
    }

    ul {
      margin: 0;
      padding: 0;
      list-style: none;
      font-size: 1.3cqw;
      font-weight: 600;
      line-height: 1.4;
    }
  }

  &__dedication {
    max-width: 80cqw;
    margin: 0.8cqw 0 0;
    padding: 0;
    border: 0;
    font-size: 2.1cqw;
    font-style: italic;
    font-weight: 600;
    line-height: 1.4;
    overflow-wrap: anywhere;
  }
}
</style>
