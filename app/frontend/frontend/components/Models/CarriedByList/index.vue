<script lang="ts">
export default {
  name: "ModelsCarriedByList",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import { type ModelExtendedCarriedByItem } from "@/services/fyApi";

type Props = {
  carriedBy: ModelExtendedCarriedByItem[];
};

const props = defineProps<Props>();

const { t } = useI18n();

// Grouped by the kind of berth, because "it fits in a garage" and "it fits in a
// hangar" are different answers and a flat list of names hides which is which.
const groups = computed(() => {
  const byDockType = new Map<string, ModelExtendedCarriedByItem[]>();

  props.carriedBy.forEach((item) => {
    const entries = byDockType.get(item.dockType) || [];
    entries.push(item);
    byDockType.set(item.dockType, entries);
  });

  return [...byDockType.entries()].map(([dockType, items]) => ({
    dockType,
    items,
  }));
});
</script>

<template>
  <template v-if="carriedBy.length">
    <hr />
    <div id="carried-by" class="row">
      <div class="col-12">
        <h2 class="text-uppercase">
          {{ t("labels.model.carriedBy") }}
        </h2>
        <p class="carried-by__hint">
          {{ t("texts.model.carriedByHint") }}
        </p>

        <div v-for="group in groups" :key="`carried-by-${group.dockType}`">
          <h3 class="carried-by__dock-type">
            {{ t(`labels.dockTypes.${group.dockType}`) }}
          </h3>
          <ul class="carried-by__list">
            <li v-for="item in group.items" :key="`carried-by-${item.slug}`">
              <router-link :to="{ name: 'ship', params: { slug: item.slug } }">
                {{ item.name }}
              </router-link>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </template>
</template>

<style lang="scss" scoped>
.carried-by__hint {
  margin-bottom: 1rem;
}

.carried-by__dock-type {
  margin-bottom: 0.5rem;
  font-size: 1rem;
  text-transform: uppercase;
}

.carried-by__list {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem 1.5rem;
  padding: 0;
  margin: 0 0 1.5rem;
  list-style: none;
}
</style>
