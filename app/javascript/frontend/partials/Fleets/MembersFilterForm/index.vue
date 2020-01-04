<template>
  <form @submit.prevent="filter">
    <FormInput
      v-model="form.usernameCont"
      :placeholder="$t('placeholders.filters.fleets.members.username')"
      :aria-label="$t('placeholders.filters.fleets.members.username')"
    />

    <FilterGroup
      v-model="form.roleIn"
      :options="roleOptions"
      :label="$t('labels.filters.fleets.members.role')"
      name="role"
      multiple
    />

    <Btn
      :disabled="!isFilterSelected"
      block
      @click.native="resetFilter"
    >
      <i class="fal fa-times" />
      {{ $t('actions.resetFilter') }}
    </Btn>
  </form>
</template>

<script>
import Filters from 'frontend/mixins/Filters'
import FilterGroup from 'frontend/components/Form/FilterGroup'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  name: 'FleetFilterForm',

  components: {
    FilterGroup,
    FormInput,
    Btn,
  },

  mixins: [
    Filters,
  ],

  data() {
    const query = this.$route.query.q || {}
    return {
      form: {
        usernameCont: query.usernameCont,
        roleIn: query.roleIn || [],
      },

      roleOptions: [{
        name: this.$t('labels.fleet.members.roles.admin'),
        value: 'admin',
      }, {
        name: this.$t('labels.fleet.members.roles.officer'),
        value: 'officer',
      }, {
        name: this.$t('labels.fleet.members.roles.member'),
        value: 'member',
      }],
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
      this.$store.commit('setFilters', { [this.$route.name]: this.form })
    },

    form: {
      handler() {
        this.filter()
      },
      deep: true,
    },
  },
}
</script>
