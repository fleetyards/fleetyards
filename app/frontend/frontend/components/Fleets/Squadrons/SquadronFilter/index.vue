<script lang="ts">
export default {
  name: "FleetSquadronFilter",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import SquadronEmblem from "@/frontend/components/Fleets/Squadrons/SquadronEmblem/index.vue";
import { useFilters } from "@/shared/composables/useFilters";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useFleetSquadrons, type Fleet } from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

type SquadronFilters = { squadronSlugIn?: string[] };

const { t } = useI18n();

const { isFleetSquadronsEnabled } = useFeatures();

const enabled = computed(() => isFleetSquadronsEnabled(props.fleet));

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  { perPage: "all" },
  { query: { enabled } },
);

const squadronList = computed(() => squadrons.value?.items ?? []);

/*
 * Its own `useFilters` rather than a prop from the page: the composable watches
 * the route query, so writing from here is what makes the page refetch. Both
 * instances see the same query and neither owns it.
 */
const { filter, filters } = useFilters<SquadronFilters>();

/*
 * Normalised, because the router does not do it: one value in the query is a
 * string and two are an array. Left alone, `includes` would match a substring
 * and the spread would take the string apart into characters.
 */
const selected = computed(() => {
  const value = filters.value.squadronSlugIn;

  if (!value) return [];

  return Array.isArray(value) ? value : [value];
});

const isSelected = (slug: string) => selected.value.includes(slug);

// "All" is the absence of a filter rather than a value of its own, so it lights
// up exactly when nothing is chosen.
const showingAll = computed(() => selected.value.length === 0);

const clear = () => filter({ squadronSlugIn: [] });

/*
 * One at a time. The endpoint takes a list and would happily narrow to several,
 * but a segmented control with an "All" in it reads as a choice between its
 * segments -- and a second click adding to the first is what made the ship list
 * end up filtered by two squadrons nobody asked for. Clicking the lit segment
 * again goes back to All.
 */
const select = (slug: string) => {
  filter({ squadronSlugIn: isSelected(slug) ? [] : [slug] });
};
</script>

<template>
  <BtnGroup v-if="squadronList.length" segmented class="squadron-filter">
    <Btn :active="showingAll" data-test="squadron-filter-all" @click="clear">
      {{ t("labels.all") }}
    </Btn>
    <Btn
      v-for="squadron in squadronList"
      :key="squadron.id"
      v-tooltip="squadron.name"
      :active="isSelected(squadron.slug)"
      :aria-label="squadron.name"
      :data-test="`squadron-filter-${squadron.slug}`"
      @click="select(squadron.slug)"
    >
      <SquadronEmblem :squadron="squadron" :size="18" />
    </Btn>
  </BtnGroup>
</template>
