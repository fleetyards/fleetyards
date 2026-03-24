<script lang="ts">
export default {
  name: "OauthAuthorize",
};
</script>

<script lang="ts" setup>
import Box from "@/shared/components/Box/index.vue";
import BaseBtn from "@/shared/components/base/Btn/index.vue";
import {
  HeadingLevelEnum,
  HeadingSizeEnum,
} from "@/shared/components/base/Heading/types";
import {
  oauthPreAuthorize,
  oauthAuthorize,
  oauthDeny,
} from "@/services/fyOAuthApi/services/oauth/oauth";
import type { OauthPreAuthorization } from "@/services/fyOAuthApi/models";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
const route = useRoute();

const preAuth = ref<OauthPreAuthorization | null>(null);
const error = ref<string | null>(null);
const loading = ref(true);
const submitting = ref(false);

onMounted(async () => {
  try {
    const data = await oauthPreAuthorize({
      client_id: (route.query.client_id as string) || "",
      redirect_uri: (route.query.redirect_uri as string) || "",
      response_type: (route.query.response_type as string) || "",
      scope: (route.query.scope as string) || "",
      state: route.query.state as string,
      code_challenge: route.query.code_challenge as string,
      code_challenge_method: route.query.code_challenge_method as string,
    });
    preAuth.value = data;
  } catch (e: unknown) {
    if (e instanceof Error) {
      error.value = e.message;
    } else {
      error.value = t("messages.oauthAuthorize.loadError");
    }
  } finally {
    loading.value = false;
  }
});

async function authorize() {
  if (!preAuth.value) return;

  submitting.value = true;

  try {
    const data = await oauthAuthorize({
      clientId: preAuth.value.clientId,
      redirectUri: preAuth.value.redirectUri,
      responseType: preAuth.value.responseType,
      responseMode: preAuth.value.responseMode,
      scope: preAuth.value.scope,
      state: preAuth.value.state,
      codeChallenge: preAuth.value.codeChallenge,
      codeChallengeMethod: preAuth.value.codeChallengeMethod,
    });

    if (data.redirect_uri) {
      window.location.href = data.redirect_uri;
    }
  } catch {
    error.value = t("messages.oauthAuthorize.authorizeError");
    submitting.value = false;
  }
}

async function deny() {
  if (!preAuth.value) return;

  submitting.value = true;

  try {
    await oauthDeny({
      clientId: preAuth.value.clientId,
      redirectUri: preAuth.value.redirectUri,
      responseType: preAuth.value.responseType,
      responseMode: preAuth.value.responseMode,
      scope: preAuth.value.scope,
      state: preAuth.value.state,
      codeChallenge: preAuth.value.codeChallenge,
      codeChallengeMethod: preAuth.value.codeChallengeMethod,
    });
  } catch {
    error.value = t("messages.oauthAuthorize.denyError");
    submitting.value = false;
  }
}
</script>

<template>
  <Box
    large
    :heading-level="HeadingLevelEnum.H1"
    :heading-size="HeadingSizeEnum.XXL"
  >
    <template #heading>
      {{ t("headlines.oauthAuthorize") }}
    </template>

    <div v-if="loading" class="text-center">
      {{ t("messages.oauthAuthorize.loading") }}
    </div>

    <template v-else-if="error">
      <p class="text-danger">{{ error }}</p>
    </template>

    <template v-else-if="preAuth">
      <p class="authorize-info">
        {{
          t("texts.oauthAuthorize.requestingAccess", {
            clientName: preAuth.clientName,
          })
        }}
      </p>

      <template v-if="preAuth.scopes.length > 0">
        <p>{{ t("texts.oauthAuthorize.scopesIntro") }}</p>
        <ul class="authorize-scopes">
          <li v-for="scope in preAuth.scopes" :key="scope.name">
            {{ scope.description }}
          </li>
        </ul>
      </template>
    </template>

    <template #footer>
      <div class="authorize-actions">
        <BaseBtn variant="danger" :disabled="submitting" block @click="deny">
          {{ t("actions.oauthAuthorize.deny") }}
        </BaseBtn>
        <BaseBtn
          type="submit"
          :loading="submitting"
          :disabled="submitting"
          block
          @click="authorize"
        >
          {{ t("actions.oauthAuthorize.authorize") }}
        </BaseBtn>
      </div>
    </template>
  </Box>
</template>

<style lang="scss" scoped>
.authorize-info {
  margin-bottom: 15px;
}

.authorize-scopes {
  list-style: disc;
  padding-left: 20px;
  margin-bottom: 20px;

  li {
    margin-bottom: 5px;
  }
}

.authorize-actions {
  display: flex;
  gap: 10px;
}
</style>
