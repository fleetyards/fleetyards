import { describe, expect, it } from "vitest";
import { errorTypeFrom } from "./ErrorTypes";
import { ErrorTypesEnum } from "@/shared/components/AsyncData.types";

const failedWith = (status: number) => ({
  isAxiosError: true,
  response: { status },
});

describe("errorTypeFrom", () => {
  it("reads a refused request as forbidden rather than an outage", () => {
    expect(errorTypeFrom(failedWith(403))).toBe(ErrorTypesEnum.FORBIDDEN);
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
