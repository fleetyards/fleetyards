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

<script>
import FilteredTable from '@/frontend/core/components/FilteredTable/index.vue'
import AddToHangar from '@/frontend/components/Models/AddToHangar/index.vue'

export default {
  name: 'FilteredGrid',

  components: {
    AddToHangar,
    FilteredTable,
  },

  props: {
    models: {
      required: true,
      type: Array,
    },

    primaryKey: {
      required: true,
      type: String,
    },

    slim: {
      default: false,
      type: Boolean,
    },
  },

  computed: {
    tableColumns() {
      return [
        {
          class: `store-image wide ${this.slim ? 'small' : ''}`,
          name: 'store_image',
          type: 'store-image',
        },
        {
          flexGrow: 1,
          name: 'name',
        },
        { label: this.$t('labels.actions'), name: 'actions', width: '10%' },
      ]
    },
  },
}
</script>
