<template>
  <section class="container">
    <div class="row">
      <div class="col-md-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.membership') }}</h1>
      </div>
    </div>
    <form @submit.prevent="submit">
      <div class="row">
        <div class="col-md-12 col-lg-6">
          <Checkbox
            id="primary"
            v-model="form.primary"
            :label="$t('labels.fleet.members.primary')"
          />
        </div>
        <div class="col-md-12 col-lg-6">
          <Checkbox
            id="hideShips"
            v-model="form.hideShips"
            :label="$t('labels.fleet.members.hideShips')"
          />
        </div>
      </div>
      <br>
      <Btn
        :loading="submitting"
        type="submit"
        size="large"
        data-test="fleet-save"
      >
        {{ $t('actions.save') }}
      </Btn>
    </form>
  </section>
</template>

<script>
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import Btn from 'frontend/components/Btn'
import Checkbox from 'frontend/components/Form/Checkbox'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  name: 'FleetSettings',

  components: {
    BreadCrumbs,
    Btn,
    Checkbox,
  },

  mixins: [
    MetaInfo,
    FleetsMixin,
  ],

  props: {
    fleet: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      submitting: false,
      form: {
        primary: false,
        hideShips: false,
      },
    }
  },

  computed: {
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleets.settings', { fleet: this.fleet.name })
    },

    crumbs() {
      if (!this.fleet) {
        return []
      }

      return [{
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },

        label: this.fleet.name,
      }]
    },
  },
  watch: {
    $route() {
      this.setupForm()
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    setupForm() {
      this.form = {
        primary: this.myFleet.primary,
        hideShips: this.myFleet.hideShips,
      }
    },

    async submit() {
      this.submitting = true

      const response = await this.$api.put(`fleets/${this.$route.params.slug}/members`, this.form)

      this.submitting = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.fleet.members.update.success'),
        })

        this.$comlink.$emit('fleetUpdate')
      } else {
        this.$alert({
          text: this.$t('messages.fleet.members.update.failure'),
        })
      }
    },
  },
}
</script>
