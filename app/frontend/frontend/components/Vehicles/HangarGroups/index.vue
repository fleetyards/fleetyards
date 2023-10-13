<template>
  <div
    class="hangar-groups"
    :class="{
      'hangar-groups-large': size === 'large',
    }"
  >
    <div
      v-for="group in groups"
      :key="`hangar-group-${group.id}`"
      v-tooltip="group.name"
      class="hangar-group"
      :style="{
        'background-color': group.color,
      }"
      @click.exact="filter($event, group.slug)"
    />
  </div>
</template>

<script lang="ts" setup>
import type { HangarGroup } from "@/services/fyApi";

type HangarGroupBubbleSizes = "default" | "large";

type Props = {
  groups: HangarGroup[];
  size?: HangarGroupBubbleSizes;
};

withDefaults(defineProps<Props>(), {
  size: "default",
});

const router = useRouter();
const route = useRoute();

const filter = (event: Event, filter: string) => {
  event.preventDefault();

  if (!filter || !route.name) {
    return;
  }

  const query = JSON.parse(JSON.stringify(route.query.q || {}));

  if ((query.hangarGroupsIn || []).includes(filter)) {
    const index = (query.hangarGroupsIn as string[]).findIndex(
      (item) => item === filter,
    );
    if (index > -1) {
      query.hangarGroupsIn.splice(index, 1);
    }
  } else {
    if (!query.hangarGroupsIn) {
      query.hangarGroupsIn = [];
    }
    query.hangarGroupsIn.push(filter);
  }

  router.replace({
    name: route.name,
    query: {
      q: query,
    },
  });
};
</script>

<script lang="ts">
export default {
  name: "HangarGroups",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
