<script lang="ts">
export default {
  name: "BlueprintStatsCard",
};
</script>

<script lang="ts" setup>
import { type RouteLocationRaw } from "vue-router";
import StatsCard from "@/frontend/components/StatsCard/index.vue";
import {
  type StatsCardBadge,
  type StatsCardStatus,
} from "@/frontend/components/StatsCard/types";
import { useCraftTime } from "@/frontend/composables/useCraftTime";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import { useI18n } from "@/shared/composables/useI18n";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";
import { type Blueprint } from "@/services/fyApi";

type Props = {
  blueprint?: Blueprint;
  name?: string;
  to?: RouteLocationRaw | false;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  blueprint: undefined,
  name: undefined,
  to: undefined,
  loading: false,
});

const emit = defineEmits<{ navigate: [] }>();

const { t } = useI18n();
const { format: formatCraftTime } = useCraftTime();

const badges = computed<StatsCardBadge[]>(() => {
  const blueprint = props.blueprint;
  if (!blueprint) return [];

  const craftTime = formatCraftTime(blueprint.craftTime);

  return [
    craftTime
      ? {
          key: "craftTime",
          label: t("labels.blueprint.craftTime"),
          value: craftTime,
        }
      : undefined,
    blueprint.slotCount
      ? {
          key: "slots",
          label: t("labels.blueprint.slots"),
          value: String(blueprint.slotCount),
        }
      : undefined,
  ].filter((badge): badge is StatsCardBadge => !!badge);
});

const category = computed(() =>
  props.blueprint?.craftable?.type
    ? t(`labels.blueprint.craftableTypes.${props.blueprint.craftable.type}`)
    : undefined,
);

const status = computed<StatsCardStatus | undefined>(() =>
  props.blueprint?.retired
    ? { label: t("labels.blueprint.retired"), tone: "neutral" }
    : undefined,
);

const craftable = computed(() => props.blueprint?.craftable);

const craftableRoute = computed(() => catalogueItemRoute(craftable.value));

const materials = computed(() => props.blueprint?.materials ?? []);

const ownRoute = computed(() =>
  props.blueprint?.slug
    ? { name: "blueprint", params: { slug: props.blueprint.slug } }
    : undefined,
);
</script>

<template>
  <StatsCard
    compact
    :title="blueprint?.name || name || ''"
    kind="Blueprint"
    :category="category"
    :status="status"
    :badges="badges"
    :to="to === false ? undefined : (to ?? ownRoute)"
    :loading="loading"
    :unavailable="!loading && !blueprint"
    @navigate="emit('navigate')"
  >
    <template v-if="craftable?.name || materials.length" #default>
      <div v-if="craftable?.name" class="blueprint-stats-card__section">
        <span class="blueprint-stats-card__label">{{
          t("labels.blueprint.makes")
        }}</span>
        <!-- A link, not another hover card: a card opening inside a card would
           leave the reader two layers deep in something meant as a glance. -->
        <router-link
          v-if="craftableRoute"
          :to="craftableRoute"
          class="blueprint-stats-card__makes blueprint-stats-card__makes--link"
          data-test="blueprint-stats-card-makes"
          @click="emit('navigate')"
        >
          <i :class="catalogueTokenIcon(craftable.type)" aria-hidden="true" />
          [{{ craftable.name }}]
        </router-link>
        <span v-else class="blueprint-stats-card__makes">
          <i :class="catalogueTokenIcon(craftable.type)" aria-hidden="true" />
          [{{ craftable.name }}]
        </span>
      </div>

      <div v-if="materials.length" class="blueprint-stats-card__section">
        <span class="blueprint-stats-card__label">
          {{ t("labels.blueprint.materials") }}
        </span>
        <div class="blueprint-stats-card__materials">
          <router-link
            v-for="material in materials"
            :key="material.id"
            :to="{ name: 'commodity', params: { slug: material.slug } }"
            class="blueprint-stats-card__material"
            @click="emit('navigate')"
          >
            {{ material.name }}
          </router-link>
        </div>
      </div>
    </template>
  </StatsCard>
</template>

<style lang="scss" scoped>
@import "@/shared/components/catalogueToken";
@import "@/frontend/components/StatsCard/label";

.blueprint-stats-card {
  &__label {
    @include stats-card-label;
  }

  &__section {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  &__makes {
    @include catalogue-token;
    align-self: flex-start;
    font-size: 0.85rem;
    font-weight: 600;
    color: var(--color-primary, #428bca);
  }

  &__makes--link {
    @include catalogue-token-link;
  }

  &__materials {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
  }

  &__material {
    padding: 3px 9px;
    border: 1px solid var(--color-edge, rgb(122 130 136 / 0.5));
    border-radius: var(--radius-control-bare, 6px);
    background: rgb(0 0 0 / 0.2);
    font-size: 0.8rem;
    color: var(--color-text, #c8c8c8);
    text-decoration: none;
    transition:
      border-color 150ms ease,
      color 150ms ease;

    &:hover,
    &:focus-visible {
      border-color: var(--color-primary, #428bca);
      color: var(--color-lifted, #eee);
    }
  }
}
</style>
