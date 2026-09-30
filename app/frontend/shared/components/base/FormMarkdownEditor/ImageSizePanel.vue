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
};

withDefaults(defineProps<Props>(), {
  size: null,
});

const emit = defineEmits<{
  select: [size: ImageSize | null];
}>();

const { t } = useI18n();

const options: { size: ImageSize | null; key: string }[] = [
  ...IMAGE_SIZES.map((size) => ({ size, key: `imageSize${size}` })),
  { size: null, key: "imageSizeFull" },
];
</script>

<template>
  <div
    class="base-markdown-editor__panel"
    role="group"
    :aria-label="t('markdownEditor.imageSize')"
    data-test="markdown-editor-image-size"
  >
    <span class="base-markdown-editor__panel-label">
      {{ t("markdownEditor.imageSize") }}
    </span>
    <div class="base-markdown-editor__panel-actions">
      <Btn
        v-for="option in options"
        :key="option.key"
        :size="BtnSizesEnum.SM"
        :active="option.size === size"
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
@import "./panel";

.base-markdown-editor__panel-label {
  color: var(--color-text-dim, #959595);
  font-size: 0.875rem;
}
</style>
