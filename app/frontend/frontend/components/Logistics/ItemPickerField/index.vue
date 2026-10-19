<script lang="ts">
export default {
  name: "LogisticsItemPickerField",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  // The goods' name: a catalogue item's, an existing position's or one typed
  // into the picker.
  value?: string;
  // What the item is filed under, beside its name.
  categoryLabel?: string;
  error?: string;
  // For a field that opens another step than the item picker.
  label?: string;
  placeholder?: string;
  clearLabel?: string;
};

const props = withDefaults(defineProps<Props>(), {
  value: undefined,
  categoryLabel: undefined,
  error: undefined,
  label: undefined,
  placeholder: undefined,
  clearLabel: undefined,
});

const emit = defineEmits<{
  open: [];
  clear: [];
}>();

const { t } = useI18n();

const triggerId = computed(() => `${props.name}-trigger`);
const errorId = computed(() => `${props.name}-error`);
</script>

<template>
  <div class="item-picker-field" :data-test="`item-picker-field-${name}`">
    <label class="item-picker-field__label" :for="triggerId">
      {{ label ?? t("labels.logistics.itemPicker.field") }}
    </label>

    <div class="item-picker-field__control">
      <button
        :id="triggerId"
        type="button"
        class="item-picker-field__trigger"
        :class="{ 'item-picker-field__trigger--error': error }"
        :aria-invalid="!!error || undefined"
        :aria-describedby="error ? errorId : undefined"
        data-test="item-picker-field-open"
        @click="emit('open')"
      >
        <span v-if="value" class="item-picker-field__value">
          <span class="item-picker-field__name">{{ value }}</span>
          <span v-if="categoryLabel" class="item-picker-field__meta">
            {{ categoryLabel }}
          </span>
        </span>
        <span v-else class="item-picker-field__placeholder">
          {{ placeholder ?? t("labels.logistics.itemPicker.placeholder") }}
        </span>
        <i class="fa fa-chevron-right" />
      </button>

      <!-- Beside the trigger, not inside it: a button cannot hold another. -->
      <button
        v-if="value"
        v-tooltip="clearLabel ?? t('labels.logistics.itemPicker.clear')"
        type="button"
        class="item-picker-field__clear"
        :aria-label="clearLabel ?? t('labels.logistics.itemPicker.clear')"
        data-test="item-picker-field-clear"
        @click="emit('clear')"
      >
        <i class="fa-light fa-xmark" />
      </button>
    </div>

    <p v-if="error" :id="errorId" class="item-picker-field__error">
      {{ error }}
    </p>
  </div>
</template>

<style lang="scss" scoped>
.item-picker-field {
  margin-bottom: 15px;
}

.item-picker-field__label {
  display: block;
  margin-bottom: var(--field-label-gap, 5px);
  line-height: var(--field-label-line, 1.5rem);
}

.item-picker-field__control {
  display: flex;
  gap: 8px;
}

// Drawn as the select trigger is -- a dark fill in a lighter edge, capped top
// and bottom -- so it reads as a field among the form's other fields.
.item-picker-field__trigger {
  appearance: none;
  position: relative;
  display: flex;
  flex: 1 1 auto;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
  height: var(--field-h, 43px);
  padding: 0 12px;
  font: inherit;
  color: inherit;
  text-align: left;
  background: var(--color-field, rgb(18 20 23 / 0.96));
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control, 8px);
  cursor: pointer;

  &:hover {
    color: var(--color-lifted, #eee);
    background: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }

  &::before,
  &::after {
    position: absolute;
    right: max(10px, var(--cap-inset, 12%));
    left: max(10px, var(--cap-inset, 12%));
    height: var(--cap-h-btn, 2px);
    background-color: var(--field-cap, var(--color-endcap, #7a8288));
    border-radius: var(--cap-r-btn, 1px);
    content: "";
  }

  &::before {
    top: -1px;
  }

  &::after {
    bottom: -1px;
  }

  i {
    flex: none;
    margin-right: 3px;
  }
}

.item-picker-field__trigger--error {
  border-color: var(--color-danger, #dc3545);
}

.item-picker-field__error {
  margin: 4px 0 0;
  font-size: 0.875rem;
  color: var(--color-danger, #dc3545);
}

.item-picker-field__value {
  display: flex;
  align-items: baseline;
  gap: 8px;
  min-width: 0;
}

.item-picker-field__name {
  overflow: hidden;
  font-weight: bold;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.item-picker-field__meta {
  flex: none;
  font-size: 12px;
  color: var(--color-text-dim, #959595);
}

.item-picker-field__placeholder {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  color: var(--color-text-dim, #959595);
}

.item-picker-field__clear {
  appearance: none;
  flex: none;
  width: var(--field-h, 43px);
  height: var(--field-h, 43px);
  padding: 0;
  font: inherit;
  color: var(--color-muted, #7a8288);
  background: var(--color-field, rgb(18 20 23 / 0.96));
  border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-control, 8px);
  cursor: pointer;

  &:hover {
    color: var(--color-lifted, #eee);
    background: var(--color-control-hover, rgb(52 58 64 / 0.95));
  }
}
</style>
