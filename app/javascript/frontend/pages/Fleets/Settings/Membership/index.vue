<template>
  <section class="container">
    <div class="row">
      <div class="col-lg-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.membership') }}</h1>
      </div>
    </div>
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <Checkbox
              id="primary"
              v-model="form.primary"
              :label="$t('labels.fleet.members.primary')"
            />
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="shipsFilter"
              rules="required"
              :name="$t('labels.fleet.members.shipsFilter.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'ships-filter'"
                  v-model="form.shipsFilter"
                  translation-key="fleet.members.shipsFilter"
                  :options="shipsFilterOptions"
                  name="shipsFilter"
                />
              </div>
            </ValidationProvider>
          </div>
          <div v-if="shipsFilterIsHangarGroup" class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="hangarGroupId"
              rules="required"
              :name="$t('labels.fleet.members.hangarGroupId.field')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group"
              >
                <FilterGroup
                  :key="'hangar-group-id'"
                  v-model="form.hangarGroupId"
                  translation-key="fleet.members.hangarGroupId"
                  fetch-path="hangar-groups"
                  value-attr="id"
                  name="hangarGroupId"
                />
              </div>
            </ValidationProvider>
          </div>
        </div>
        <br />
        <Btn
          :loading="submitting"
          type="submit"
          size="large"
          data-test="fleet-save"
        >
          {{ $t('actions.save') }}
        </Btn>
      </form>
    </ValidationObserver>
  </section>
</template>

<script>
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import Btn from 'frontend/components/Btn'
import Checkbox from 'frontend/components/Form/Checkbox'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FleetsMixin from 'frontend/mixins/Fleets'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  name: 'FleetSettings',

  components: {
    BreadCrumbs,
    Btn,
    Checkbox,
    FilterGroup,
  },

  mixins: [MetaInfo, FleetsMixin],

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
        shipsFilter: null,
        hangarGroupId: null,
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

      return [
        {
          to: {
            name: 'fleet',
            params: {
              slug: this.fleet.slug,
            },
          },

          label: this.fleet.name,
        },
      ]
    },

    shipsFilterIsHangarGroup() {
      return this.form.shipsFilter === 'hangar_group'
    },

    shipsFilterOptions() {
      return [
        {
          name: this.$t('labels.fleet.members.shipsFilter.values.purchased'),
          value: 'purchased',
        },
        {
          name: this.$t('labels.fleet.members.shipsFilter.values.hangar_group'),
          value: 'hangar_group',
        },
        {
          name: this.$t('labels.fleet.members.shipsFilter.values.hide'),
          value: 'hide',
        },
      ]
    },
  },

  watch: {
    $route() {
      this.setupForm()
    },

    shipsFilterIsHangarGroup() {
      if (!this.shipsFilterIsHangarGroup) {
        this.form.hangarGroupId = null
      }
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    setupForm() {
      this.form = {
        primary: this.myFleet.primary,
        shipsFilter: this.myFleet.shipsFilter,
        hangarGroupId: this.myFleet.hangarGroupId,
      }
    },

    async submit() {
      this.submitting = true

      const response = await this.$api.put(
        `fleets/${this.$route.params.slug}/members`,
        this.form,
      )

      this.submitting = false

      if (!response.error) {
        displaySuccess({
          text: this.$t('messages.fleet.members.update.success'),
        })

        this.$comlink.$emit('fleetUpdate')
      } else {
        displayAlert({
          text: this.$t('messages.fleet.members.update.failure'),
        })
      }
    },
  },
}
</script>
