/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { SessionInput } from '../models/SessionInput';
import type { StandardMessage } from '../models/StandardMessage';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class SessionsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * create session
     * @returns StandardMessage successful
     * @throws ApiError
     */
    public createSession({
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
    public deleteSession(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/sessions',
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
