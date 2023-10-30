<template>
  <div v-if="perPageSelectable || innerTotal > 1" class="pagination">
    <BtnGroup :inline="inline">
      <PerPageDropdown
        v-if="perPageSelectable && collection && collection.perPage"
        variant="dropdown"
        size="small"
        :per-page="collection.perPage"
        :steps="collection.perPageSteps"
        @change="collection.updatePerPage"
      />
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(1)"
        :disabled="page <= 1"
        route-active-class=""
      >
        <i class="fa fa-chevron-double-left" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(page - 1)"
        :disabled="page <= 1"
        route-active-class=""
      >
        <i class="fa fa-chevron-left" />
      </Btn>
      <span class="pagination-pages" style="flex-grow: none">
        {{
          $t("labels.pagination.pages", {
            page,
            total: innerTotal || 1,
          })
        }}
      </span>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(page + 1)"
        :disabled="page >= innerTotal"
        route-active-class=""
      >
        <i class="fa fa-chevron-right" />
      </Btn>
      <Btn
        variant="dropdown"
        size="small"
        :to="pageRoute(innerTotal)"
        :disabled="page >= innerTotal"
        route-active-class=""
      >
        <i class="fa fa-chevron-double-right" />
      </Btn>
    </BtnGroup>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import BtnGroup from "@/frontend/core/components/BtnGroup/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import PerPageDropdown from "@/frontend/core/components/Paginator/PerPageDropdown/index.vue";

@Component<Paginator>({
  components: {
    BtnGroup,
    Btn,
    PerPageDropdown,
  },
})
export default class Paginator extends Vue {
  @Prop({ default: false }) inline!: boolean;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  @Prop({ default: null }) collection: any;

  @Prop({ default: 1 }) page: number;

  @Prop({ default: 1 }) total: number;

  @Prop({ default: true }) perPageSelectable: boolean;

  get innerTotal() {
    if (this.collection) {
      return this.collection.totalPages || 1;
    }

    return this.total;
  }

  pageRoute(page) {
    return { query: { page, q: this.$route.query.q } };
  }
}
</script>
