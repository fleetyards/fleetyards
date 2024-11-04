<script lang="ts">
export default {
  name: "SearchHistory",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import PanelHeading from "@/shared/components/Panel/Heading/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useSearchStore } from "@/frontend/stores/search";
import { storeToRefs } from "pinia";
import { useI18n } from "@/shared/composables/useI18n";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

const { t } = useI18n();

const searchStore = useSearchStore();

const { history } = storeToRefs(searchStore);

const mobile = useMobile();

const page = ref(1);
const perPage = ref(30);

const filteredHistory = computed(() => {
  return history.value.slice(0, page.value * perPage.value);
});

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

<template>
  <div v-if="history.length" class="row justify-content-center">
    <div class="col-12 col-lg-6">
      <Panel slim>
        <PanelHeading level="h2">
          {{ t("headlines.searchHistory") }}
          <template #actions>
            <Btn
              v-if="history.length"
              :size="BtnSizesEnum.SMALL"
              :inline="true"
              :aria-label="t('actions.clearHistory')"
              @click="resetHistory"
            >
              <i v-if="mobile" class="fa fa-times" />
              <template v-else>
                {{ t("actions.clearHistory") }}
              </template>
            </Btn>
          </template>
        </PanelHeading>
        <div class="search-history">
          <div
            v-for="(entry, index) in filteredHistory"
            :key="index"
            class="search-history-item"
            @click="restore(entry.search)"
          >
            {{ entry.search }}
          </div>
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

<style lang="scss" scoped>
@import "index";
</style>
