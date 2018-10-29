<template>
  <router-view v-if="$route.name !== 'stations'" />
  <section
    v-else
    class="container"
  >
    <div class="row">
      <div class="col-xs-12">foo</div>
    </div>
  </section>
</template>
