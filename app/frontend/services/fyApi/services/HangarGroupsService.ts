/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarGroupCreateInput } from '../models/HangarGroupCreateInput';
import type { HangarGroupMinimal } from '../models/HangarGroupMinimal';
import type { HangarGroupUpdateInput } from '../models/HangarGroupUpdateInput';

import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class HangarGroupsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * HangarGroup create
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public hangarGroupCreate({
        requestBody,
    }: {
        requestBody: HangarGroupCreateInput,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/hangar/groups',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * HangarGroup list
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public hangarGroups(): CancelablePromise<Array<HangarGroupMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar/groups',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * HangarGroup Destroy
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public hangarGroupDestroy({
        id,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/hangar/groups/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * HangarGroup Update
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public hangarGroupUpdate({
        id,
        requestBody,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
        requestBody: HangarGroupUpdateInput,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar/groups/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * HangarGroup sort
     * @returns any successful
     * @throws ApiError
     */
    public hangarGroupSort(): CancelablePromise<{
        success?: boolean;
    }> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar/groups/sort',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * @deprecated
     * HangarGroup list
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public getHangarGroups(): CancelablePromise<Array<HangarGroupMinimal>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar-groups',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * @deprecated
     * HangarGroup create
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public postHangarGroups({
        requestBody,
    }: {
        requestBody: HangarGroupCreateInput,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/hangar-groups',
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
            },
        });
    }

    /**
     * @deprecated
     * HangarGroup Destroy
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public deleteHangarGroups({
        id,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/hangar-groups/{id}',
            path: {
                'id': id,
            },
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * @deprecated
     * HangarGroup Update
     * @returns HangarGroupMinimal successful
     * @throws ApiError
     */
    public putHangarGroups({
        id,
        requestBody,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
        requestBody: HangarGroupUpdateInput,
    }): CancelablePromise<HangarGroupMinimal> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar-groups/{id}',
            path: {
                'id': id,
            },
            body: requestBody,
            mediaType: 'application/json',
            errors: {
                401: `unauthorized`,
                404: `not found`,
            },
        });
    }

    /**
     * @deprecated
     * HangarGroup sort
     * @returns any successful
     * @throws ApiError
     */
    public putHangarGroupsSort(): CancelablePromise<{
        success?: boolean;
    }> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar-groups/sort',
            errors: {
                401: `unauthorized`,
            },
        });
    }

}
