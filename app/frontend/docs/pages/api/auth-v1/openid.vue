<script lang="ts">
export default {
  name: "AuthApiOpenIdPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BaseSpacer from "@/shared/components/base/Spacer/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
const frontendEndpoint = computed(() => window.FRONTEND_ENDPOINT);

const discoveryUrl = computed(
  () => `${frontendEndpoint.value}/.well-known/openid-configuration`,
);
</script>

<template>
  <BreadCrumbs
    :crumbs="[{ to: { name: 'api-auth-v1' }, label: t('nav.authApiV1') }]"
  />

  <Heading :size="HeadingSizeEnum.HERO" hero>OpenID Connect</Heading>

  <Panel>
    <PanelBody>
      <BaseText>
        FleetYards.net supports OpenID Connect for authentication and
        authorization. This allows third-party applications to authenticate
        users and access the API on their behalf.
      </BaseText>

      <h3 class="text-xl font-semibold">Discovery</h3>

      <BaseText>
        The OpenID Connect discovery endpoint provides all the information
        needed to interact with the authentication system:
      </BaseText>

      <BaseText>
        <a
          :href="discoveryUrl"
          target="_blank"
          rel="noopener"
          class="text-brand-primary hover:text-brand-primary/80 transition-colors"
        >
          <code class="hljs p-1 rounded">{{ discoveryUrl }}</code>
        </a>
      </BaseText>

      <BaseSpacer />

      <h3 class="text-xl font-semibold">Authorization Code Flow with PKCE</h3>

      <BaseText>
        FleetYards.net uses the Authorization Code flow with PKCE (Proof Key for
        Code Exchange) for secure authentication. PKCE is required for all
        authorization code grants.
      </BaseText>

      <BaseText> The flow works as follows: </BaseText>

      <ol class="list-decimal pl-5 mb-4 space-y-2">
        <li>
          Generate a <code class="hljs p-1 rounded">code_verifier</code> and
          derive a <code class="hljs p-1 rounded">code_challenge</code> from it.
        </li>
        <li>
          Redirect the user to the authorization endpoint with the
          <code class="hljs p-1 rounded">code_challenge</code>.
        </li>
        <li>
          After the user authorizes your application, exchange the authorization
          code for tokens using the
          <code class="hljs p-1 rounded">code_verifier</code>.
        </li>
      </ol>

      <BaseSpacer />

      <h3 class="text-xl font-semibold">Endpoints</h3>

      <table class="table-auto w-full mb-4">
        <thead>
          <tr>
            <th class="px-4 py-2">Endpoint</th>
            <th class="px-4 py-2">URL</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="border px-4 py-2">Authorization</td>
            <td class="border px-4 py-2">
              <code class="hljs p-1 rounded"
                >{{ frontendEndpoint }}/oauth/authorize</code
              >
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">Token</td>
            <td class="border px-4 py-2">
              <code class="hljs p-1 rounded"
                >{{ frontendEndpoint }}/oauth/token</code
              >
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">Revoke</td>
            <td class="border px-4 py-2">
              <code class="hljs p-1 rounded"
                >{{ frontendEndpoint }}/oauth/revoke</code
              >
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">User Info</td>
            <td class="border px-4 py-2">
              <code class="hljs p-1 rounded"
                >{{ frontendEndpoint }}/oauth/userinfo</code
              >
            </td>
          </tr>
          <tr>
            <td class="border px-4 py-2">Discovery</td>
            <td class="border px-4 py-2">
              <code class="hljs p-1 rounded">{{ discoveryUrl }}</code>
            </td>
          </tr>
        </tbody>
      </table>

      <BaseSpacer />

      <h3 class="text-xl font-semibold">OAuth Applications</h3>

      <BaseText>
        You can register and manage your OAuth applications in your
        <a
          :href="`${frontendEndpoint}/settings/oauth-applications/`"
          class="text-brand-primary hover:text-brand-primary/80 transition-colors"
        >
          account settings</a
        >.
      </BaseText>
    </PanelBody>
  </Panel>
</template>
