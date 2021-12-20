<template>
  <div class="pagination">
    <BtnGroup>
      <PerPageDropdown
        v-if="collection && collection.perPage"
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
          $t('labels.pagination.pages', {
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
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import BtnGroup from 'frontend/core/components/BtnGroup'
import Btn from 'frontend/core/components/Btn'
import PerPageDropdown from 'frontend/core/components/Paginator/PerPageDropdown'

@Component<Paginator>({
  components: {
    BtnGroup,
    Btn,
    PerPageDropdown,
  },
})
export default class Paginator extends Vue {
  @Prop({ default: null }) collection: any

  @Prop({ default: 1 }) page: number

  @Prop({ default: 1 }) total: number

  get innerTotal() {
    if (this.collection) {
      return this.collection.totalPages || 1
    }

    return this.total
  }

  pageRoute(page) {
    return { query: { page, q: this.$route.query.q } }
  }
}
</script>
