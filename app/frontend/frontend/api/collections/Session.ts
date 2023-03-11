import { post, destroy } from "@/frontend/api/client";
import type { TApiResponse, TApiErrorResponse } from "@/frontend/api/client";

export class SessionCollection {
  create(
    params: TSessionParams
  ): Promise<TApiResponse<TPlainResponse> | TApiErrorResponse> {
    return post<TPlainResponse>("sessions", params, true);
  }

  async destroy(): Promise<boolean> {
    const response = await destroy("sessions");

    if (!response.error) {
      return true;
    }

    return false;
  }

  async confirmAccess(password: string): Promise<boolean> {
    const response = await post<boolean>("sessions/confirm-access", {
      password,
    });

    if (!response.error) {
      return true;
    }

    return false;
  }
}

export default new SessionCollection();
