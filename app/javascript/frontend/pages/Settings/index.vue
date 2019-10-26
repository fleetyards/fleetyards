<template>
  <section class="container">
    <div class="row">
      <div class="col-xs-12 col-sm-3 col-sm-push-9">
        <ul class="tabs">
          <router-link
            :to="{ name: 'settings-profile' }"
            tag="li"
          >
            <a>{{ $t('nav.settings.profile') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'settings-account' }"
            tag="li"
          >
            <a>{{ $t('nav.settings.account') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'settings-hangar' }"
            tag="li"
          >
            <a>{{ $t('nav.settings.hangar') }}</a>
          </router-link>
          <router-link
            :to="{ name: 'settings-change-password' }"
            tag="li"
          >
            <a>{{ $t('actions.changePassword') }}</a>
          </router-link>
        </ul>
      </div>
      <div class="col-xs-12 col-sm-9 col-sm-pull-3">
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
