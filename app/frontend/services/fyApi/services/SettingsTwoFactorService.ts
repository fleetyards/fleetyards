/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class SettingsTwoFactorService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * qrcode two_factor
     * @returns any successful
     * @throws ApiError
     */
    public getUsersTwoFactorQrcode(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users/two-factor/qrcode',
        });
    }

    /**
     * enable two_factor
     * @returns any successful
     * @throws ApiError
     */
    public postUsersTwoFactorEnable(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/two-factor/enable',
        });
    }

    /**
     * disable two_factor
     * @returns any successful
     * @throws ApiError
     */
    public postUsersTwoFactorDisable(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/two-factor/disable',
        });
    }

    /**
     * generate_backup_codes two_factor
     * @returns any successful
     * @throws ApiError
     */
    public postUsersTwoFactorGenerateBackupCodes(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/two-factor/generate-backup-codes',
        });
    }

}
