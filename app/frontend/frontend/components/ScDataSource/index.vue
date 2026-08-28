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
  <div
    v-if="hasChoice"
    class="sc-data-source"
    :class="{ 'sc-data-source-off-default': selected && !selected.default }"
  >
    <span class="sc-data-source-label">
      <i class="fa-duotone fa-database" />
      {{ t("labels.scDataSource.reading") }}
    </span>

    <BtnGroup>
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

    <span v-if="selected && !selected.default" class="sc-data-source-warning">
      {{ t("labels.scDataSource.notLive") }}
    </span>
  </div>
</template>

<style lang="scss" scoped>
.sc-data-source {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  padding: 0.4rem 0.75rem;
  font-size: 0.85rem;
}

.sc-data-source-label {
  display: inline-flex;
  align-items: center;
  gap: 0.4rem;
  opacity: 0.7;
}

.sc-data-source-off-default {
  border-left: 3px solid $warning;
  background: rgba($warning, 0.08);
}

.sc-data-source-warning {
  color: $warning;
}
</style>
