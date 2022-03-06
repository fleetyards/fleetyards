<template>
  <Modal :title="$t('headlines.vehicle.bulkGroupEdit')">
    <p class="hint">
      <i class="fal fa-info-circle" />
      {{ $t('labels.vehicle.bulkGroupEdit.hint') }}
    </p>

    <form id="vehicle-bulk" @submit.prevent="save">
      <div class="row">
        <div v-if="hangarGroups.length" class="col-12">
          <h3>Groups:</h3>
          <div class="row">
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
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          form="vehicle-bulk"
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
  name: 'VehicleModal',
  components: {
    Btn,
    Checkbox,
    Modal,
  },

  props: {
    vehicleIds: {
      type: Array,
      required: true,
    },
  },

  data() {
    return {
      hangarGroupIds: [],
      submitting: false,
    }
  },

  computed: {
    hangarGroups() {
      return hangarGroupsCollection.records
    },
  },

  methods: {
    changeGroup(group) {
      if (this.hangarGroupIds.includes(group.id)) {
        const index = this.hangarGroupIds.findIndex(
          (groupId) => groupId === group.id
        )
        if (index > -1) {
          this.hangarGroupIds.splice(index, 1)
        }
      } else {
        this.hangarGroupIds.push(group.id)
      }
    },

    async save() {
      this.submitting = true

      if (
        await vehiclesCollection.updateHangarGroupsBulk(
          this.vehicleIds,
          this.hangarGroupIds
        )
      ) {
        this.$comlink.$emit('close-modal')
      }

      this.submitting = false
    },

    selected(groupId) {
      return this.hangarGroupIds.includes(groupId)
    },
  },
}
</script>
