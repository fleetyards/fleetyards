/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class SessionsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * create session
     * @returns any successful
     * @throws ApiError
     */
    public postSessions(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/sessions',
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
        });
    }

    /**
     * confirm_access session
     * @returns any successful
     * @throws ApiError
     */
    public postSessionsConfirmAccess(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/sessions/confirm-access',
        });
    }

}
