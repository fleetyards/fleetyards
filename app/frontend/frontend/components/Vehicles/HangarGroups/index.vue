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
  // Overlaps the dots on one line, so a row of a table keeps its height
  // however many groups the ship is in.
  stacked?: boolean;
  // The stacked dots shown before the rest fold into a count. The count takes
  // a dot's place, so a "+1" never stands in for a dot that would have fit.
  max?: number;
  highlightedId?: string;
};

const props = withDefaults(defineProps<Props>(), {
  size: "default",
  stacked: false,
  max: 4,
  highlightedId: undefined,
});

const visibleGroups = computed(() => {
  if (!props.stacked || props.groups.length <= props.max) {
    return props.groups;
  }

  return props.groups.slice(0, props.max - 1);
});

const hiddenGroups = computed(() =>
  props.groups.slice(visibleGroups.value.length),
);

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

  await router.push({
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
      'hangar-groups-stacked': stacked,
    }"
  >
    <div
      v-for="group in visibleGroups"
      :key="`hangar-group-${group.id}`"
      v-tooltip="group.name"
      class="hangar-group"
      :class="{
        'hangar-group-highlighted': group.id === highlightedId,
      }"
      :style="{
        'background-color': group.color,
      }"
      data-test="hangar-group"
      @click.exact="filter($event, group.slug)"
    />
    <div
      v-if="hiddenGroups.length"
      v-tooltip="hiddenGroups.map((group) => group.name).join(', ')"
      class="hangar-group hangar-group-overflow"
      :class="{
        'hangar-group-highlighted': hiddenGroups.some(
          (group) => group.id === highlightedId,
        ),
      }"
      data-test="hangar-group-overflow"
    >
      +{{ hiddenGroups.length }}
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
