/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ConfirmAccessInput } from '../models/ConfirmAccessInput';
import type { SessionInput } from '../models/SessionInput';
import type { StandardMessage } from '../models/StandardMessage';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class SessionsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * confirm_access session
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public postSessionsConfirmAccess({
        requestBody,
    }: {
        requestBody: ConfirmAccessInput,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/sessions/confirm-access',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
                401: `unauthorized`,
            },
        });
    }

    /**
     * create session
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public postSessions({
        requestBody,
    }: {
        requestBody: SessionInput,
    }): CancelablePromise<StandardMessage> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/sessions',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                400: `bad request`,
            },
        });
    }

    /**
     * delete session
     * @returns any successful
     * @throws ApiError
     */
    public deleteSessions(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/sessions',
            errors: {
                401: `unauthorized`,
            },
        });
    }

}
