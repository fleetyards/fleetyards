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

// `4.10.2-live.12913470` already names its environment; the pill says that
// part itself, so it shows the release and leaves the build id to the title.
const release = (version: string) => version.split("-")[0];
</script>

<template>
  <Transition name="fade-quick" appear>
    <div v-if="builds.length" class="home-build-pills">
      <Pill
        v-for="build in builds"
        :key="build.environment"
        :variant="
          build.environment.toLowerCase() === 'live'
            ? PillVariantsEnum.SUCCESS
            : PillVariantsEnum.WARNING
        "
        :title="build.version"
        uppercase
      >
        {{ build.environment }} {{ release(build.version) }}
      </Pill>
    </div>
  </Transition>
</template>

<style lang="scss" scoped>
.home-build-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 12px;
  white-space: nowrap;
}
</style>
