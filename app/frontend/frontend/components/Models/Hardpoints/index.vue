<template>
  <div>
    <div v-if="erkulUrl" class="d-flex justify-content-center">
      <Btn :href="erkulUrl" :mobile-block="true" class="erkul-link">
        <small>{{ $t('labels.erkul.prefix') }}</small>
        <i />
        {{ $t('labels.erkul.link') }}
      </Btn>
    </div>
    <div class="row">
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['avionic', 'system']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['propulsion', 'thruster']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
      <div class="col-12 col-md-6 col-lg-4">
        <HardpointGroup
          v-for="group in ['weapon']"
          :key="group"
          :group="group"
          :hardpoints="hardpointsForGroup(group)"
        />
      </div>
    </div>
    <div v-if="scunpackedUrl" class="d-flex justify-content-end">
      <Btn
        :href="scunpackedUrl"
        variant="link"
        :mobile-block="true"
        class="scunpacked-link"
      >
        <small>{{ $t('labels.scunpacked.prefix') }}</small>
        <i>
          {{ $t('labels.scunpacked.link') }}
        </i>
      </Btn>
    </div>
    <Loader :loading="loading" :fixed="true" />
  </div>
</template>

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'
import Loader from '@/frontend/core/components/Loader/index.vue'
import modelHardpointsCollection from '@/frontend/api/collections/ModelHardpoints'
import HardpointGroup from './Group/index.vue'

export default {
  name: 'ModelHardpoints',
  components: {
    Btn,
    HardpointGroup,
    Loader,
  },

  props: {
    model: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      collection: modelHardpointsCollection,
      loading: false,
    }
  },

  computed: {
    erkulUrl() {
      if (
        !this.model ||
        this.model.productionStatus !== 'flight-ready' ||
        !this.model.erkulIdentifier
      ) {
        return null
      }

      return `https://www.erkul.games/ship/${this.model.erkulIdentifier}`
    },

    hardpoints() {
      return this.collection.records || []
    },

    scunpackedUrl() {
      if (!this.model.scIdentifier) {
        return null
      }

      return `https://scunpacked.com/ships/${this.model.scIdentifier}`
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

    hardpointsForGroup(group) {
      return this.hardpoints.filter((hardpoint) => hardpoint.group === group)
    },
  },
}
</script>
