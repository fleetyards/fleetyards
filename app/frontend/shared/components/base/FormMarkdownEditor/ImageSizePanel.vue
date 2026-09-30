<script lang="ts">
export default {
  name: "FormMarkdownEditorImageSizePanel",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { IMAGE_SIZES, type ImageSize } from "./extensions";

type Props = {
  size?: ImageSize | null;
  disabled?: boolean;
};

withDefaults(defineProps<Props>(), {
  size: null,
  disabled: false,
});

const emit = defineEmits<{
  select: [size: ImageSize | null];
}>();

const { t } = useI18n();

const root = ref<HTMLElement>();

defineExpose({
  containsFocus: () => !!root.value?.contains(document.activeElement),
});

const options: { size: ImageSize | null; key: string }[] = [
  ...IMAGE_SIZES.map((size) => ({ size, key: `imageSize${size}` })),
  { size: null, key: "imageSizeFull" },
];
</script>

<template>
  <div
    ref="root"
    class="markdown-image-size"
    role="toolbar"
    :aria-label="t('markdownEditor.imageSize')"
    data-test="markdown-editor-image-size"
  >
    <div class="markdown-image-size__options">
      <Btn
        v-for="option in options"
        :key="option.key"
        :size="BtnSizesEnum.XS"
        :active="option.size === size"
        :disabled="disabled"
        :aria-pressed="option.size === size"
        :data-test="`markdown-editor-image-size-${option.size ?? 'full'}`"
        @mousedown.prevent
        @click="emit('select', option.size)"
      >
        {{ t(`markdownEditor.${option.key}`) }}
      </Btn>
    </div>
  </div>
</template>

<style lang="scss" scoped>
// Floats over the selected image, so it carries its own surface.
.markdown-image-size {
  padding: 4px;
  background-color: var(--color-field, rgb(18 20 23 / 0.96));
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-control, 8px);
  box-shadow: 0 4px 12px rgb(0 0 0 / 0.4);
}

.markdown-image-size__options {
  display: flex;
  gap: 4px;
}
</style>
