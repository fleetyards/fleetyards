<script lang="ts">
export default {
  name: "CatalogueTokenLink",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { type CatalogueItemRef } from "@/frontend/components/CatalogueItemPopover/types";
import MissionText from "@/frontend/components/MissionText/index.vue";
import { catalogueTokenIcon } from "@/shared/utils/CatalogueTokens";

type Props = {
  item: CatalogueItemRef;
};

defineProps<Props>();
</script>

<!-- An item named in text, marked as one the way a game marks an item link:
     its type's icon, then its name in brackets. -->
<template>
  <span class="catalogue-token-link" :data-type="item.type">
    <i :class="catalogueTokenIcon(item.type)" aria-hidden="true" />
    <!-- A mission's name is a game template: its placeholders read as what
         the game will fill in, the way the mission list shows them. -->
    <CatalogueItemPopover :item="item" link-class="catalogue-token-link__link"
      >[<MissionText
        v-if="item.type === 'GameMission'"
        :text="item.name"
      /><template v-else>{{ item.name }}</template
      >]</CatalogueItemPopover
    >
  </span>
</template>

<style lang="scss" scoped>
// A flex row, so the markup's whitespace adds no spaces: the gap between icon
// and name is this one, and nothing sits between the name and what follows.
.catalogue-token-link {
  display: inline-flex;
  align-items: baseline;
  gap: 0.25em;
  white-space: nowrap;

  i {
    font-size: 0.85em;
    color: var(--color-primary, #428bca);
  }

  :deep(.catalogue-token-link__link) {
    color: var(--color-primary, #428bca);
    font-weight: 600;
    text-decoration: none;
    transition: color 150ms ease;

    &:hover,
    &:focus-visible {
      color: var(--color-primary-tint, #6aa5dc);
      text-decoration: none;
    }
  }
}
</style>
