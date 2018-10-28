<template>
  <section class="container">
    <router-view v-if="$route.name !== 'stations'" />
    <template v-else>
      <div class="row">
        <div class="col-xs-12">foo</div>
      </div>
    </template>
  </section>
</template>
