<template>
  <div
    v-if="pagination && (perPageSelectable || pagination.totalPages > 1)"
    class="pagination"
  >
    <BtnGroup :inline="inline">
      <PerPageDropdown
        v-if="perPageSelectable"
        variant="dropdown"
        size="small"
        :per-page="internalPerPage"
        :steps="pagination.perPageSteps"
        in-group
        @change="updatePerPage"
      />
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(1)"
        :disabled="currentPage <= 1"
        route-active-class=""
        in-group
      >
        <i class="fa fa-chevron-double-left" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(currentPage - 1)"
        :disabled="currentPage <= 1"
        route-active-class=""
        in-group
      >
        <i class="fa fa-chevron-left" />
      </Btn>
      <span class="pagination-pages" style="flex-grow: none">
        {{
          i18n?.t("paginator.labels.pages", {
            page: String(currentPage),
            total: String(pagination.totalPages || 1),
          })
        }}
      </span>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(currentPage + 1)"
        :disabled="currentPage >= pagination.totalPages"
        route-active-class=""
        in-group
      >
        <i class="fa fa-chevron-right" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(pagination.totalPages)"
        :disabled="currentPage >= pagination.totalPages"
        route-active-class=""
        in-group
      >
        <i class="fa fa-chevron-double-right" />
      </Btn>
    </BtnGroup>
  </div>
</template>

<script lang="ts" setup>
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import PerPageDropdown from "./PerPageDropdown/index.vue";
import { type BaseList } from "@/services/fyApi";
import { useRoute } from "vue-router";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

type Props = {
  queryResultRef: BaseList;
  updatePerPage?: (perPage: number | string) => void;
  perPage?: number | string;
  inline?: boolean;
  hash?: string;
};

const props = withDefaults(defineProps<Props>(), {
  updatePerPage: undefined,
  perPage: undefined,
  inline: false,
  hash: undefined,
});

const pagination = computed(() => props.queryResultRef.meta.pagination);

const perPageSelectable = computed(
  () => !!pagination.value?.perPageSteps && !!props.updatePerPage,
);

const internalPerPage = computed(
  () => props.perPage || pagination.value?.defaultPerPage,
);

const i18n = inject<I18nPluginOptions>("i18n");

const route = useRoute();

const pageRoute = (page: number) => ({
  query: { page: String(page), q: route.query.q },
  hash: props.hash,
});

const currentPage = computed(() => {
  const page = Number(route.query.page);
  return Number.isNaN(page) ? 1 : page;
});
</script>

<script lang="ts">
export default {
  name: "AppPaginator",
};
</script>

<style lang="scss" scoped>
@import "./index.scss";
</style>
