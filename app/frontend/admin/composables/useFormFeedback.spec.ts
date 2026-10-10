import { describe, expect, it, vi, beforeEach } from "vitest";
import { AxiosError, AxiosHeaders } from "axios";
import { useFormFeedback } from "./useFormFeedback";

const notifications = vi.hoisted(() => ({
  displaySuccess: vi.fn(),
  displayAlert: vi.fn(),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => notifications,
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

const validationError = () =>
  new AxiosError("Bad Request", "400", undefined, undefined, {
    status: 400,
    statusText: "Bad Request",
    headers: {},
    config: { headers: new AxiosHeaders() },
    data: {
      code: "validation_error",
      message: "Name is already taken",
      errors: [
        {
          attribute: "name",
          messages: [{ code: "taken", message: "is already taken" }],
        },
      ],
    },
  });

describe("useFormFeedback", () => {
  beforeEach(() => {
    notifications.displaySuccess.mockReset();
    notifications.displayAlert.mockReset();
  });

  it("confirms a created record", () => {
    useFormFeedback().created();

    expect(notifications.displaySuccess).toHaveBeenCalledWith({
      text: "messages.admin.form.created",
    });
  });

  it("confirms saved changes", () => {
    useFormFeedback().updated();

    expect(notifications.displaySuccess).toHaveBeenCalledWith({
      text: "messages.admin.form.updated",
    });
  });

  it("shows the server's message and marks the fields it refused", () => {
    const setErrors = vi.fn();

    useFormFeedback().failed(validationError(), setErrors);

    expect(setErrors).toHaveBeenCalledWith({ name: ["is already taken"] });
    expect(notifications.displayAlert).toHaveBeenCalledWith({
      text: "Name is already taken",
    });
  });

  it("falls back to a generic message when the server sends none", () => {
    useFormFeedback().failed(new Error("Network Error"));

    expect(notifications.displayAlert).toHaveBeenCalledWith({
      text: "errors.generic",
    });
    expect(notifications.displaySuccess).not.toHaveBeenCalled();
  });
});
