<script lang="ts">
export default {
  name: "AllSupporters",
};
</script>

<script lang="ts" setup>
import type { Supporter } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  supporters: Supporter[];
  anonymousCount: number;
}

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <div class="all-supporters" data-test="all-supporters">
    <h2 class="all-supporters__headline">
      {{ t("headlines.allSupporters") }}
    </h2>
    <ul class="all-supporters__list">
      <li
        v-for="supporter in supporters"
        :key="supporter.displayName"
        class="all-supporters__item"
      >
        <router-link
          v-if="supporter.username"
          :to="{
            name: 'hangar-public',
            params: { username: supporter.username },
          }"
        >
          {{ supporter.displayName }}
        </router-link>
        <span v-else>{{ supporter.displayName }}</span>
      </li>
      <li
        v-if="anonymousCount"
        class="all-supporters__item all-supporters__item--anonymous"
        data-test="anonymous-supporters"
      >
        {{ t("texts.support.anonymousSupporters", { count: anonymousCount }) }}
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.all-supporters__headline {
  margin: 0 0 6px;
  font-size: 0.9rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  opacity: 0.7;
}

.all-supporters__list {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.all-supporters__item {
  font-size: 0.9rem;
}

.all-supporters__item--anonymous {
  opacity: 0.7;
}
</style>
