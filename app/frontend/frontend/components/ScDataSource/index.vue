<script lang="ts">
export default {
  name: "ScDataSourceBar",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import { useQueryClient } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useScDataSourceStore } from "@/shared/stores/scDataSource";
import { useScDataSources } from "@/services/fyApi";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();
const queryClient = useQueryClient();
const store = useScDataSourceStore();
const { available, hasChoice } = storeToRefs(store);

// The switch is also what tells the store which builds exist, so the two cannot
// disagree: a source the server stopped offering is dropped from the choice.
const { data } = useScDataSources();

watch(
  () => data.value,
  (result) => {
    if (result?.items) store.setAvailable(result.items);
  },
  { immediate: true },
);

const selected = computed(() => store.selected);

// The header is a sibling in this same tree, so its target is not in the
// document while this mounts -- Vue would fail to locate it and render nothing.
// Route components teleport into it fine because they mount after the layout.
const mounted = ref(false);
onMounted(() => {
  mounted.value = true;
});

const hint = computed(() =>
  selected.value && !selected.value.default
    ? t("labels.scDataSource.notLive")
    : t("labels.scDataSource.reading"),
);

// Everything cached was fetched against another build, so it all goes. Sending
// the new source without this would show the old build's data under the new
// label until each query happened to refetch.
const select = async (environment: string) => {
  if (selected.value?.environment === environment) return;

  const option = available.value.find(
    (source) => source.environment === environment,
  );

  store.select(option?.default ? undefined : environment);

  queryClient.clear();
  await queryClient.refetchQueries({ type: "active" });
};
</script>

<template>
  <!-- Into the header rather than a row of its own: this is a global control
       like Compare and Fleetchart beside it, and a full-width bar of its own
       pushed every page's toolbar down and lined up with nothing. -->
  <Teleport v-if="mounted" to="#header-right">
    <div
      v-if="hasChoice"
      class="sc-data-source"
      :class="{ 'sc-data-source-off-default': selected && !selected.default }"
    >
      <span v-tooltip="hint" class="sc-data-source-label">
        <i class="fa-duotone fa-database" />
      </span>

      <BtnGroup segmented data-test="sc-data-source-switch">
        <Btn
          v-for="source in available"
          :key="source.environment"
          v-tooltip="source.version"
          :size="BtnSizesEnum.SM"
          :active="source.environment === selected?.environment"
          @click="select(source.environment)"
        >
          {{ source.environment }}
        </Btn>
      </BtnGroup>
    </div>
  </Teleport>
</template>

<style lang="scss" scoped>
.sc-data-source {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
}

.sc-data-source-label {
  opacity: 0.6;
}

// Off the default build, the icon says so rather than a bar of its own -- the
// active button already names which build is being read.
.sc-data-source-off-default .sc-data-source-label {
  color: $warning;
  opacity: 1;
}
</style>
