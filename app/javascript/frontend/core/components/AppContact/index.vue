<template>
  <address>
    <dl class="dl-horizontal">
      <dd class="name">
        {{ appName }}
      </dd>
      <dt>
        <strong>Address:</strong>
      </dt>
      <dd>
        {{ maintainerName }}
        <br />
        {{ maintainerAddressStreet }}
        <br />
        {{ maintainerAddressPostalcode }} {{ maintainerAddressCity }}
        <br />
        {{ maintainerAddressCountry }}
      </dd>
      <dt>
        <strong>E-Mail:</strong>
      </dt>
      <dd>
        {{ maintainerMail }}
      </dd>
    </dl>
  </address>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'

@Component<AppContact>({})
export default class AppContact extends Vue {
  get appName() {
    return window.APP_NAME
  }

  get maintainerName() {
    return window.MAINTAINER_NAME
  }

  get maintainerMail() {
    return window.MAINTAINER_MAIL
  }

  get maintainerAddressStreet() {
    return window.MAINTAINER_ADDRESS_STREET
  }

  get maintainerAddressPostalcode() {
    return window.MAINTAINER_ADDRESS_POSTALCODE
  }

  get maintainerAddressCity() {
    return window.MAINTAINER_ADDRESS_CITY
  }

  get maintainerAddressCountry() {
    return window.MAINTAINER_ADDRESS_COUNTRY
  }
}
</script>
