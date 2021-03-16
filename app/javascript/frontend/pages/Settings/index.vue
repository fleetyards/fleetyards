<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-3 order-md-12">
        <ul class="tabs">
          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'settings-profile' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('nav.settings.profile') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'settings-account' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('nav.settings.account') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'settings-hangar' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('nav.settings.hangar') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate }"
            :to="{ name: 'settings-change-password' }"
            :custom="true"
          >
            <li role="link" @click="navigate" @keypress.enter="navigate">
              <a :href="linkHref">{{ $t('actions.changePassword') }}</a>
            </li>
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
