import { beforeEach, describe, expect, it, vi } from "vitest";
import { RsiPageCheckEnum, RsiPageKindEnum } from "@/services/fyApi";
import {
  RsiPageReportOutcome,
  reportDetail,
  useRsiPageReport,
} from "./useRsiPageReport";

const request = vi.fn();

vi.mock("@/frontend/composables/useSyncExtension", () => ({
  useSyncExtension: () => ({ request }),
}));

const report = vi.fn((_: unknown) => Promise.resolve());

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  reportRsiPage: (data: unknown) => report({ data }),
}));

const signedIn = { code: 200, payload: { handle: "citizen" } };

const send = (details?: string[]) =>
  useRsiPageReport()({
    page: RsiPageKindEnum.HANGAR,
    check: RsiPageCheckEnum.MISSING_KINDS,
    details,
  });

const sentDetails = () =>
  (report.mock.calls[0][0] as { data: { details?: string[] } }).data.details;

describe("reportDetail", () => {
  it("keeps a detail on one line without backticks", () => {
    expect(reportDetail("kind `Ship`\r\n  liner\tDrake ")).toBe(
      "kind Ship liner Drake",
    );
  });

  it("cuts a long detail to 200 characters", () => {
    expect(reportDetail("a".repeat(250))).toBe("a".repeat(200));
  });

  it("does not split a character outside the basic plane", () => {
    const detail = reportDetail(`${"a".repeat(199)}🚀🚀`);

    expect(Array.from(detail)).toHaveLength(200);
    expect(detail.endsWith("🚀")).toBe(true);
  });
});

describe("useRsiPageReport", () => {
  beforeEach(() => {
    request.mockReset();
    report.mockClear();
  });

  it("sends at most ten details and drops the empty ones", async () => {
    request.mockResolvedValue(signedIn);

    await expect(
      send([" ", ...Array.from({ length: 12 }, (_, i) => `detail ${i}`)]),
    ).resolves.toBe(RsiPageReportOutcome.REPORTED);

    expect(sentDetails()).toEqual(
      Array.from({ length: 10 }, (_, i) => `detail ${i}`),
    );
  });

  it("leaves details out when none is left", async () => {
    request.mockResolvedValue(signedIn);

    await send(["`", "\n"]);

    expect(sentDetails()).toBeUndefined();
  });

  it("sends nothing once the RSI session is gone", async () => {
    request.mockResolvedValue({ code: 401 });

    await expect(send(["detail"])).resolves.toBe(
      RsiPageReportOutcome.SIGNED_OUT,
    );
    expect(report).not.toHaveBeenCalled();
  });
});
