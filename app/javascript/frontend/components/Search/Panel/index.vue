<template>
  <Panel
    v-if="item"
    :id="`${item.resultType}-${item.id}`"
  >
    <div class="panel-heading">
      <h2 class="panel-title">
        <router-link :to="route">
          {{ item.name }}
        </router-link>

        <br>

        <small>
          {{ item.locationLabel }}
        </small>
      </h2>
    </div>
    <div class="panel-image text-center">
      <LazyImage
        :to="route"
        :aria-label="item.name"
        :src="item.storeImageMedium"
        :alt="item.name"
        class="image"
      />
    </div>
    <!-- <b-collapse
        :id="`details-${model.slug}-wrapper`"
        :visible="details"
      >
        <div class="production-status">
          <strong class="text-uppercase">
            <template v-if="model.productionStatus">
              {{ $t(`labels.model.productionStatus.${model.productionStatus}`) }}
            </template>
            <template v-else>
              {{ $t(`labels.not-available`) }}
            </template>
          </strong>
        </div>
        <ul class="list-group">
          <li class="list-group-item">
            <ModelTopMetrics :model="model" />
          </li>
          <li class="list-group-item">
            <ModelBaseMetrics :model="model" />
          </li>
        </ul>
      </b-collapse> -->
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import LazyImage from 'frontend/components/LazyImage'

export default {
  components: {
    Panel,
    LazyImage,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },
  },

  computed: {
    route() {
      switch (this.item.resultType) {
        case 'shop':
          return { name: 'shop', params: { station: this.item.station.slug, slug: this.item.slug } }
        case 'station':
          return { name: 'station', params: { slug: this.item.slug } }
        default:
          return ''
      }
    },
  },
}
</script>
