import { describe, expect, it } from "vitest";
import { errorTypeFrom } from "./ErrorTypes";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const failedWith = (status: number, data?: unknown) => ({
  isAxiosError: true,
  response: { status, data },
});

describe("errorTypeFrom", () => {
  it("reads a refused request as forbidden rather than an outage", () => {
    expect(errorTypeFrom(failedWith(403))).toBe(ErrorTypesEnum.FORBIDDEN);
  });

  // The two 403s the API answers with are told apart by the body alone. Read as
  // a status they are one screen, and an unbought fleet would be told its
  // clearance is wrong rather than that nobody has subscribed it.
  it("separates an unbought fleet from a refused one", () => {
    expect(
      errorTypeFrom(failedWith(403, { code: "subscription_required" })),
    ).toBe(ErrorTypesEnum.SUBSCRIPTION_REQUIRED);
  });

  it("reads a 403 carrying any other code as plain forbidden", () => {
    expect(errorTypeFrom(failedWith(403, { code: "forbidden" }))).toBe(
      ErrorTypesEnum.FORBIDDEN,
    );
  });

  // An HTML error page, an empty body, a proxy's own 403 -- none of them are an
  // upsell, and reading a body that is not JSON must not throw either.
  it("reads a 403 with no usable body as plain forbidden", () => {
    expect(errorTypeFrom(failedWith(403, "<html>nope</html>"))).toBe(
      ErrorTypesEnum.FORBIDDEN,
    );
    expect(errorTypeFrom(failedWith(403, null))).toBe(ErrorTypesEnum.FORBIDDEN);
  });

  // The code only means anything on a 403.
  it("does not read the code on any other status", () => {
    expect(
      errorTypeFrom(failedWith(500, { code: "subscription_required" })),
    ).toBe(ErrorTypesEnum.ERROR);
  });

  it("reads a missing record as not found", () => {
    expect(errorTypeFrom(failedWith(404))).toBe(ErrorTypesEnum.NOT_FOUND);
  });

  it("reads everything else as an error", () => {
    expect(errorTypeFrom(failedWith(500))).toBe(ErrorTypesEnum.ERROR);
    expect(errorTypeFrom(failedWith(422))).toBe(ErrorTypesEnum.ERROR);
  });

  it("reads a request that got no answer as a lost connection", () => {
    expect(errorTypeFrom({ isAxiosError: true, code: "ERR_NETWORK" })).toBe(
      ErrorTypesEnum.OFFLINE,
    );
  });

  it("keeps a cancelled request off the error screens", () => {
    expect(
      errorTypeFrom({ isAxiosError: true, code: "ERR_CANCELED" }),
    ).toBeUndefined();
  });

  it("has no verdict on something that is not a failed request", () => {
    expect(errorTypeFrom(new Error("boom"))).toBeUndefined();
    expect(errorTypeFrom(undefined)).toBeUndefined();
  });
});
