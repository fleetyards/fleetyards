/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ScDataVersion } from '../models/ScDataVersion';
import type { Version } from '../models/Version';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class VersionsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * SC Data Version
     * @returns ScDataVersion successful
     * @throws ApiError
     */
    public scDataVersion(): CancelablePromise<ScDataVersion> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/sc-data/version',
        });
    }
    /**
     * Version of Fleetyards
     * @returns Version successful
     * @throws ApiError
     */
    public version(): CancelablePromise<Version> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/version',
        });
    }
}
