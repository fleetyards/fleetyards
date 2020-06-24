<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-3 order-md-12">
        <ul class="tabs">
          <router-link :to="{ name: 'settings-profile' }" tag="li">
            <a>{{ $t('nav.settings.profile') }}</a>
          </router-link>
          <router-link :to="{ name: 'settings-account' }" tag="li">
            <a>{{ $t('nav.settings.account') }}</a>
          </router-link>
          <router-link :to="{ name: 'settings-hangar' }" tag="li">
            <a>{{ $t('nav.settings.hangar') }}</a>
          </router-link>
          <router-link :to="{ name: 'settings-change-password' }" tag="li">
            <a>{{ $t('actions.changePassword') }}</a>
          </router-link>
        </ul>
      </div>
      <div class="col-12 col-md-9 order-md-1">
        <router-view />
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'Settings',
}
</script>
