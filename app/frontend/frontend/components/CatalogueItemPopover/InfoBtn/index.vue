<script lang="ts">
export default {
  name: "CatalogueItemInfoBtn",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import {
  type CatalogueItemRef,
  type CatalogueRecord,
} from "@/frontend/components/CatalogueItemPopover/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  item: CatalogueItemRef;
  record?: CatalogueRecord;
};

withDefaults(defineProps<Props>(), {
  record: undefined,
});

const { t } = useI18n();
</script>

<template>
  <CatalogueItemPopover :item="item" :record="record" read-only>
    <button
      type="button"
      class="catalogue-item-info-btn"
      :aria-label="t('labels.statsCard.show', { name: item.name })"
      data-test="catalogue-item-info"
    >
      <i class="fa-regular fa-circle-info" />
    </button>
  </CatalogueItemPopover>
</template>

<style scoped>
@reference "../../../../entrypoints/tailwind.css";

.catalogue-item-info-btn {
  @apply text-text relative m-0 flex cursor-help items-center justify-center p-0;
  @apply bg-gray-black/90 border-edge rounded-control-bare border text-[12px];
  width: 22px;
  height: 22px;
}

/* A finger's reach, since a miss lands on the card's toggle and picks it. */
.catalogue-item-info-btn::before {
  content: "";
  position: absolute;
  inset: -7px;
}

.catalogue-item-info-btn:hover {
  @apply text-lifted;
}

.catalogue-item-info-btn:focus-visible {
  @apply outline-primary outline-2;
  outline-offset: 1px;
}
</style>
