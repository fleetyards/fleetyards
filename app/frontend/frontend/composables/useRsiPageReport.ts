import {
  type RsiPageCheckEnum,
  type RsiPageKindEnum,
  useReportRsiPage,
} from "@/services/fyApi";
import { useSyncExtension } from "@/frontend/composables/useSyncExtension";
import {
  FleetyardsSyncAction,
  type FleetyardsSyncSessionPayload,
} from "@/frontend/lib/FleetyardsSyncHandler";

export enum RsiPageReportOutcome {
  REPORTED = "reported",
  // The RSI session ran out mid-sync: RSI answers with its sign-in page, which
  // no parser recognises, and nothing about RSI's markup changed.
  SIGNED_OUT = "signedOut",
  NO_ANSWER = "noAnswer",
}

const MAX_DETAILS = 10;
const MAX_DETAIL_LENGTH = 200;

// The admin notification renders each detail as inline code, so one may not
// hold a backtick or break the line. Cut by code point: the server counts them,
// and a surrogate pair split in half would fail its check and lose the report.
export const reportDetail = (detail: string) =>
  Array.from(
    detail
      .replace(/[`\r\n]/g, " ")
      .replace(/\s+/g, " ")
      .trim(),
  )
    .slice(0, MAX_DETAIL_LENGTH)
    .join("")
    .trim();

// Tells the admins a sync met an RSI page its parser no longer recognises,
// once the extension confirms the RSI session is still there. The report itself
// is fired and forgotten: the sync has already stopped.
export const useRsiPageReport = () => {
  const mutation = useReportRsiPage();
  const extension = useSyncExtension();

  return async (report: {
    page: RsiPageKindEnum;
    check: RsiPageCheckEnum;
    pageNumber?: number;
    extensionVersion?: string;
    details?: string[];
  }) => {
    const identity = await extension
      .request(FleetyardsSyncAction.IDENTIFY)
      .catch(() => undefined);

    if (!identity) return RsiPageReportOutcome.NO_ANSWER;

    if (
      identity.code !== 200 ||
      !(identity.payload as FleetyardsSyncSessionPayload)?.handle
    ) {
      return RsiPageReportOutcome.SIGNED_OUT;
    }

    const details = report.details
      ?.map(reportDetail)
      .filter(Boolean)
      .slice(0, MAX_DETAILS);

    mutation
      .mutateAsync({
        data: { ...report, details: details?.length ? details : undefined },
      })
      .catch(() => undefined);

    return RsiPageReportOutcome.REPORTED;
  };
};
