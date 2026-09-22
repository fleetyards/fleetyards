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
import {
  FeatureFlagName,
  useFleetSquadrons,
  type Fleet,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

type SquadronFilters = { squadronSlugIn?: string[] };

const { t } = useI18n();

const { isFleetFeatureEnabled } = useFeatures();

const enabled = computed(() =>
  isFleetFeatureEnabled(props.fleet, FeatureFlagName.FLEET_SQUADRONS),
);

const { data: squadrons } = useFleetSquadrons(
  computed(() => props.fleet.slug),
  {},
  { query: { enabled } },
);

const squadronList = computed(() => squadrons.value?.items ?? []);

/*
 * Its own `useFilters` rather than a prop from the page: the composable watches
 * the route query, so writing from here is what makes the page refetch. Both
 * instances see the same query and neither owns it.
 */
const { filter, filters } = useFilters<SquadronFilters>();

const selected = computed(() => filters.value.squadronSlugIn ?? []);

const isSelected = (slug: string) => selected.value.includes(slug);

// "All" is the absence of a filter rather than a value of its own, so it lights
// up exactly when nothing is chosen and clicking it clears the rest.
const showingAll = computed(() => selected.value.length === 0);

const clear = () => filter({ squadronSlugIn: [] });

// Toggles rather than replaces: a fleet's squadrons are not exclusive and a
// member can be in several, so the control is a multi-select wearing a
// segmented coat.
const toggle = (slug: string) => {
  const next = [...selected.value];
  const index = next.indexOf(slug);

  if (index === -1) {
    next.push(slug);
  } else {
    next.splice(index, 1);
  }

  filter({ squadronSlugIn: next });
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
      :active="isSelected(squadron.slug)"
      :data-test="`squadron-filter-${squadron.slug}`"
      mobile-icon-only
      @click="toggle(squadron.slug)"
    >
      <SquadronEmblem :squadron="squadron" :size="18" />
      {{ squadron.name }}
    </Btn>
  </BtnGroup>
</template>

<style lang="scss" scoped>
// Wraps rather than scrolls: a fleet can have more squadrons than fit on one
// line of a toolbar that already carries a view switch and a paginator.
.squadron-filter {
  flex-wrap: wrap;
}
</style>
