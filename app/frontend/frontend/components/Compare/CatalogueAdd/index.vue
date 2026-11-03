<script lang="ts">
export default {
  name: "CompareCatalogueAdd",
};
</script>

<script lang="ts" setup>
import CompareAddButton from "@/frontend/components/Compare/AddButton/index.vue";
import { MAX_MODELS } from "@/frontend/components/Compare/constants";
import type { CompareCategory } from "@/frontend/components/Compare/category";
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
  label: string;
  compact?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  lock: undefined,
  compact: false,
});

const { t } = useI18n();

const comlink = useComlink();

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
  <CompareAddButton
    :label="label"
    :full="slugs.length >= MAX_MODELS"
    :full-hint="t('labels.compare.enoughItems')"
    :compact="compact"
    data-test="compare-add-items"
    @open="showPicker"
  />
</template>
