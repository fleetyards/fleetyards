<template>
  <div class="row justify-content-center">
    <div class="col-12 col-lg-6">
      <Panel>
        <div class="panel-heading panel-heading-with-actions">
          <h2 class="panel-title">
            {{ t("headlines.searchHistory") }}
          </h2>
          <div class="panel-heading-actions">
            <Btn
              v-if="history.length"
              size="small"
              :inline="true"
              :aria-label="t('actions.clearHistory')"
              @click="resetHistory"
            >
              <i v-if="mobile" class="fa fa-times" />
              <template v-else>
                {{ t("actions.clearHistory") }}
              </template>
            </Btn>
          </div>
        </div>
        <div class="search-history">
          <template v-if="history.length">
            <div
              v-for="(entry, index) in filteredHistory"
              :key="index"
              class="search-history-item"
              @click="restore(entry.search)"
            >
              {{ entry.search }}
            </div>
          </template>
          <div v-else class="search-history-empty">...</div>
        </div>
      </Panel>
      <div class="text-center">
        <Btn v-if="history.length > page * perPage" @click="showMore">
          {{ t("actions.showMore") }}
        </Btn>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { ref, computed, defineEmits } from "vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import { useAppStore } from "@/frontend/stores/App";
import { useSearchStore } from "@/frontend/stores/Search";
import { useI18n } from "@/frontend/composables/useI18n";
import { storeToRefs } from "pinia";

const { t } = useI18n();

const page = ref<number>(1);

const perPage = ref<number>(30);

const { mobile } = storeToRefs(useAppStore());

const searchStore = useSearchStore();

const { history } = storeToRefs(searchStore);

const filteredHistory = computed(() =>
  history.value.slice(0, page.value * perPage.value)
);

const emit = defineEmits(["restore"]);

const restore = (search: string) => {
  emit("restore", search);
};

const showMore = () => {
  page.value += 1;
};

const resetHistory = () => {
  searchStore.$reset();
};
</script>

<script lang="ts">
export default {
  name: "SearchHistory",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
