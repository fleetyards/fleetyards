<script lang="ts">
export default {
  name: "EmptyTable",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name?: string;
};

withDefaults(defineProps<Props>(), {
  name: undefined,
});

const { t } = useI18n();
</script>

<template>
  <Heading class="empty__headline">
    <slot>
      <template v-if="name">
        {{ t("emptyBox.headlines.forName", { name: name }) }}
      </template>
      <template v-else>
        {{ t("emptyBox.headlines.default") }}
      </template>
    </slot>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
