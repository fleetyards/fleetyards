<script lang="ts">
export default {
  name: "HomeBuildPills",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useScDataBuilds } from "@/services/fyApi";

const { data } = useScDataBuilds();

// Only the builds the game is on right now: LIVE first, then PTU when there is
// one, never the archive of every build the export has seen.
const builds = computed(() =>
  ["live", "ptu"].flatMap((environment) => {
    const build = data.value?.items.find(
      (item) => item.environment.toLowerCase() === environment,
    );

    return build ? [build] : [];
  }),
);
</script>

<template>
  <div v-if="builds.length" class="home-build-pills">
    <Pill
      v-for="build in builds"
      :key="build.environment"
      :variant="
        build.environment.toLowerCase() === 'live'
          ? PillVariantsEnum.SUCCESS
          : PillVariantsEnum.WARNING
      "
      uppercase
    >
      {{ build.environment }} {{ build.version }}
    </Pill>
  </div>
</template>

<style lang="scss" scoped>
.home-build-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
}
</style>
