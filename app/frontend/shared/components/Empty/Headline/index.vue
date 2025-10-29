<script lang="ts">
export default {
  name: "EmptyTable",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";

type Props = {
  name?: string;
};

withDefaults(defineProps<Props>(), {
  name: undefined,
});

const { t } = useI18n();
</script>

<template>
  <Heading class="empty__headline" mt :size="HeadingSizeEnum.HERO_SM">
    <slot>
      <template v-if="name">
        {{ t("empty.headlines.forName", { name: name }) }}
      </template>
      <template v-else>
        {{ t("empty.headlines.default") }}
      </template>
    </slot>
  </Heading>
</template>

<style lang="scss" scoped>
@import "index";
</style>
