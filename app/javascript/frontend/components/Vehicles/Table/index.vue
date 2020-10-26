<template>
  <FilteredTable
    :records="vehicles"
    :primary-key="primaryKey"
    :columns="tableColumns"
    :selected="selected"
    @selected-change="onSelectedChange"
  >
    <template #col.store_image="{ record }">
      <div
        :key="record.model.storeImageSmall"
        v-lazy:background-image="record.model.storeImageSmall"
        class="image lazy"
        alt="storeImage"
      />
    </template>
    <template #col.name="{ record }">
      <router-link
        :to="{
          name: 'model',
          params: {
            slug: record.model.slug,
          },
        }"
      >
        <span v-if="record.name">
          {{ record.name }}
        </span>

        <span v-else>{{ record.model.name }}</span>
      </router-link>
    </template>
    <template #col.purchased="{ record }">
      <div class="purchased">
        <i v-if="record.purchased" class="fad fa-check-square" />
        <i v-else class="fad fa-square" />
      </div>
    </template>
    <template #col.public="{ record }">
      <div class="public">
        <i v-if="record.public" class="fad fa-check-square" />
        <i v-else class="fad fa-square" />
      </div>
    </template>
    <template #col.model_manufacturer="{ record }">
      {{ record.model.manufacturer.name }}
    </template>
    <template #col.actions="{ record }">
      ...
    </template>
  </FilteredTable>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import FilteredTable from 'frontend/core/components/FilteredTable'

@Component<FilteredGrid>({
  components: {
    FilteredTable,
  },
})
export default class FilteredGrid extends Vue {
  @Prop({ required: true }) vehicles!: Vehicle[]

  @Prop({ required: true }) primaryKey!: string

  selected: string[] = []

  tableColumns: FilteredTableColumn[] = [
    {
      name: 'store_image',
      class: 'store-image wide',
      type: 'store-image',
    },
    {
      name: 'name',
      label: this.$t('labels.vehicle.name'),
      width: '20%',
      class: 'name',
    },
    {
      name: 'model_manufacturer',
      label: this.$t('labels.model.manufacturer'),
      width: '20%',
    },
    {
      name: 'purchased',
      label: this.$t('labels.vehicle.purchased'),
      width: '10%',
    },
    {
      name: 'public',
      label: this.$t('labels.vehicle.publicShort'),
      width: '10%',
    },
    { name: 'actions', label: this.$t('labels.actions'), width: '10%' },
  ]

  onSelectedChange(value) {
    console.log(value)
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
