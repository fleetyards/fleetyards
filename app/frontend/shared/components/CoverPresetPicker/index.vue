<script lang="ts">
export default {
  name: "CoverPresetPicker",
};
</script>

<script lang="ts" setup>
export type CoverPreset = {
  key: string;
  url: string;
};

type Props = {
  modelValue?: string | null;
  presets: CoverPreset[];
  label?: string;
};

const props = withDefaults(defineProps<Props>(), {
  modelValue: null,
  label: undefined,
});

const emit = defineEmits<{
  "update:modelValue": [string | null];
}>();

/*
 * Picking the one already picked clears it, rather than there being no way back
 * to "no preset" once a tile has been touched. An upload is what actually
 * overrides this, but a form that cannot be put back the way it was found is a
 * form people stop trusting.
 */
const select = (key: string) => {
  emit("update:modelValue", props.modelValue === key ? null : key);
};
</script>

<template>
  <div v-if="presets.length" class="cover-presets">
    <span v-if="label" class="cover-presets__label">{{ label }}</span>
    <div class="cover-presets__grid">
      <button
        v-for="preset in presets"
        :key="preset.key"
        type="button"
        class="cover-preset"
        :class="{ 'cover-preset--active': modelValue === preset.key }"
        :style="{ backgroundImage: `url(${preset.url})` }"
        :aria-pressed="modelValue === preset.key"
        :data-test="`cover-preset-${preset.key}`"
        @click="select(preset.key)"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.cover-presets__label {
  display: block;
  margin-bottom: 6px;
  font-size: 13px;
  color: var(--color-muted, #7a8288);
}

.cover-presets__grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: 8px;
  margin-bottom: 12px;
}

.cover-preset {
  position: relative;
  height: 70px;
  padding: 0;
  background-repeat: no-repeat;
  background-position: center;
  background-size: cover;
  border: 2px solid transparent;
  border-radius: var(--radius-control-bare, 6px);
  cursor: pointer;
  transition:
    border-color 0.15s,
    transform 0.1s;

  &:hover {
    border-color: rgb(255 255 255 / 30%);
    transform: scale(1.02);
  }
}

.cover-preset--active {
  border-color: var(--color-primary, #428bca);
  box-shadow: 0 0 0 1px var(--color-primary, #428bca);
}
</style>
