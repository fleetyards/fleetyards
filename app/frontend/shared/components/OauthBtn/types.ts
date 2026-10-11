import { FeatureFlagName } from "@/services/fyApi";

export enum OauthBtnProvidersEnum {
  DISCORD = "discord",
  GITHUB = "github",
  TWITCH = "twitch",
  GOOGLE = "google",
  BLUESKY = "bluesky",
  CITIZENID = "citizenid",
  PATREON = "patreon",
}

export const oauthProviderFeatureFlags: Record<
  `${OauthBtnProvidersEnum}`,
  FeatureFlagName
> = {
  [OauthBtnProvidersEnum.DISCORD]: FeatureFlagName.OAUTH_DISCORD,
  [OauthBtnProvidersEnum.GITHUB]: FeatureFlagName.OAUTH_GITHUB,
  [OauthBtnProvidersEnum.TWITCH]: FeatureFlagName.OAUTH_TWITCH,
  [OauthBtnProvidersEnum.GOOGLE]: FeatureFlagName.OAUTH_GOOGLE,
  [OauthBtnProvidersEnum.BLUESKY]: FeatureFlagName.OAUTH_BLUESKY,
  [OauthBtnProvidersEnum.CITIZENID]: FeatureFlagName.OAUTH_CITIZENID,
  [OauthBtnProvidersEnum.PATREON]: FeatureFlagName.OAUTH_PATREON,
};
