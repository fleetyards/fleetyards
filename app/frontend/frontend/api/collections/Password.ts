import { put } from "@/frontend/api/client";
import type { TApiResponse, TApiErrorResponse } from "@/frontend/api/client";

export class PasswordCollection {
  async update(
    token: string,
    form: TPasswordChangeForm
  ): Promise<TApiResponse<boolean> | TApiErrorResponse> {
    return put<boolean>(`password/update/${token}`, form);
  }
}

export default new PasswordCollection();
