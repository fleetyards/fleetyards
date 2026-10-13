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
import {
  DEFAULT_OPERATIONS_GROUP,
  OPERATIONS_GROUPS,
} from "./operationsGroups";
import { emblemSize, plaqueMakerFor } from "./makers";
import miscPattern from "@/images/plaque/misc-pattern.webp";

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

const maker = computed(() => plaqueMakerFor(props.vehicle));

// The uploaded logo, for a maker the plaque has no emblem of its own for.
const logo = computed(
  () => manufacturer.value?.logo?.smallUrl || manufacturer.value?.logo?.url,
);

const inMakerStyle = computed(
  () => props.vehicle.plaqueStyle === "manufacturer" && !!maker.value,
);

// The image drawn through a mask in the style's colour, if the emblem is drawn
// that way in the current style.
const emblemMask = computed(() => {
  if (!maker.value) {
    return undefined;
  }
  if (maker.value.tint) {
    return maker.value.emblem;
  }

  return inMakerStyle.value ? undefined : maker.value.mono;
});

const emblemStyle = computed(() => {
  if (!maker.value) {
    return undefined;
  }

  return {
    ...emblemSize(maker.value),
    ...(emblemMask.value ? { "--icon": `url(${emblemMask.value})` } : {}),
  };
});

const styleClasses = computed(() => {
  const style = props.vehicle.plaqueStyle ?? "brass";

  if (style !== "manufacturer") {
    return [`vehicle-plaque--${style}`];
  }
  if (!maker.value) {
    return ["vehicle-plaque--brass"];
  }

  return [
    "vehicle-plaque--maker",
    `vehicle-plaque--maker-${maker.value.theme}`,
  ];
});

// The columns carry the maker's everyday name, "Drake Shipwrights", and the
// operations crew is the lore group the captain picked.
const builder = computed(
  () => props.vehicle.manufacturerShortName || manufacturer.value?.name || "",
);

