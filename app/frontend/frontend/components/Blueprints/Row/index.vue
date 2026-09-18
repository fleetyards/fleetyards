<script lang="ts">
export default {
  name: "BlueprintRow",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { useCraftTime } from "@/frontend/composables/useCraftTime";
import { type Blueprint } from "@/services/fyApi";

type Props = {
  blueprint: Blueprint;
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

const MATERIALS_SHOWN = 4;

const shownMaterials = computed(() =>
  (props.blueprint.materials || []).slice(0, MATERIALS_SHOWN),
);

const extraMaterials = computed(() =>
  Math.max((props.blueprint.materials || []).length - MATERIALS_SHOWN, 0),
);

// What the recipe makes, and where that lives. 5 of the 1,607 recipes in the
// current build resolve to no catalogue row at all -- four mission carryables
// and one entity class present in no file -- so this is genuinely absent
// rather than merely unset.
const craftableRoute = computed(() => {
  const craftable = props.blueprint.craftable;
  if (!craftable) return undefined;

  if (craftable.type === "Component") {
    return { name: "component", params: { slug: craftable.slug } };
  }

  // Equipment and commodities have no detail page yet -- they are list-only
  // endpoints. Linking them would land on the app's not-found, so they read
  // as plain text until those tenants exist.
  return undefined;
});
</script>

<template>
  <div class="blueprint-row">
    <span class="blueprint-row__main">
      <router-link
        v-if="blueprint.slug"
        class="blueprint-row__name"
        :to="{ name: 'blueprint', params: { slug: blueprint.slug } }"
      >
        {{ blueprint.name }}
      </router-link>
      <span v-else class="blueprint-row__name">{{ blueprint.name }}</span>

      <span class="blueprint-row__sub">
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
      </span>
    </span>

    <!-- What it eats. Capped at four names with a count for the rest: the
         busiest recipe uses four materials, but the cap keeps a row one line
         if a future patch adds more. -->
    <span v-if="shownMaterials.length" class="blueprint-row__materials">
      <router-link
        v-for="material in shownMaterials"
        :key="material.slug"
        class="blueprint-row__material"
        :to="filterLink('consumingCommodityIn', [material.slug])"
      >
        {{ material.name }}
      </router-link>
      <span v-if="extraMaterials" class="blueprint-row__material-more">
        +{{ extraMaterials }}
      </span>
    </span>

    <!-- Said on the row, not only on the detail page. 901 of 1,607 recipes
         have no stated source, so "can I actually go and get this" is a
         question the list itself has to answer. -->
    <span class="blueprint-row__badges">
      <span
        v-if="blueprint.sourceUnknown"
        class="blueprint-row__badge blueprint-row__badge--quiet"
      >
        <span class="blueprint-row__badge-value">
          {{ t("labels.blueprint.noKnownSource") }}
        </span>
      </span>

      <span v-if="blueprint.craftTime" class="blueprint-row__badge">
        <span class="blueprint-row__badge-label">
          {{ t("labels.blueprint.craftTime") }}
        </span>
        <span class="blueprint-row__badge-value">
          {{ formatCraftTime(blueprint.craftTime) }}
        </span>
      </span>

      <span v-if="blueprint.slotCount" class="blueprint-row__badge">
        <span class="blueprint-row__badge-label">
          {{ t("labels.blueprint.slots") }}
        </span>
        <span class="blueprint-row__badge-value">{{
          blueprint.slotCount
        }}</span>
      </span>
    </span>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
