<template>
  <div
    id="app"
    class="app-body container-fluid"
  >
    <transition
      name="fade"
      mode="out-in"
      appear
    >
      <router-view />
    </transition>
  </div>
</template>

<script>

export default {
  name: 'AdminApp',
}
</script>
