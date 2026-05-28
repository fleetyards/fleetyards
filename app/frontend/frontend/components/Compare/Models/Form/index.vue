<script lang="ts">
export default {
  name: "CompareModelsForm",
};
</script>

<script lang="ts" setup>
import debounce from "lodash.debounce";
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import ModelFilterGroup from "@/frontend/components/base/ModelFilterGroup/index.vue";
import { useCompareModelFilters } from "@/frontend/composables/useCompareModelFilters";
import { compareShare, type Model } from "@/services/fyApi";
import { uniq as uniqArray } from "@/shared/utils/Array";
import { ComponentExposed } from "vue-component-type-helpers";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const longShareUrl = computed(() => {
  const host = `${window.location.protocol}//${window.location.host}`;

  return `${host}${route.fullPath}`;
});

// Pre-fetch the short share URL so the share button can hand it to
// navigator.share synchronously — iOS Safari requires transient user
// activation and rejects share() calls that await first.
const shortShareUrl = ref<string | undefined>();
const shareKey = computed(() =>
  props.models
    .map((model) => model.slug)
    .sort()
    .join(","),
);
const shareUrl = computed(() => shortShareUrl.value || longShareUrl.value);

const fetchShortShareUrl = debounce(async (key: string) => {
  try {
    const result = await compareShare({ models: key.split(",") });
    if (key !== shareKey.value) return;
    shortShareUrl.value = result.shortUrl || result.longUrl || undefined;
  } catch (error) {
    if (key !== shareKey.value) return;
    console.info("compareShare failed", error);
    shortShareUrl.value = undefined;
  }
}, 300);

watch(
  shareKey,
  (key) => {
    fetchShortShareUrl.cancel();
    shortShareUrl.value = undefined;
    if (!key) return;
    void fetchShortShareUrl(key);
  },
  { immediate: true },
);

const shareTitle = computed(() => t("headlines.compare.ships"));

const erkulUrl = computed(() => {
  return "https://www.erkul.games/calculator";
});

const spviewerUrl = computed(() => {
  return `https://www.spviewer.eu/compare?ship=${scIdentifiers.value.join("&ship=")}`;
});

const selectDisabled = computed(() => {
  return form.value.models.length > 7;
});

const disabledTooltip = computed(() => {
  if (selectDisabled.value) {
    return t("labels.compare.enough");
  }

  return undefined;
});

const scIdentifiers = computed(() => {
  return props.models.map((model) => model.scIdentifier);
});

const prefillFormValues = () => {
  return {
    models: filters.value.models || [],
  };
};

const setupForm = () => {
  form.value = prefillFormValues();
};

const { filter, filters } = useCompareModelFilters(setupForm);

const form = ref<{ models: string[] }>(prefillFormValues());

// const newModel = ref<string>();

// watch(
//   () => newModel.value,
//   () => {
//     if (newModel.value) {
//       form.value.models = [...(form.value.models || []), newModel.value]
//         .filter(uniqArray)
//         .sort();

//       filter(form.value);
//     }
//     newModel.value = undefined;
//   },
// );

const modelFilterGroup = ref<ComponentExposed<typeof ModelFilterGroup>>();

const handleChange = (model: string) => {
  if (model) {
    form.value.models = [...(form.value.models || []), model]
      .filter(uniqArray)
      .sort();

    filter(form.value);
  }

  modelFilterGroup.value?.clear();
};
</script>

<template>
  <div class="compare-form">
    <ModelFilterGroup
      ref="modelFilterGroup"
      v-tooltip="disabledTooltip"
      :disabled="selectDisabled"
      name="new-model"
      @update:model-value="handleChange"
    />
    <ShareBtn
      v-if="models.length"
      :url="shareUrl"
      :title="shareTitle"
      block
      mobile-icon-only
    />
    <Btn
      :href="erkulUrl"
      :aria-label="t('labels.hardpoints.erkul')"
      block
      mobile-icon-only
      class="erkul-link"
    >
      <i />
      {{ t("labels.hardpoints.erkul") }}
    </Btn>
    <Btn
      v-tooltip="t('labels.hardpoints.spviewerTitle')"
      :href="spviewerUrl"
      :aria-label="t('labels.hardpoints.spviewer')"
      block
      mobile-icon-only
      class="spviewer-link"
    >
      <i />
      {{ t("labels.hardpoints.spviewer") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
