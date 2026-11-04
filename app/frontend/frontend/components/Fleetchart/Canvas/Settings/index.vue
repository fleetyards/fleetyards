<script lang="ts">
export default {
  name: "FleetchartCanvasSettings",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  FleetchartFacings,
  FleetchartGroups,
  FleetchartLayouts,
  FleetchartSorts,
  FleetchartSpacings,
  useFleetchartStore,
  type FleetchartOptions,
} from "@/shared/stores/fleetchart";

interface Props {
  namespace: string;
  canArrange?: boolean;
}

const props = defineProps<Props>();

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const options = computed(() =>
  fleetchartStore.fleetchartOptions(props.namespace),
);

const update = (changes: Partial<FleetchartOptions>) => {
  fleetchartStore.updateOptions({
    namespace: props.namespace,
    options: changes,
  });
};

// Packing decides the order itself, so a sort would do nothing there.
const layout = computed(() =>
  fleetchartStore.fleetchartLayout(props.namespace, props.canArrange),
);

const sortable = computed(
  () =>
    layout.value !== FleetchartLayouts.PACKED &&
    layout.value !== FleetchartLayouts.FREE,
);

// Ships in a free arrangement stay where they were put, facing the way they were
// turned.
const groupable = computed(() => layout.value !== FleetchartLayouts.FREE);

const choices = computed(() => [
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
          values: Object.values(FleetchartGroups) as string[],
        },
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
          :active="options[choice.name] === value"
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
