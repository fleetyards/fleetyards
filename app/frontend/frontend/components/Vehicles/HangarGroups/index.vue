<script lang="ts">
export default {
  name: "HangarGroups",
};
</script>

<script lang="ts" setup>
import { type HangarGroup, type HangarGroupPublic } from "@/services/fyApi";

type HangarGroupBubbleSizes = "default" | "large";

type Props = {
  groups: (HangarGroup | HangarGroupPublic)[];
  size?: HangarGroupBubbleSizes;
};

withDefaults(defineProps<Props>(), {
  size: "default",
});

const router = useRouter();
const route = useRoute();

const toArray = (value: string | string[] | undefined): string[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return [value];
};

const filter = async (event: Event, filterSlug: string) => {
  event.preventDefault();

  if (!filterSlug || !route.name) {
    return;
  }

  const currentGroups = toArray(
    route.query.hangarGroupsIn as string | string[] | undefined,
  );
  let hangarGroupsIn: string[];

  if (currentGroups.includes(filterSlug)) {
    hangarGroupsIn = currentGroups.filter((g) => g !== filterSlug);
  } else {
    hangarGroupsIn = [...currentGroups, filterSlug];
  }

  await router.replace({
    name: route.name,
    query: {
      ...route.query,
      hangarGroupsIn: hangarGroupsIn.length ? hangarGroupsIn : undefined,
    },
  });
};
</script>

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

<style lang="scss" scoped>
@import "index";
</style>
