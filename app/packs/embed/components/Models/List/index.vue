<template>
  <transition-group name="fade-list" class="row" tag="div" :appear="true">
    <div
      v-for="(model, index) in internalModels"
      :key="`panel-${index}-${model.slug}`"
      class="col-12 col-md-6 col-xl-4 col-xxl-4 fade-list-item"
    >
      <ModelPanel :model="model" :details="details" :count="count(model)" />
    </div>
  </transition-group>
</template>

<script>
import ModelPanel from 'embed/components/Models/Panel'
import { mapGetters } from 'vuex'

export default {
  name: 'ModelList',

  components: {
    ModelPanel,
  },

  props: {
    models: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      internalModels: [],
    }
  },

  computed: {
    ...mapGetters(['details', 'grouping']),
  },

  watch: {
    models() {
      this.internalModels = this.models
    },
  },

  mounted() {
    this.internalModels = this.models
  },

  methods: {
    count(model) {
      if (!this.grouping) {
        return null
      }

      return model.count
    },
  },
}
</script>
