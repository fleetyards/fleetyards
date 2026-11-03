<script lang="ts">
export default {
  name: "CompareCatalogueHeader",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import type { CompareCategory } from "@/frontend/components/Compare/category";
import { useCompareShareUrl } from "@/frontend/composables/useCompareShareUrl";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import type {
  ComponentQuery,
  CompareShareInput,
  EquipmentQuery,
} from "@/services/fyApi";

type Props = {
  kind: "Component" | "Equipment";
  queryKey: keyof CompareShareInput;
  slugs: string[];
  lock?: CompareCategory<ComponentQuery | EquipmentQuery>;
  addLabel: string;
  shareTitle: string;
};

const props = withDefaults(defineProps<Props>(), {
  lock: undefined,
});

const { t } = useI18n();

const comlink = useComlink();

const full = computed(() => props.slugs.length >= MAX_MODELS);

const tooltip = computed(() =>
  full.value ? t("labels.compare.enoughItems") : undefined,
);

const shareUrl = useCompareShareUrl(props.queryKey, () => props.slugs);

const showPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Compare/CataloguePickerModal/index.vue"),
    props: {
      kind: props.kind,
      queryKey: props.queryKey,
      lock: props.lock,
    },
    wide: true,
  });
};
</script>

<template>
  <!-- The tooltip hangs on the wrapper, not the button: a disabled button
       dispatches no pointer events, so the one case that has something to say is
       the one that could never say it. -->
  <div v-tooltip="tooltip" class="compare-catalogue-header__add">
    <Btn
      :disabled="full"
      :size="BtnSizesEnum.MD"
      data-test="compare-add-items"
      @click="showPicker"
    >
      <i class="fa-light fa-plus" />
      {{ addLabel }}
    </Btn>
  </div>
  <div class="compare-catalogue-header__actions">
    <ShareBtn
      v-if="slugs.length"
      :url="shareUrl"
      :title="shareTitle"
      :size="BtnSizesEnum.MD"
      no-label
    />
  </div>
</template>

<style lang="scss" scoped>
.compare-catalogue-header__add,
.compare-catalogue-header__actions {
  display: flex;
  align-items: center;
}

.compare-catalogue-header__actions {
  justify-content: flex-end;
  gap: 10px;
}
</style>
