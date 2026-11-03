<script lang="ts">
export default {
  name: "CompareCatalogueShare",
};
</script>

<script lang="ts" setup>
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useCompareShareUrl } from "@/frontend/composables/useCompareShareUrl";
import type { CompareShareInput } from "@/services/fyApi";

type Props = {
  queryKey: keyof CompareShareInput;
  slugs: string[];
  title: string;
};

const props = defineProps<Props>();

const shareUrl = useCompareShareUrl(props.queryKey, () => props.slugs);
</script>

<template>
  <div class="compare-catalogue-share">
    <ShareBtn
      v-if="slugs.length"
      :url="shareUrl"
      :title="title"
      :size="BtnSizesEnum.MD"
      :variant="BtnVariantsEnum.BARE"
      no-label
    />
  </div>
</template>

<style lang="scss" scoped>
.compare-catalogue-share {
  display: flex;
  align-items: center;
  justify-content: flex-end;
}
</style>
