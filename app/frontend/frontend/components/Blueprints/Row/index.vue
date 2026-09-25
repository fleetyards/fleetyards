<script lang="ts">
export default {
  name: "BlueprintRow",
};
</script>

<script lang="ts" setup>
import BlueprintOwnToggle from "@/frontend/components/Blueprints/OwnToggle/index.vue";
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemChip,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useCraftTime } from "@/frontend/composables/useCraftTime";
import { type Blueprint, type FleetBlueprintOwner } from "@/services/fyApi";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";

type Props = {
  blueprint: Blueprint;
  /**
   * Who holds it, on a fleet's list of what its members can craft. Absent on
   * the public catalogue, which knows of no owner but the reader.
   */
  owners?: FleetBlueprintOwner[];
  ownerCount?: number;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

// Every value the catalogue can be narrowed by is a link that narrows it, the
// way a component row's manufacturer and category are. `page` is dropped: the
// row that was clicked is almost never on the same page of a smaller set.
const filterLink = (key: string, value: string | string[]) => ({
  name: route.name as string,
  query: { ...route.query, page: undefined, [key]: value },
});

const { format: formatCraftTime } = useCraftTime();

// What it eats.
const materials = computed<RowListItemChip[]>(() =>
  (props.blueprint.materials || []).map((material) => ({
    key: material.slug,
    label: material.name,
    to: filterLink("consumingCommodityIn", [material.slug]),
  })),
);

const OWNERS_SHOWN = 3;

const shownOwners = computed(() => (props.owners || []).slice(0, OWNERS_SHOWN));

const extraOwners = computed(() =>
  Math.max((props.ownerCount ?? (props.owners || []).length) - OWNERS_SHOWN, 0),
);

// The fleet's name for somebody where it has one, and their username
// otherwise -- a nickname is optional and most memberships carry none.
const ownerName = (owner: FleetBlueprintOwner) =>
  owner.nickname || owner.username;

// Which sides of the law hand this recipe out, as the API states them: each
// named once, in the order lawful, neutral, outlaw. An older cached payload
// carries none, so this stands in for the field rather than assuming it.
const ALIGNMENT_TONES: Record<string, RowListItemTonesEnum> = {
  lawful: RowListItemTonesEnum.PRIMARY,
  outlaw: RowListItemTonesEnum.DANGER,
};

const tags = computed<RowListItemTag[]>(() =>
  (props.blueprint.sourceAlignments || []).map((alignment) => ({
    key: alignment,
    label: t(`labels.blueprint.alignments.${alignment}`),
    to: filterLink("sourceAlignmentIn", [alignment]),
    tone: ALIGNMENT_TONES[alignment],
  })),
);

// What the recipe makes, and where that lives. 5 of the 1,607 recipes in the
// current build resolve to no catalogue row at all -- four mission carryables
// and one entity class present in no file -- so this is genuinely absent
// rather than merely unset.
const craftableRoute = computed(() =>
  catalogueItemRoute(props.blueprint.craftable),
);

const badges = computed<RowListItemBadge[]>(() => {
  const list: RowListItemBadge[] = [];

  // Said on the row, not only on the detail page. 901 of 1,607 recipes have no
  // stated source, so "can I actually go and get this" is a question the list
  // itself has to answer.
  if (props.blueprint.sourceUnknown) {
    list.push({
      key: "no-source",
      value: t("labels.blueprint.noKnownSource"),
      quiet: true,
    });
  }

  // The formatted string rather than the raw seconds decides it: a recipe whose
  // time rounds away to nothing has no figure to show, and an empty badge reads
  // as a rendering fault.
  const craftTime = formatCraftTime(props.blueprint.craftTime);

  if (craftTime) {
    list.push({
      key: "craft-time",
      label: t("labels.blueprint.craftTime"),
      value: craftTime,
    });
  }

  if (props.blueprint.slotCount) {
    list.push({
      key: "slots",
      label: t("labels.blueprint.slots"),
      value: String(props.blueprint.slotCount),
    });
  }

  return list;
});
</script>

<template>
  <RowListItem
    class="blueprint-row"
    :to="
      blueprint.slug
        ? { name: 'blueprint', params: { slug: blueprint.slug } }
        : undefined
    "
    :chips="materials"
    :tags="tags"
    :badges="badges"
  >
    <template #name>{{ blueprint.name }}</template>

    <template #sub>
      <router-link
        v-if="blueprint.craftable"
        :to="filterLink('craftableTypeEq', blueprint.craftable.type)"
      >
        {{ t(`labels.blueprint.craftableTypes.${blueprint.craftable.type}`) }}
      </router-link>
      <router-link v-if="craftableRoute" :to="craftableRoute">
        {{ blueprint.craftable?.name }}
      </router-link>
      <span v-else-if="blueprint.craftable">{{
        blueprint.craftable.name
      }}</span>
    </template>

    <!-- Who in the fleet holds it. Capped at three names with a count for the
         rest: a row is one line, and "and 11 others" is the part a reader acts
         on anyway. -->
    <span v-if="shownOwners.length" class="blueprint-row__owners">
      <router-link
        v-for="owner in shownOwners"
        :key="owner.userId"
        class="blueprint-row__owner"
        :to="{ name: 'hangar-public', params: { username: owner.username } }"
      >
        {{ ownerName(owner) }}
      </router-link>
      <span v-if="extraOwners" class="blueprint-row__owner-more">
        +{{ extraOwners }}
      </span>
    </span>

    <template #actions>
      <BlueprintOwnToggle :blueprint="blueprint" variant="row" />
    </template>
  </RowListItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
