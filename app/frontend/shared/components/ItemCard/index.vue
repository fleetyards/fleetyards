<script lang="ts">
export default {
  name: "ItemCard",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Collapsed from "@/shared/components/Collapsed.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import { type RowListItemBadge } from "@/shared/components/RowListItem/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  type ItemCardFacet,
  type ItemCardMaker,
  type ItemCardStat,
} from "@/shared/components/ItemCard/types";

type Props = {
  // Absent for a record the game never named: it has no slug, and
  // `router-link` throws on a missing required param.
  to?: RouteLocationRaw;
  image?: string;
  maker?: ItemCardMaker;
  categories?: ItemCardFacet[];
  badges?: RowListItemBadge[];
  stats?: ItemCardStat[];
  // The figures under the picture, hidden until asked for as on a ship card.
  details?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  image: undefined,
  maker: undefined,
  categories: () => [],
  badges: () => [],
  stats: () => [],
  details: false,
});

const slots = defineSlots<{
  name: () => unknown;
  // Stands in for the picture, which most components do not have.
  icon?: () => unknown;
  // States laid over the picture's corner beside the categories, such as
  // "retired".
  tags?: () => unknown;
  actions?: () => unknown;
}>();

const hasDetails = computed(
  () => props.badges.length > 0 || props.stats.length > 0,
);
</script>

<template>
  <Panel class="item-card" data-test="item-card">
    <!-- The picture fills the card behind the heading, as on a ship card, but
         is drawn here rather than as the panel's background: that one is
         cropped to cover, and these renders are cut tight to the item on a
         transparent ground, so an upright magazine would lose both ends. -->
    <div
      class="item-card__hero"
      :class="{
        'item-card__hero--joined': details && hasDetails,
      }"
    >
      <PanelHeading
        shadow="top"
        :level="HeadingLevelEnum.H2"
        :size="HeadingSizeEnum.LG"
        compact
        class="item-card__heading"
      >
        <router-link v-if="to" :to="to" class="item-card__name">
          <slot name="name" />
        </router-link>
        <span v-else class="item-card__name">
          <slot name="name" />
        </span>

        <template v-if="slots.actions" #actions>
          <slot name="actions" />
        </template>
      </PanelHeading>

      <!-- Below the heading rather than behind it, so a long name takes room
           from the picture instead of covering it. -->
      <div class="item-card__stage">
        <img
          v-if="image"
          class="item-card__image"
          :src="image"
          alt=""
          loading="lazy"
          data-test="item-card-image"
        />
        <span v-else class="item-card__icon">
          <slot name="icon" />
        </span>

        <!-- Over the picture's foot, as the ship card's focus sits: what it is
             filed under on the left, who makes it on the right. Each narrows
             the list. -->
        <div
          v-if="categories.length || slots.tags || maker"
          class="item-card__overlay"
        >
          <span class="item-card__tags" data-test="item-card-categories">
            <template v-for="category in categories" :key="category.key">
              <router-link v-if="category.to" :to="category.to">
                <Pill :variant="PillVariantsEnum.NEUTRAL">
                  {{ category.label }}
                </Pill>
              </router-link>
              <Pill v-else :variant="PillVariantsEnum.NEUTRAL">
                {{ category.label }}
              </Pill>
            </template>
            <slot name="tags" />
          </span>

          <component
            :is="maker.to ? 'router-link' : 'span'"
            v-if="maker"
            v-tooltip="maker.name"
            :to="maker.to"
            :aria-label="maker.name"
            class="item-card__maker"
            data-test="item-card-maker"
          >
            <!-- The mark on its own, or the short code in a pill where there is
                 none: the name in full ran into the category pills on a narrow
                 card, and the tooltip still gives it. -->
            <img
              v-if="maker.logo"
              class="item-card__logo"
              :src="maker.logo"
              alt=""
              loading="lazy"
              data-test="item-card-logo"
            />
            <Pill v-else :variant="PillVariantsEnum.NEUTRAL">
              {{ maker.code || maker.name }}
            </Pill>
          </component>
        </div>
      </div>
    </div>

    <Collapsed v-if="hasDetails" :visible="details">
      <PanelBody class="item-card__body" data-test="item-card-details">
        <div v-if="badges.length" class="metrics-card__hero">
          <div
            v-for="badge in badges"
            :key="badge.key"
            class="metrics-card__tile"
            :data-test="`item-card-badge-${badge.key}`"
          >
            <div v-if="badge.label" class="metrics-card__tile__label">
              {{ badge.label }}
            </div>
            <div class="metrics-card__tile__value">{{ badge.value }}</div>
          </div>
        </div>

        <div v-if="stats.length" class="metrics-card__rows">
          <div
            v-for="stat in stats"
            :key="stat.label"
            class="metrics-card__row"
            data-test="item-card-stat"
          >
            <span class="metrics-card__row__label">{{ stat.label }}</span>
            <span class="metrics-card__row__value">{{ stat.value }}</span>
          </div>
        </div>
      </PanelBody>
    </Collapsed>
  </Panel>
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

.item-card {
  display: flex;
  flex-direction: column;
}

// One shape for a card with a one-line name. The ratio is only a floor here on
// purpose: a longer name grows the box rather than eating the picture, and the
// grid stretches the row's other cards to match. The picture itself is out of
// the flow in the stage, so however tall a render is it cannot grow anything.
.item-card__hero {
  display: flex;
  flex: 1 0 auto;
  flex-direction: column;
  aspect-ratio: 4 / 3;
  overflow: hidden;
  // Lit from behind the item and falling off to the frame: the renders are
  // dark metal on a transparent ground, and flat near-black swallowed them.
  background: radial-gradient(
    ellipse at 50% 60%,
    color-mix(in srgb, var(--color-gray-light, #959595) 32%, transparent),
    rgb(0 0 0 / 0.35) 80%
  );
  border-radius: var(--radius-surface-inner, 14px);
}

.item-card__hero--joined {
  border-bottom-left-radius: 0;
  border-bottom-right-radius: 0;
}

// A floor so a narrow card with a two-line name still shows the item.
.item-card__stage {
  position: relative;
  flex: 1 0 120px;
}

.item-card__image {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  padding: 0 16px 16px;
  object-fit: contain;
}

.item-card__icon {
  --hardpoint-category-icon-size: 64px;
  --equipment-icon-size: 64px;

  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--color-primary, #428bca);
  opacity: 0.8;
}

.item-card__name {
  overflow-wrap: anywhere;
}

.item-card__overlay {
  position: absolute;
  right: 10px;
  bottom: 10px;
  left: 10px;
  z-index: 1;
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 6px;
}

// They wrap rather than run off a narrow card.
.item-card__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  min-width: 0;
}

.item-card__maker {
  flex: none;
}

.item-card__logo {
  display: block;
  width: 48px;
  height: 48px;
  object-fit: contain;
  // Lifted off the lit ground, which a dark mark would otherwise sink into.
  filter: drop-shadow(0 1px 3px rgb(0 0 0 / 0.7));
}

.item-card__body {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px 16px 16px;
}

.item-card__body .metrics-card__hero {
  margin-bottom: 0;
}

// The hero's tiles are sized for a ship page; three would stack one per line
// in a card this narrow.
.item-card__body .metrics-card__tile {
  flex-basis: 60px;
  padding: 8px 10px;
}

.item-card__body .metrics-card__tile__label {
  margin-bottom: 5px;
  font-size: 10px;
  letter-spacing: 0.12em;
}
</style>
