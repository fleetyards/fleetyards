<script lang="ts">
export default {
  name: "PreviewImage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  file: File;
};

const props = defineProps<Props>();

const { t } = useI18n();

const src = ref<string | undefined>();

const alt = computed(() => props.file.name);

const reader = new FileReader();

onMounted(() => {
  reader.onload = (event) => {
    src.value = event.target?.result as string;
  };

  reader.readAsDataURL(props.file);
});
</script>

<template>
  <LazyImage
    v-if="src"
    v-tooltip="t('directUpload.previewImage.remove')"
    :src="src"
    :alt="alt"
    shadow
    class="preview-image"
  >
    <span class="preview-image__remove"><i class="fa fa-times fa-2x" /></span>
  </LazyImage>
</template>

<style lang="scss" scoped>
@import "index";
</style>
