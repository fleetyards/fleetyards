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
        <strong>Email:</strong>
      </dt>
      <dd>
        {{ maintainerMail }}
      </dd>
    </dl>
  </address>
</template>

<script>
export default {
  name: 'AppContact',

  computed: {
    appName() {
      return window.APP_NAME
    },

    maintainerAddressCity() {
      return window.MAINTAINER_ADDRESS_CITY
    },

    maintainerAddressCountry() {
      return window.MAINTAINER_ADDRESS_COUNTRY
    },

    maintainerAddressPostalcode() {
      return window.MAINTAINER_ADDRESS_POSTALCODE
    },

    maintainerAddressStreet() {
      return window.MAINTAINER_ADDRESS_STREET
    },

    maintainerMail() {
      return window.MAINTAINER_MAIL
    },

    maintainerName() {
      return window.MAINTAINER_NAME
    },
  },
}
</script>
