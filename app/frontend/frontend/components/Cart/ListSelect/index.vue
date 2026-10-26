<script lang="ts">
export default {
  name: "CartListSelect",
};
</script>

<script lang="ts" setup>
import { useRoute, useRouter } from "vue-router";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useCartLists } from "@/services/fyApi";

type Props = {
  // The list the page shows, which need not be the active one.
  listId?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  listId: undefined,
});

const { t } = useI18n();

const route = useRoute();

const router = useRouter();

const { data: lists } = useCartLists();

const options = computed(() =>
  (lists.value ?? []).map((list) => ({
    value: list.id,
    label: `${list.name} (${list.itemsCount})`,
  })),
);

// Only shows the list; making it active is a list action of its own. The
// active list is the page's default, so it needs no address of its own.
const show = (id?: string | null) => {
  if (!id || id === props.listId) {
    return;
  }

  const list = lists.value?.find((entry) => entry.id === id);

  void router.replace({
    name: "cart",
    query: { ...route.query, list: list?.active ? undefined : id },
  });
};
</script>

<template>
  <BaseSelect
    v-if="options.length"
    :model-value="listId"
    name="cart-list"
    :options="options"
    :label="t('cart.lists.shown')"
    :nullable="false"
    no-label
    unsorted
    class="cart-list-select"
    data-test="cart-list-select"
    @update:model-value="show"
  />
</template>

<style lang="scss" scoped>
// A header control: the field's own bottom margin would push it off the
// buttons' line.
.cart-list-select {
  min-width: 200px;
  margin-bottom: 0;
}
</style>