const credits = computed(() =>
  PLAQUE_CREDITS.map((group) => ({
    ...group,
    heading:
      group.role === "operations"
        ? // A group a newer server knows and this bundle does not reads as
          // the default rather than breaking the plaque.
          (
            OPERATIONS_GROUPS[
              props.vehicle.operationsGroup ?? DEFAULT_OPERATIONS_GROUP
            ] ?? OPERATIONS_GROUPS[DEFAULT_OPERATIONS_GROUP]
          ).heading
        : t(`texts.vehiclePlaque.credits.${group.role}`, {
            manufacturer: builder.value,
          }),
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
    <figure
      :id="elementId"
      class="vehicle-plaque"
      :class="styleClasses"
      :style="{ '--mark': `url(${miscPattern})` }"
      data-test="vehicle-plaque"
    >
      <span
        v-for="corner in ['tl', 'tr', 'bl', 'br']"
        :key="corner"
        class="vehicle-plaque__corner"
        :class="`vehicle-plaque__corner--${corner}`"
      />
      <span
        v-for="index in 8"
        :key="index"
        class="vehicle-plaque__deco"
        :class="`vehicle-plaque__deco--${index}`"
      />
      <span
        v-if="emblemMask"
        class="vehicle-plaque__emblem"
        :style="emblemStyle"
        data-test="vehicle-plaque-emblem"
      />
      <img
        v-else-if="maker"
        :src="maker.emblem"
        :style="emblemStyle"
        alt=""
        class="vehicle-plaque__logo"
        data-test="vehicle-plaque-emblem"
      />
      <img
        v-else-if="logo"
        :src="logo"
        alt=""
        class="vehicle-plaque__logo vehicle-plaque__logo--uploaded"
      />
      <h3 class="vehicle-plaque__name" data-test="vehicle-plaque-name">
        {{ shipName }}
      </h3>
      <p class="vehicle-plaque__class" data-test="vehicle-plaque-class">
        {{ classLine }}
      </p>
      <p
        v-if="vehicle.serial"
        class="vehicle-plaque__registry"
        data-test="vehicle-plaque-registry"
      >
        <span>{{ t("labels.vehiclePlaque.registry") }}</span>
        {{ vehicle.serial }}
      </p>
      <ul v-if="lines.length" class="vehicle-plaque__lines">
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
          class="vehicle-plaque__group"
        >
          <h4>{{ group.heading }}</h4>
          <ul>
            <li v-for="name in group.names" :key="name">{{ name }}</li>
          </ul>
        </section>
      </div>
      <blockquote
        v-if="vehicle.dedication"
        class="vehicle-plaque__quote"
        data-test="vehicle-plaque-dedication"
      >
        “{{ vehicle.dedication }}”
      </blockquote>
    </figure>
  </div>
</template>

<style lang="scss" scoped>
// One layout at every width: the frame is the size container and every
// measure is a share of its width, so a phone shows the desktop plaque scaled
// down, line breaks and all. The numbers are px on a 720px plaque.
.vehicle-plaque-frame {
  container-type: inline-size;
}

// The layout every style shares; the styles themselves are in `styles/`.
.vehicle-plaque {
  --bg: #222;
  --ink: #ddd;
  --sub: #aaa;
  --accent: #428bca;
  --rule: rgb(255 255 255 / 0.2);
  --logo: none;

  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.2cqw;
  margin: 0;
  padding: 5cqw 5.5cqw 4.6cqw;
  text-align: center;

  > * {
    position: relative;
    z-index: 1;
  }

  &__deco {
    display: none;
    position: absolute;
    z-index: 0;
  }

  &__corner {
    display: none;
  }

  &__logo {
    object-fit: contain;
    filter: var(--logo);

    &--uploaded {
      max-width: 22cqw;
      max-height: 7cqw;
    }
  }

  &__emblem {
    display: block;
    background: var(--emblem, var(--accent));
    mask: var(--icon) center / contain no-repeat;
  }

  &__name {
    margin: 0;
    font:
      700 5.6cqw/1.1 Orbitron,
      sans-serif;
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  // One line each, at every width. A picture of the plaque pins every box to
  // its width rounded below the text, so a break would draw the second line
  // over the next one.
  &__name,
  &__class,
  &__registry,
  &__lines li {
    white-space: nowrap;
  }

  &__class,
  &__registry {
    margin: 0;
    font-size: 1.9cqw;
    font-weight: 700;
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }

  &__lines {
    display: flex;
    flex-direction: column;
    gap: 0.3cqw;
    margin: 0;
    padding: 0;
    list-style: none;
    font-size: 1.7cqw;
    font-weight: 600;
    letter-spacing: 0.04em;
    line-height: 1.4;
    text-transform: uppercase;
  }

  &__credits {
    display: grid;
    grid-template-columns: repeat(5, minmax(0, 1fr));
    gap: 1.4cqw;
    align-self: stretch;
    margin-top: 1.2cqw;
  }

  &__group {
    h4 {
      margin: 0 0 0.6cqw;
      font-size: 1.15cqw;
      font-weight: 800;
      letter-spacing: 0.05em;
      line-height: 1.3;
      text-transform: uppercase;
    }

    ul {
      margin: 0;
      padding: 0;
      list-style: none;
      font-size: 1.3cqw;
      font-weight: 600;
      line-height: 1.45;
    }
  }

  &__quote {
    max-width: 80cqw;
    margin: 1cqw 0 0;
    padding: 0;
    border: 0;
    font-size: 2.1cqw;
    font-style: italic;
    font-weight: 600;
    line-height: 1.4;
    overflow-wrap: anywhere;
  }
}

// A maker style paints with the colours it sets on the plate.
.vehicle-plaque--maker {
  background: var(--bg);
  color: var(--ink);

  .vehicle-plaque__name,
  .vehicle-plaque__quote {
    color: var(--name, var(--ink));
  }

  .vehicle-plaque__class,
  .vehicle-plaque__group h4 {
    color: var(--accent);
  }

  .vehicle-plaque__registry,
  .vehicle-plaque__lines,
  .vehicle-plaque__group ul {
    color: var(--sub);
  }

  .vehicle-plaque__credits {
    padding-top: 1.8cqw;
    border-top: 1px solid var(--rule);
  }
}

// The general styles were drawn around an uploaded logo; the emblem takes the
// colour that logo was filtered to.
.vehicle-plaque--brass,
.vehicle-plaque--walnut {
  --emblem: rgb(43 36 32 / 0.8);
}

.vehicle-plaque--hud,
.vehicle-plaque--glass {
  --emblem: rgb(255 255 255 / 0.85);
}

.vehicle-plaque--gunmetal,
.vehicle-plaque--salvage,
.vehicle-plaque--carbon {
  --emblem: #e2e2e2;
}

.vehicle-plaque--blueprint {
  --emblem: rgb(255 255 255 / 0.9);
}

.vehicle-plaque--neon {
  --emblem: #fff;

  .vehicle-plaque__emblem {
    filter: drop-shadow(0 0 0.8cqw rgb(255 63 180 / 0.9));
  }
}

@import "./styles/general";
@import "./styles/makers";
</style>
