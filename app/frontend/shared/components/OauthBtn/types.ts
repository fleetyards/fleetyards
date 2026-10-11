import { FeatureFlagName, OmniauthProviderEnum } from "@/services/fyApi";

export const oauthProviderFeatureFlags: Record<
  OmniauthProviderEnum,
  FeatureFlagName
> = {
  [OmniauthProviderEnum.DISCORD]: FeatureFlagName.OAUTH_DISCORD,
  [OmniauthProviderEnum.GITHUB]: FeatureFlagName.OAUTH_GITHUB,
  [OmniauthProviderEnum.TWITCH]: FeatureFlagName.OAUTH_TWITCH,
  [OmniauthProviderEnum.GOOGLE]: FeatureFlagName.OAUTH_GOOGLE,
  [OmniauthProviderEnum.BLUESKY]: FeatureFlagName.OAUTH_BLUESKY,
  [OmniauthProviderEnum.CITIZENID]: FeatureFlagName.OAUTH_CITIZENID,
  [OmniauthProviderEnum.PATREON]: FeatureFlagName.OAUTH_PATREON,
};
