<template>
  <FilteredTable
    :records="models"
    :primary-key="primaryKey"
    :columns="tableColumns"
    :selectable="false"
  >
    <template #col-store_image="{ record }">
      <div
        :key="record.storeImageSmall"
        v-lazy:background-image="record.storeImageSmall"
        class="image lazy"
        alt="storeImage"
      />
    </template>
    <template #col-name="{ record }">
      <div class="name">
        <router-link
          :to="{
            name: 'model',
            params: {
              slug: record.slug,
            },
          }"
        >
          <span>{{ record.name }}</span>
        </router-link>
        <br v-if="!slim" />
        <small>
          <span v-html="record.manufacturer.name" />
        </small>
      </div>
    </template>
    <template #col-actions="{ record }">
      <AddToHangar :model="record" variant="list" />
    </template>
  </FilteredTable>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FilteredTable, {
  FilteredTableColumn,
} from 'frontend/core/components/FilteredTable/index.vue'
import AddToHangar from 'frontend/components/Models/AddToHangar/index.vue'

@Component<FilteredGrid>({
  components: {
    FilteredTable,
    AddToHangar,
  },
})
export default class FilteredGrid extends Vue {
  @Prop({ required: true }) models!: Model[]

  @Prop({ required: true }) primaryKey!: string

  @Prop({ default: false }) slim!: boolean

  get tableColumns(): FilteredTableColumn[] {
    return [
      {
        name: 'store_image',
        class: `store-image wide ${this.slim ? 'small' : ''}`,
        type: 'store-image',
      },
      {
        name: 'name',
        flexGrow: 1,
      },
      { name: 'actions', label: this.$t('labels.actions'), width: '10%' },
    ]
  }
}
</script>
