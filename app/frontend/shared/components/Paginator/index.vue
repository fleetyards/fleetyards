<script lang="ts">
export default {
  name: "AppPaginator",
};
</script>

<script lang="ts" setup>
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import PerPageDropdown from "./PerPageDropdown/index.vue";
import { type BaseList } from "@/services/fyApi";
import { useRoute } from "vue-router";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import type { MaybeRef } from "vue";

type Props = {
  queryResultRef: MaybeRef<BaseList | undefined>;
  updatePerPage?: (perPage: number | string) => void;
  // Declared so `@update-per-page` arrives here instead of falling through as
  // an attribute and leaving the dropdown hidden.
  onUpdatePerPage?: (perPage: number | string) => void;
  perPage?: number | string;
  size?: BtnSizesEnum;
  inline?: boolean;
  hash?: string;
};

const props = withDefaults(defineProps<Props>(), {
  updatePerPage: undefined,
  onUpdatePerPage: undefined,
  perPage: undefined,
  size: undefined,
  inline: false,
  hash: undefined,
});

const result = computed(() => unref(props.queryResultRef));

// No result yet rather than a result without pagination: the first stands in
// for the list still loading and keeps the control on screen, the second is an
// endpoint that does not paginate at all and gets nothing.
const loading = computed(() => !result.value);

const pagination = computed(() => result.value?.meta.pagination);

const visible = computed(() => loading.value || !!pagination.value);

const perPageHandler = computed(
  () => props.updatePerPage ?? props.onUpdatePerPage,
);

const perPageSelectable = computed(
  () => !!pagination.value?.perPageSteps && !!perPageHandler.value,
);

const internalPerPage = computed(
  () => props.perPage || pagination.value?.defaultPerPage,
);

// Picking the size on screen again changes nothing, so it keeps the page.
const changePerPage = (step: number | string) => {
  if (String(step) === String(internalPerPage.value)) {
    return;
  }

  perPageHandler.value?.(step);
};

// A size saved, or carried by a link, from before the list offered these steps
// (30 on a card grid) would leave a short row on every page and match no step,
// so the list goes back to its default instead.
watch(
  [() => pagination.value?.perPageSteps, () => props.perPage],
  ([steps, perPage]) => {
    if (!steps || !perPage || !perPageHandler.value) {
      return;
    }

    if (steps.some((step) => String(step) === String(perPage))) {
      return;
    }

    const fallback = pagination.value?.defaultPerPage;

    if (fallback) {
      perPageHandler.value(fallback);
    }
  },
  { immediate: true },
);

// An empty list still has a page one, and a page count is only unknown while the
// request is out.
const totalPages = computed(() => pagination.value?.totalPages || 1);

const pagesVisible = computed(() => loading.value || totalPages.value > 1);

const { t } = useI18n();

const mobile = useMobile();

const route = useRoute();

const pageRoute = (page: number) => ({
  query: { ...route.query, page: String(page) },
  hash: props.hash,
});

const currentPage = computed(() => {
  const page = Number(route.query.page);
  return Number.isNaN(page) ? 1 : page;
});

const pagesLabel = computed(() =>
  t("paginator.labels.pages", {
    page: String(currentPage.value),
    total: loading.value ? "–" : String(totalPages.value),
  }),
);
</script>

<template>
  <div v-if="visible" class="pagination">
    <BtnGroup>
      <PerPageDropdown
        v-if="perPageSelectable"
        :size="size"
        :per-page="internalPerPage"
        :steps="pagination?.perPageSteps"
        @change="changePerPage"
      />
      <template v-if="pagesVisible">
        <Btn
          v-if="!mobile"
          :size="size"
          :to="pageRoute(1)"
          :disabled="loading || currentPage <= 1"
          route-active-class=""
        >
          <i class="fa fa-chevron-double-left" />
        </Btn>
        <Btn
          :size="size"
          :to="pageRoute(currentPage - 1)"
          :disabled="loading || currentPage <= 1"
          route-active-class=""
        >
          <i class="fa fa-chevron-left" />
        </Btn>
      </template>
      <span class="pagination__pages" style="flex-grow: none">
        {{ pagesLabel }}
      </span>
      <template v-if="pagesVisible">
        <Btn
          :size="size"
          :to="pageRoute(currentPage + 1)"
          :disabled="loading || currentPage >= totalPages"
          route-active-class=""
        >
          <i class="fa fa-chevron-right" />
        </Btn>
        <Btn
          v-if="!mobile"
          :size="size"
          :to="pageRoute(totalPages)"
          :disabled="loading || currentPage >= totalPages"
          route-active-class=""
        >
          <i class="fa fa-chevron-double-right" />
        </Btn>
      </template>
    </BtnGroup>
  </div>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
