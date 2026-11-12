<script lang="ts">
export default {
  name: "HomeDashboardPatchTiles",
};
</script>

<script lang="ts" setup>
import PatchTile from "@/frontend/components/Home/Dashboard/PatchTile/index.vue";
import { useScDataSources } from "@/services/fyApi";

// Live always, and the PTU beside it while there is one: the server stops
// offering a preview once live has caught up with it.
const { data } = useScDataSources();

const environments = computed(() => {
  const offered = new Set(
    (data.value?.items || []).map((source) => source.environment.toLowerCase()),
  );

  return ["live", ...(offered.has("ptu") ? ["ptu"] : [])];
});
</script>

<template>
  <div
    class="home-patch-tiles"
    :class="{ 'home-patch-tiles--pair': environments.length > 1 }"
    data-test="home-patch-tiles"
  >
    <PatchTile
      v-for="environment in environments"
      :key="environment"
      :environment="environment"
    />
  </div>
</template>

<style lang="scss" scoped>
.home-patch-tiles {
  display: grid;
  gap: 12px;

  &--pair {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>
