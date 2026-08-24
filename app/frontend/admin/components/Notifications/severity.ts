import {
  AdminNotificationSeverityEnum,
  type AdminNotification,
} from "@/services/fyAdminApi";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Severity = AdminNotification["severity"];

export const severityPillVariant = (severity: Severity) => {
  switch (severity) {
    case AdminNotificationSeverityEnum.ERROR:
      return PillVariantsEnum.DANGER;
    case AdminNotificationSeverityEnum.WARNING:
      return PillVariantsEnum.WARNING;
    default:
      return PillVariantsEnum.DEFAULT;
  }
};

export const hasSeverityLabel = (severity: Severity) =>
  severity !== AdminNotificationSeverityEnum.INFO;
