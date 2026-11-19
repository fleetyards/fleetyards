import { type Feature } from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

export type FeatureSummaryPart = {
  key: string;
  icon: string;
  label: string;
};

const DAY_MS = 1000 * 60 * 60 * 24;

export const useFeatureState = () => {
  const { t } = useI18n();

  const stateVariant = (state: string): `${PillVariantsEnum}` => {
    switch (state) {
      case "on":
        return PillVariantsEnum.SUCCESS;
      case "off":
        return PillVariantsEnum.DANGER;
      case "conditional":
        return PillVariantsEnum.WARNING;
      default:
        return PillVariantsEnum.DEFAULT;
    }
  };

  const stateLabel = (state: string) => {
    switch (state) {
      case "on":
        return t("labels.features.stateOn");
      case "off":
        return t("labels.features.stateOff");
      case "conditional":
        return t("labels.features.stateConditional");
      default:
        return state;
    }
  };

  const actorCount = (feature: Feature, type: string) =>
    feature.actors.filter((actor) => actor.type === type).length;

  // Who gets the flag right now, one part per open gate. A flag that is on
  // for everyone ignores its other gates, so they are left out.
  const summaryParts = (feature: Feature): FeatureSummaryPart[] => {
    // Off means every gate is cleared; the opt-in settings survive that but
    // give nobody the flag until someone opts in.
    if (feature.state === "off") return [];

    if (feature.state === "on") {
      return [
        {
          key: "everyone",
          icon: "fa-light fa-globe",
          label: t("labels.features.everyone"),
        },
      ];
    }

    const parts: FeatureSummaryPart[] = feature.groups.map((group) => ({
      key: `group-${group}`,
      icon: "fa-light fa-users",
      label: group,
    }));

    if (feature.percentageOfActors > 0) {
      parts.push({
        key: "percentage-of-actors",
        icon: "fa-light fa-percent",
        label: t("labels.features.summary.percentOfUsers", {
          percent: feature.percentageOfActors,
        }),
      });
    }

    if (feature.percentageOfTime > 0) {
      parts.push({
        key: "percentage-of-time",
        icon: "fa-light fa-shuffle",
        label: t("labels.features.summary.percentOfRequests", {
          percent: feature.percentageOfTime,
        }),
      });
    }

    const users = actorCount(feature, "User");
    if (users > 0) {
      parts.push({
        key: "users",
        icon: "fa-light fa-user",
        label: t("labels.features.summary.users", { count: users }),
      });
    }

    const fleets = actorCount(feature, "Fleet");
    if (fleets > 0) {
      parts.push({
        key: "fleets",
        icon: "fa-light fa-people-group",
        label: t("labels.features.summary.fleets", { count: fleets }),
      });
    }

    if (feature.selfServiceUser) {
      parts.push({
        key: "self-service-user",
        icon: "fa-light fa-hand-pointer",
        label: t("labels.features.selfServiceUser"),
      });
    }

    if (feature.selfServiceFleet) {
      parts.push({
        key: "self-service-fleet",
        icon: "fa-light fa-hand-pointer",
        label: t("labels.features.selfServiceFleet"),
      });
    }

    return parts;
  };

  // Whole days open, which is what the removal decision is made on.
  const daysOpen = (feature: Feature) => {
    if (!feature.fullyOnSince || feature.permanent) return null;

    return Math.floor(
      (Date.now() - new Date(feature.fullyOnSince).getTime()) / DAY_MS,
    );
  };

  return { stateVariant, stateLabel, actorCount, summaryParts, daysOpen };
};
