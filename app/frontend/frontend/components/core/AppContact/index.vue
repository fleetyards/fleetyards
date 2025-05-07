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

<script lang="ts" setup>
const appName = computed(() => {
  return window.APP_NAME;
});

const maintainerName = computed(() => {
  return window.MAINTAINER_NAME;
});

const maintainerMail = computed(() => {
  return window.MAINTAINER_MAIL;
});

const maintainerAddressStreet = computed(() => {
  return window.MAINTAINER_ADDRESS_STREET;
});

const maintainerAddressPostalcode = computed(() => {
  return window.MAINTAINER_ADDRESS_POSTALCODE;
});

const maintainerAddressCity = computed(() => {
  return window.MAINTAINER_ADDRESS_CITY;
});

const maintainerAddressCountry = computed(() => {
  return window.MAINTAINER_ADDRESS_COUNTRY;
});
</script>

<script lang="ts">
export default {
  name: "AppContact",
};
</script>
