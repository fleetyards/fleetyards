<script lang="ts">
export default {
  name: "FleetchartCanvasSettings",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetchartBackgrounds,
  FleetchartFacings,
  FleetchartGroups,
  FleetchartHeadingSizes,
  FleetchartLayouts,
  FleetchartShipStates,
  FleetchartSorts,
  FleetchartSpacings,
  useFleetchartStore,
  type FleetchartOptions,
} from "@/shared/stores/fleetchart";

interface Props {
  namespace: string;
  // Resolved by the canvas, so a group this chart does not offer reads as none.
  options: FleetchartOptions;
  groups: FleetchartGroups[];
  canArrange?: boolean;
  // Ships are being placed by hand: the options a layout uses apply to them
  // by arranging them again.
  arranging?: boolean;
  // The layout arranging again applies.
  arrangement?: FleetchartLayouts;
  // The way every ship faces, while each keeps its own: none when they differ.
  shipsFacing?: FleetchartFacings;
}

const props = withDefaults(defineProps<Props>(), {
  canArrange: false,
  arranging: false,
  arrangement: FleetchartLayouts.PACKED,
  shipsFacing: undefined,
});

const emit = defineEmits<{
  arrange: [changes: Partial<FleetchartOptions>];
}>();

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const ARRANGING_OPTIONS: (keyof FleetchartOptions)[] = [
  "sort",
  "group",
  "spacing",
  "facing",
  "headingSize",
];

const current = (name: keyof FleetchartOptions) =>
  props.arranging && name === "facing"
    ? props.shipsFacing
    : props.options[name];

const update = (changes: Partial<FleetchartOptions>) => {
  const [name, value] = Object.entries(changes)[0] as [
    keyof FleetchartOptions,
    unknown,
  ];

  if (current(name) === value) return;

  const arranges = props.arranging && ARRANGING_OPTIONS.includes(name);

  // Ships placed by hand each keep their own facing, so turning them leaves
  // the chart's own alone.
  if (!(arranges && name === "facing")) {
    fleetchartStore.updateOptions({
      namespace: props.namespace,
      options: changes,
    });
  }

  if (arranges) {
    emit("arrange", changes);
  }
};

const layout = computed(() =>
  fleetchartStore.fleetchartLayout(props.namespace, props.canArrange),
);

// A free arrangement only changes when it is arranged again, which a chart
// that cannot be edited never is.
const groupable = computed(
  () => layout.value !== FleetchartLayouts.FREE || props.arranging,
);

// Packing decides the order itself, so a sort would do nothing there.
const sortable = computed(
  () =>
    (props.arranging ? props.arrangement : layout.value) !==
      FleetchartLayouts.PACKED && groupable.value,
);

const choices = computed(() => [
  {
    name: "background" as const,
    labelKey: "background",
    optionsKey: "backgroundOptions",
    values: Object.values(FleetchartBackgrounds) as string[],
  },
  {
    name: "state" as const,
    labelKey: "state",
    optionsKey: "stateOptions",
    values: Object.values(FleetchartShipStates) as string[],
  },
  ...(sortable.value
    ? [
        {
          name: "sort" as const,
          labelKey: "sort",
          optionsKey: "sortOptions",
          values: Object.values(FleetchartSorts) as string[],
        },
      ]
    : []),
  ...(groupable.value
    ? [
        {
          name: "facing" as const,
          labelKey: "facing",
          optionsKey: "facingOptions",
          values: Object.values(FleetchartFacings) as string[],
        },
        {
          name: "group" as const,
          labelKey: "group",
          optionsKey: "groupOptions",
          values: props.groups as string[],
        },
        ...(props.options.group === FleetchartGroups.NONE &&
        layout.value !== FleetchartLayouts.FREE
          ? []
          : [
              {
                name: "headingSize" as const,
                labelKey: "headingSize",
                optionsKey: "headingSizeOptions",
                values: Object.values(FleetchartHeadingSizes) as string[],
              },
            ]),
      ]
    : []),
  ...(groupable.value
    ? [
        {
          name: "spacing" as const,
          labelKey: "spacing",
          optionsKey: "spacingOptions",
          values: Object.values(FleetchartSpacings) as string[],
        },
      ]
    : []),
]);
</script>

<template>
  <section
    class="fleetchart-canvas-settings"
    :aria-label="t('labels.fleetchartApp.options')"
    data-test="fleetchart-settings"
  >
    <div
      v-for="choice in choices"
      :key="choice.name"
      class="fleetchart-canvas-settings__row"
    >
      <span class="fleetchart-canvas-settings__label">
        {{ t(`labels.fleetchartApp.${choice.labelKey}`) }}
      </span>
      <div class="fleetchart-canvas-settings__values">
        <Btn
          v-for="value in choice.values"
          :key="value"
          :active="current(choice.name) === value"
          :data-test="`fleetchart-${choice.name}-${value}`"
          size="sm"
          @click="update({ [choice.name]: value })"
        >
          {{ t(`labels.fleetchartApp.${choice.optionsKey}.${value}`) }}
        </Btn>
      </div>
    </div>

    <div class="fleetchart-canvas-settings__values">
      <Btn
        :active="options.scaleBar"
        data-test="fleetchart-scale-bar"
        size="sm"
        @click="update({ scaleBar: !options.scaleBar })"
      >
        {{ t("labels.fleetchartApp.scaleBar") }}
      </Btn>
      <Btn
        :active="options.solidExport"
        data-test="fleetchart-solid-export"
        size="sm"
        @click="update({ solidExport: !options.solidExport })"
      >
        {{ t("labels.fleetchartApp.solidExport") }}
      </Btn>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
