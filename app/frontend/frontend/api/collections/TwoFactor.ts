import { post } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class TwoFactorCollection extends BaseCollection<
  TTwoFactorBackupCodes,
  undefined
> {
  async generateBackupCodes(): Promise<TRecordResponse<TTwoFactorBackupCodes>> {
    const response = await post<TTwoFactorBackupCodes>(
      "users/two-factor/generate-backup-codes"
    );

    return this.recordResponse(response.data, response.error);
  }

  async start(): Promise<TRecordResponse<boolean>> {
    const response = await post<boolean>("users/two-factor/start");

    if (response.error) {
      return {
        error: this.extractErrorCode(response.error),
        errors: this.extractErrors(response.error),
      };
    }

    return {
      data: true,
    };
  }

  async enable(code: string): Promise<TRecordResponse<TTwoFactorBackupCodes>> {
    const response = await post<TTwoFactorBackupCodes>(
      "users/two-factor/enable",
      {
        twoFactorCode: code,
      }
    );

    return this.recordResponse(response.data, response.error);
  }

  async disable(code: string): Promise<TRecordResponse<boolean>> {
    const response = await post<boolean>("users/two-factor/disable", {
      twoFactorCode: code,
    });

    if (response.error) {
      return {
        error: this.extractErrorCode(response.error),
        errors: this.extractErrors(response.error),
      };
    }

    return {
      data: true,
    };
  }
}
export default new TwoFactorCollection();
