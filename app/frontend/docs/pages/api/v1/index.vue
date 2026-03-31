<script lang="ts">
export default {
  name: "ApiPage",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseText from "@/shared/components/base/Text/index.vue";
import BaseSpacer from "@/shared/components/base/Spacer/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { SwaggerUIBundle } from "swagger-ui-dist";
import copyText from "@/shared/utils/CopyText";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();
const { displayInfo, displayAlert } = useAppNotifications();

const schemaUrl = computed(() => `${window.API_ENDPOINT}/schema.yaml`);

const copySchemaUrl = () => {
  copyText(schemaUrl.value).then(
    () => displayInfo({ text: t("messages.copy.success") }),
    () => displayAlert({ text: t("messages.copy.failure") }),
  );
};

const apiVersion = computed(() => window.API_VERSION);
const oasVersion = computed(() => window.API_OAS_VERSION);

const swagger = ref<SwaggerUIBundle>();

const frontendEndpoint = computed(() => window.FRONTEND_ENDPOINT);
const oauth2RedirectUrl = computed(
  () => `${window.location.origin}/oauth2-redirect.html`,
);

const validatorIconUrl = computed(
  () => `https://validator.swagger.io/validator?url=${schemaUrl.value}`,
);

const validatorUrl = computed(
  () => `https://validator.swagger.io/validator/debug?url=${schemaUrl.value}`,
);

const LocalOAuthPlugin = () => ({
  statePlugins: {
    spec: {
      wrapActions: {
        updateJsonSpec:
          (oriAction: (spec: Record<string, unknown>) => void) =>
          (spec: Record<string, unknown>) => {
            const endpoint = frontendEndpoint.value;
            const components = spec.components as Record<string, unknown>;
            const securitySchemes = components?.securitySchemes as Record<
              string,
              Record<string, unknown>
            >;

            if (securitySchemes?.Oauth2) {
              const flows = securitySchemes.Oauth2.flows as Record<
                string,
                Record<string, string>
              >;
              if (flows?.authorizationCode) {
                flows.authorizationCode.authorizationUrl = `${endpoint}/oauth/authorize`;
                flows.authorizationCode.tokenUrl = `${endpoint}/oauth/token`;
              }
            }

            if (securitySchemes?.OpenId) {
              securitySchemes.OpenId.openIdConnectUrl = `${endpoint}/.well-known/openid-configuration`;
            }

            return oriAction(spec);
          },
      },
    },
  },
});

function initSwaggerUI() {
  swagger.value = SwaggerUIBundle({
    dom_id: "#swagger-ui",
    url: schemaUrl.value,
    showCommonExtensions: true,
    filter: true,
    defaultModelRendering: "model",
    defaultModelExpandDepth: 3,
    oauth2RedirectUrl: oauth2RedirectUrl.value,
    plugins: [LocalOAuthPlugin],
  });

  swagger.value?.initOAuth({
    usePkceWithAuthorizationCodeGrant: true,
  });
}

onMounted(() => {
  initSwaggerUI();
});
</script>

<template>
  <div class="heading-row">
    <Heading :size="HeadingSizeEnum.HERO" hero> FleetYards.net API </Heading>
    <div class="version-pills">
      <BasePill>{{ apiVersion }}</BasePill>
      <BasePill variant="success">OAS {{ oasVersion }}</BasePill>
    </div>
  </div>

  <BaseText>
    “Strap into one of dozens of ships and embark on a life within the Star
    Citizen universe. Unbound by profession or skill sets, you choose the path
    of your own life.”
  </BaseText>

  <BaseText>
    This API provides basic Information about All Ships / Components /
    Manufacturers for the upcomming Space Simulation Star Citizen.
  </BaseText>

  <BaseSpacer />

  <Panel>
    <PanelBody>
      <div class="schema-url-row">
        <FormInput
          name="schemaUrl"
          :model-value="schemaUrl"
          :disabled="true"
          no-label
          inline
        />
        <Btn :size="BtnSizesEnum.SMALL" inline @click="copySchemaUrl">
          <i class="fa-duotone fa-copy" />
        </Btn>
      </div>
      <div id="swagger-ui" class="swagger-ui-wrapper"></div>
      <div class="validator-badge">
        <a target="_blank" rel="noopener noreferrer" :href="validatorUrl">
          <img :src="validatorIconUrl" alt="Online validator badge" />
        </a>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.heading-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.version-pills {
  display: flex;
  gap: 0.5rem;
}

.schema-url-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  max-width: 600px;
  margin: 0 auto 1rem;

  :deep(.base-input) {
    flex: 1;
  }
}

.validator-badge {
  display: flex;
  justify-content: flex-end;
}
</style>

<style lang="scss">
.swagger-ui-wrapper {
  .title {
    padding-top: 1rem;
  }

  .swagger-ui {
    .information-container {
      display: none;
    }

    .wrapper {
      padding: 0;
      max-width: none;
    }

    .info .title {
      font-family: "Orbitron", sans-serif;
    }

    section h3 {
      font-family: "Orbitron", sans-serif;
    }
  }
  .swagger-ui .model-box-control,
  .swagger-ui .models-control,
  .swagger-ui .opblock-summary-control {
    gap: 5px;

    .opblock-summary-description {
      flex-grow: 2;
      text-align: right;
      font-size: 110%;
    }
  }
}
</style>
