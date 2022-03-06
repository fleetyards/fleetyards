<template>
  <div class="row">
    <div class="col-12 paints">
      <hr v-if="paints.length" />
      <h2 v-if="paints.length" class="text-uppercase">
        {{ $t('labels.model.paints') }}
      </h2>
      <transition-group
        v-if="paints.length"
        name="fade-list"
        class="row"
        tag="div"
        appear
      >
        <div
          v-for="paint in paints"
          :key="`paint-${paint.slug}`"
          class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
        >
          <TeaserPanel :item="paint" :fullscreen="true" />
        </div>
      </transition-group>
      <Loader :loading="loading" :fixed="true" />
    </div>
  </div>
</template>

<script>
import Loader from '@/frontend/core/components/Loader/index.vue'
import TeaserPanel from '@/frontend/core/components/TeaserPanel/index.vue'
import modelPaintsCollection from '@/frontend/api/collections/ModelPaints'

export default {
  name: 'ModelPaintList',

  components: {
    Loader,
    TeaserPanel,
  },

  props: {
    model: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      collection: modelPaintsCollection,
      loading: false,
    }
  },

  computed: {
    paints() {
      return this.collection.records
    },
  },

  watch: {
    model() {
      this.fetch()
    },
  },

  mounted() {
    this.fetch()
  },

  methods: {
    async fetch() {
      if (!this.model) {
        return
      }

      this.loading = true

      await this.collection.findAllByModel(this.model.slug)

      this.loading = false
    },
  },
}
</script>
