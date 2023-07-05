/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class CurrentUserService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * current user
     * @returns any successful
     * @throws ApiError
     */
    public getUsersCurrent(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/users/current',
        });
    }

    /**
     * update user
     * @returns any successful
     * @throws ApiError
     */
    public putUsersCurrent(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/users/current',
        });
    }

    /**
     * update user
     * @returns any successful
     * @throws ApiError
     */
    public patchUsersCurrent(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/users/current',
        });
    }

    /**
     * delete user
     * @returns any successful
     * @throws ApiError
     */
    public deleteUsersCurrent(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/users/current',
        });
    }

    /**
     * signup user
     * @returns any successful
     * @throws ApiError
     */
    public postUsersSignup(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/signup',
        });
    }

    /**
     * confirm user
     * @returns any successful
     * @throws ApiError
     */
    public postUsersConfirm(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/confirm',
        });
    }

    /**
     * check_email user
     * @returns any successful
     * @throws ApiError
     */
    public postUsersCheckEmail(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/check-email',
        });
    }

    /**
     * check_username user
     * @returns any successful
     * @throws ApiError
     */
    public postUsersCheckUsername(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/users/check-username',
        });
    }

    /**
     * update_account user
     * @returns any successful
     * @throws ApiError
     */
    public putUsersCurrentAccount(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/users/current-account',
        });
    }

    /**
     * update_account user
     * @returns any successful
     * @throws ApiError
     */
    public patchUsersCurrentAccount(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/users/current-account',
        });
    }

}
