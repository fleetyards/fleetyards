<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.editGroups', { vehicle: vehicle.model.name })"
  >
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div v-if="hangarGroups.length" class="row">
          <div
            v-for="group in hangarGroups"
            :key="group.id"
            class="col-12 col-md-6"
          >
            <Checkbox
              :label="group.name"
              :value="selected(group.id)"
              @input="changeGroup(group)"
            />
          </div>
        </div>
      </form>
    </ValidationObserver>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-${vehicle.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          data-test="vehicle-save"
          :inline="true"
        >
          {{ $t('actions.save') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import Modal from '@/frontend/core/components/AppModal/Modal/index.vue'
import Checkbox from '@/frontend/core/components/Form/Checkbox/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import vehiclesCollection from '@/frontend/api/collections/Vehicles'
import hangarGroupsCollection from '@/frontend/api/collections/HangarGroups'

export default {
  name: 'VehicleGroupsModal',

  components: {
    Btn,
    Checkbox,
    Modal,
  },

  props: {
    vehicle: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      form: null,
      submitting: false,
    }
  },

  computed: {
    hangarGroups() {
      return hangarGroupsCollection.records
    },
  },

  watch: {
    vehicle() {
      this.setupForm()
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    changeGroup(group) {
      if (this.form.hangarGroupIds.includes(group.id)) {
        const index = this.form.hangarGroupIds.findIndex(
          (groupId) => groupId === group.id
        )
        if (index > -1) {
          this.form.hangarGroupIds.splice(index, 1)
        }
      } else {
        this.form.hangarGroupIds.push(group.id)
      }
    },

    async save() {
      this.submitting = true

      const response = await vehiclesCollection.update(
        this.vehicle.id,
        this.form
      )

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('close-modal')
      }
    },

    selected(groupId) {
      return (this.form.hangarGroupIds || []).includes(groupId)
    },

    setupForm() {
      this.form = {
        hangarGroupIds: this.vehicle.hangarGroupIds,
      }
    },
  },
}
</script>
