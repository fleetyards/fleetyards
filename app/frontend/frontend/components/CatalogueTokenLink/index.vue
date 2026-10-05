<script lang="ts">
export default {
  name: "CatalogueTokenLink",
};
</script>

<script lang="ts" setup>
import AppIcon from "@/shared/components/AppIcon/index.vue";
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
    <AppIcon :icon="catalogueTokenIcon(item.type)" aria-hidden="true" />
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
@import "@/shared/components/catalogueToken";

.catalogue-token-link {
  @include catalogue-token;

  :deep(.catalogue-token-link__link) {
    @include catalogue-token-link;
  }
}
</style>
