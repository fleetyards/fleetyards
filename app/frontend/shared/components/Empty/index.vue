<script lang="ts">
export default {
  name: "Empty",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import EmptyHeadline from "./Headline/index.vue";
import EmptyActions from "./Actions/index.vue";
import EmptyInfo from "./Info/index.vue";
import { useRoute } from "vue-router";
import { EmptyVariantsEnum } from "./types";

type Props = {
  variant?: `${EmptyVariantsEnum}`;
  name?: string;
  title?: string;
  inline?: boolean;
  hideActions?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  variant: EmptyVariantsEnum.DEFAULT,
  name: undefined,
  title: undefined,
  inline: false,
  hideActions: false,
});

const route = useRoute();

const isPagePresent = computed(
  () => !!route.query.page && Number(route.query.page) > 1,
);

const isQueryPresent = computed(
  () =>
    Object.keys(route.query?.q || {}).length > 0 ||
    Object.keys(route.query || {}).length > 0 ||
    isPagePresent.value,
);

const cssClasses = computed(() => {
  return {
    "empty-list-box": props.variant === EmptyVariantsEnum.BOX,
    "empty-list-inline": props.inline,
  };
});
</script>

<template>
  <div class="empty-list" :class="cssClasses">
    <Box v-if="variant === EmptyVariantsEnum.BOX" class="info" :large="true">
      <EmptyHeadline :name="name">
        <slot name="headline" :query-present="isQueryPresent" />
      </EmptyHeadline>
      <slot name="info" :query-present="isQueryPresent">
        <EmptyInfo :query-present="isQueryPresent" />
      </slot>
      <template v-if="isQueryPresent" #footer>
        <EmptyActions
          v-if="!props.hideActions"
          :query-present="isQueryPresent"
          :page-present="isPagePresent"
        >
          <slot name="actions" :query-present="isQueryPresent"></slot>
        </EmptyActions>
      </template>
    </Box>
    <template v-else>
      <EmptyHeadline :name="name" />
      <slot name="info" :query-present="isQueryPresent">
        <EmptyInfo :query-present="isQueryPresent" />
      </slot>
      <EmptyActions
        v-if="!props.hideActions"
        :query-present="isQueryPresent"
        :page-present="isPagePresent"
      >
        <slot name="actions" :query-present="isQueryPresent"></slot>
      </EmptyActions>
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
