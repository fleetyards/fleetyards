<template>
  <form @submit.prevent="filter">
    <FormInput
      id="username"
      v-model="form.usernameCont"
      translation-key="filters.fleets.members.username"
      :no-label="true"
      :clearable="true"
    />

    <FilterGroup
      v-model="form.roleIn"
      :options="roleOptions"
      :label="$t('labels.filters.fleets.members.role')"
      name="role"
      :multiple="true"
      :no-label="true"
    />

    <Btn
      :disabled="!isFilterSelected"
      :block="true"
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'

export default {
  name: 'FleetFilterForm',

  components: {
    FilterGroup,
    FormInput,
    Btn,
  },

  mixins: [Filters],

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        usernameCont: query.usernameCont,
        roleIn: query.roleIn || [],
      },

      roleOptions: [
        {
          name: this.$t('labels.fleet.members.roles.admin'),
          value: 'admin',
        },
        {
          name: this.$t('labels.fleet.members.roles.officer'),
          value: 'officer',
        },
        {
          name: this.$t('labels.fleet.members.roles.member'),
          value: 'member',
        },
      ],
    }
  },

  watch: {
    $route() {
      const query = this.$route.query.q || {}
      this.form = {
        usernameCont: query.usernameCont,
        roleIn: query.roleIn || [],
        sorts: query.sorts,
      }
    },
  },
}
</script>
