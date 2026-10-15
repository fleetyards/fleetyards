<script lang="ts">
export default {
  name: "LoadoutMarker",
};
</script>

<script lang="ts" setup>
import type { VehicleLoadoutMinimal } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  loadout: VehicleLoadoutMinimal;
};

const props = defineProps<Props>();

const { t } = useI18n();

// Named as a loadout, so a name chosen without context still reads as one.
const title = computed(() =>
  t("labels.loadout.marker", { name: props.loadout.name }),
);

// A fleetyards loadout is kept here rather than on another site, so the panel
// shows it instead of linking away.
const emit = defineEmits<{ open: [] }>();
</script>

<template>
  <component
    :is="loadout.url ? 'a' : 'button'"
    v-tooltip="title"
    :aria-label="title"
    class="loadout-marker"
    :class="{
      'erkul-link': loadout.urlSource === 'erkul',
      'spviewer-link': loadout.urlSource === 'spviewer',
    }"
    :href="loadout.url"
    :target="loadout.url ? '_blank' : undefined"
    :rel="loadout.url ? 'noopener' : undefined"
    :type="loadout.url ? undefined : 'button'"
    data-test="loadout-marker"
    @click.stop="loadout.url || emit('open')"
  >
    <template v-if="loadout.urlSource">
      <i />
    </template>
    <template v-else>
      <i class="fa-duotone fa-crosshairs" />
    </template>
  </component>
</template>

<style lang="scss" scoped>
.loadout-marker {
  position: absolute;
  bottom: 50%;
  left: 0;
  transform: translateY(50%);
  width: 40px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: $gray;
  padding: 0;
  border: 0;
  cursor: pointer;

  // Doubled to outrank PanelBody's rounded variants, which round every link
  // inside the body and would round the edge this sits flush against.
  &.loadout-marker {
    border-radius: 0 10px 10px 0;
  }

  i,
  svg {
    color: #fff;
  }
}
</style>
