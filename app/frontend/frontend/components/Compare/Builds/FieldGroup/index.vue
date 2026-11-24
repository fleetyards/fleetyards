<script lang="ts">
export default {
  name: "CompareBuildsFieldGroup",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Loader from "@/shared/components/Loader/index.vue";
import Entry from "@/frontend/components/Compare/Builds/Entry/index.vue";
import { useFieldLabel } from "@/frontend/components/Compare/Builds/useFieldLabel";
import {
  ScDataDiffKindEnum,
  useScDataDiff,
  type ScDataDiffCatalogueEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  catalogue: ScDataDiffCatalogueEnum;
  from: string;
  to: string;
  field: string;
  count: number;
  initiallyOpen?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  initiallyOpen: false,
});

const emit = defineEmits<{
  showAll: [field: string];
}>();

const { t, toNumber } = useI18n();

const fieldLabel = useFieldLabel();

const PREVIEW = 12;

const open = ref(props.initiallyOpen);

const params = computed(() => ({
  from: props.from,
  to: props.to,
  kind: ScDataDiffKindEnum.changed,
  field: props.field,
  perPage: String(PREVIEW),
}));

const { data, isPending } = useScDataDiff(() => props.catalogue, params, {
  query: { enabled: open },
});

const label = computed(() => fieldLabel(props.field));
</script>

<template>
  <section class="build-diff-group" data-test="build-diff-group">
    <button
      type="button"
      class="build-diff-group__toggle"
      :aria-expanded="open"
      @click="open = !open"
    >
      <i
        class="fa-solid"
        :class="open ? 'fa-caret-down' : 'fa-caret-right'"
        aria-hidden="true"
      />
      <span class="build-diff-group__label">{{ label }}</span>
      <span class="build-diff-group__count">{{ toNumber(count) }}</span>
    </button>

    <div v-if="open" class="build-diff-group__rows">
      <Loader v-if="isPending" :loading="isPending" />
      <Entry
        v-for="entry in data?.items"
        :key="entry.id"
        :entry="entry"
        :catalogue="catalogue"
        :field="field"
      />
      <Btn
        v-if="count > PREVIEW"
        :size="BtnSizesEnum.SM"
        data-test="build-diff-show-all"
        @click="emit('showAll', field)"
      >
        {{ t("labels.buildDiff.showAll", { count }) }}
      </Btn>
    </div>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
