<template>
  <header class="navigation-header">
    <div
      v-if="nodeEnv && !mobile"
      :class="{
        'spacing-right': $route.name === 'home',
      }"
      class="environment-label"
    >
      <span :class="environmentLabelClasses">
        <i class="far fa-info-circle" />
        {{ nodeEnv }}
      </span>
      <span class="git-revision" :class="environmentLabelClasses">
        <i class="far fa-fingerprint" />
        {{ gitRevision }}
      </span>
    </div>
    <QuickSearch v-if="$route.meta.quickSearch" />
    <Search v-if="$route.meta.search" />
  </header>
</template>

<script lang="ts">
import QuickSearch from "../QuickSearch/index.vue";
import Search from "../Search/index.vue";

@Component<NavigationHeader>({
  components: {
    QuickSearch,
    Search,
  },
})
export default class NavigationHeader extends Vue {
  get mobile() {
    return this.$store.getters["app/mobile"];
  }

  get navCollapsed() {
    return this.$store.getters["app/navCollapsed"];
  }

  get gitRevision() {
    return this.$store.getters["app/gitRevision"];
  }

  get environmentLabelClasses() {
    const cssClasses = ["pill"];

    if (window.NODE_ENV === "staging") {
      cssClasses.push("pill-warning");
    } else if (window.NODE_ENV === "production") {
      cssClasses.push("pill-danger");
    }

    return cssClasses;
  }

  get nodeEnv() {
    if (window.NODE_ENV === "production") {
      return null;
    }

    return (window.NODE_ENV || "").toUpperCase();
  }

  toggle() {
    this.$store.dispatch("app/toggleNav");
  }
}
</script>
