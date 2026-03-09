<script lang="ts">
export default {
  name: "ListGroup",
};
</script>

<script lang="ts" setup generic="T extends { id: string }">
import Empty from "@/shared/components/Empty/index.vue";
import Loader from "@/shared/components/Loader/index.vue";

type Props = {
  items: T[];
  loading?: boolean;
  emptyName?: string;
};

withDefaults(defineProps<Props>(), {
  loading: false,
  emptyName: "entries",
});
</script>

<template>
  <div class="list-group">
    <TransitionGroup name="list">
      <slot name="prepend" />

      <div v-for="item in items" :key="item.id" class="list-group__item">
        <div class="list-group__row">
          <div class="list-group__content">
            <slot name="display" :item="item" />
          </div>
          <div class="list-group__actions">
            <slot name="actions" :item="item" />
          </div>
        </div>
        <slot name="expanded" :item="item" />
      </div>
    </TransitionGroup>

    <Loader :loading="loading" />

    <Empty
      v-if="!items.length && !loading"
      variant="box"
      hide-actions
      :name="emptyName"
    />
  </div>
</template>

<style lang="scss">
@import "index";
</style>
