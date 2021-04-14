<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-3 order-md-12">
        <ul class="tabs">
          <router-link
            v-slot="{ href: linkHref, navigate, isActive }"
            :to="{ name: 'settings-profile' }"
            :custom="true"
          >
            <li
              role="link"
              :class="{ active: isActive }"
              @click="navigate"
              @keypress.enter="navigate"
            >
              <a :href="linkHref">{{ $t('nav.settings.profile') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate, isActive }"
            :to="{ name: 'settings-account' }"
            :custom="true"
          >
            <li
              role="link"
              :class="{ active: isActive }"
              @click="navigate"
              @keypress.enter="navigate"
            >
              <a :href="linkHref">{{ $t('nav.settings.account') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate, isActive }"
            :to="{ name: 'settings-security' }"
            :custom="true"
          >
            <li
              role="link"
              :class="{ active: isActive }"
              @click="navigate"
              @keypress.enter="navigate"
            >
              <a :href="linkHref">{{ $t('nav.settings.security') }}</a>
            </li>
          </router-link>
          <router-link
            v-slot="{ href: linkHref, navigate, isActive }"
            :to="{ name: 'settings-hangar' }"
            :custom="true"
          >
            <li
              role="link"
              :class="{ active: isActive }"
              @click="navigate"
              @keypress.enter="navigate"
            >
              <a :href="linkHref">{{ $t('nav.settings.hangar') }}</a>
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

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<Settings>()
export default class Settings extends Vue {}
</script>
