<template>
  <div class="quick-search-bar">
    <form @submit.prevent="filter">
      <FormInput
        :id="$route.meta.quickSearch || 'quicksearch'"
        v-model="form[$route.meta.quickSearch]"
        :translation-key="`quicksearch.${$route.name}`"
        :no-label="true"
        :autofocus="!mobile"
        :clearable="true"
      />
    </form>
  </div>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Getter } from "vuex-class";
import Filters from "@/frontend/mixins/Filters";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";

type QuickSearchFormData = {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  [key: string]: any;
};

@Component<Navigation>({
  components: {
    FormInput,
  },
  mixins: [Filters],
})
export default class QuickSearch extends Vue {
  form: QuickSearchFormData = {};

  @Getter("mobile") mobile;

  mounted() {
    const query = this.queryParams();

    query[this.$route.meta.quickSearch] =
      query[this.$route.meta.quickSearch] || null;

    this.form = query;
  }

  @Watch("$route")
  onRouteChange() {
    const query = this.queryParams();

    query[this.$route.meta.quickSearch] =
      query[this.$route.meta.quickSearch] || null;

    this.form = query;
  }

  queryParams() {
    return JSON.parse(JSON.stringify(this.$route.query.q || {}));
  }
}
</script>
