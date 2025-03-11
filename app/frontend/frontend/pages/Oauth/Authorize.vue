<template>
  <div>
    ClientID: {{ route.query.client_id }}
    <br />
    RedirectURI: {{ route.query.redirect_uri }}
    <br />
    State: {{ route.query.state }}
    <br />
    Scope: {{ route.query.scope }}
    <br />
    ResponseType: {{ route.query.response_type }}
    <br />
    CodeChallenge: {{ route.query.code_challenge }}
    <br />
    CodeChallengeMethod: {{ route.query.code_challenge_method }}
  </div>
</template>

<script lang="ts" setup>
const route = useRoute();
</script>

<script lang="ts">
export default {
  name: "OauthAuthorize",
};
</script>
