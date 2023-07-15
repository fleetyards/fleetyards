<template>
  <div v-if="perPageSelectable || pagination.totalPages > 1" class="pagination">
    <BtnGroup :inline="inline">
      <PerPageDropdown
        v-if="perPageSelectable"
        variant="dropdown"
        size="small"
        :per-page="internalPerPage"
        :steps="pagination.perPageSteps"
        @change="updatePerPage"
      />
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(1)"
        :disabled="pagination.currentPage <= 1"
        route-active-class=""
      >
        <i class="fa fa-chevron-double-left" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(pagination.currentPage - 1)"
        :disabled="pagination.currentPage <= 1"
        route-active-class=""
      >
        <i class="fa fa-chevron-left" />
      </Btn>
      <span class="pagination-pages" style="flex-grow: none">
        {{
          t("labels.pagination.pages", {
            page: String(pagination.currentPage),
            total: String(pagination.totalPages || 1),
          })
        }}
      </span>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(pagination.currentPage + 1)"
        :disabled="pagination.currentPage >= pagination.totalPages"
        route-active-class=""
      >
        <i class="fa fa-chevron-right" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(pagination.totalPages)"
        :disabled="pagination.currentPage >= pagination.totalPages"
        route-active-class=""
      >
        <i class="fa fa-chevron-double-right" />
      </Btn>
    </BtnGroup>
  </div>
</template>

<script lang="ts" setup>
import BtnGroup from "@/frontend/core/components/BtnGroup/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import PerPageDropdown from "@/frontend/core/components/Pagination/PerPageDropdown/index.vue";
import type { Pagination } from "@/services/fyApi";
import { useRoute } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";

type Props = {
  pagination?: Pagination;
  inline?: boolean;
  updatePerPage?: (perPage: number | string) => void;
  perPage?: number | string;
  hash?: string;
};

const props = withDefaults(defineProps<Props>(), {
  pagination: () => ({
    currentPage: 1,
    totalPages: 1,
    defaultPerPage: 30,
    maxPerPage: 100,
  }),
  updatePerPage: undefined,
  perPage: undefined,
  inline: false,
  perPageSelectable: true,
  hash: undefined,
});

const perPageSelectable = computed(
  () => !!props.pagination?.perPageSteps && !!props.updatePerPage
);

const internalPerPage = computed(
  () => props.perPage || props.pagination?.defaultPerPage
);

const { t } = useI18n();

const route = useRoute();

const pageRoute = (page: number) => ({
  query: { page: String(page), q: route.query.q },
  hash: props.hash,
});
</script>

<script lang="ts">
export default {
  name: "AppPagination",
};
</script>
