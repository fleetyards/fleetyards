/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { HangarGroup } from '../models/HangarGroup';
import type { HangarGroupCreateInput } from '../models/HangarGroupCreateInput';
import type { HangarGroupUpdateInput } from '../models/HangarGroupUpdateInput';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class HangarGroupsService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * HangarGroup create
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public create({
        requestBody,
    }: {
        requestBody: HangarGroupCreateInput,
    }): CancelablePromise<HangarGroup> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public hangarGroups(): CancelablePromise<Array<HangarGroup>> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public destroy({
        id,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
    }): CancelablePromise<HangarGroup> {
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
     * @returns HangarGroup successful
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
    }): CancelablePromise<HangarGroup> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public deprecateDgetHangarGroups(): CancelablePromise<Array<HangarGroup>> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public deprecateDcreateHangarGroup({
        requestBody,
    }: {
        requestBody: HangarGroupCreateInput,
    }): CancelablePromise<HangarGroup> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public deprecateDdestroyHangarGroup({
        id,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
    }): CancelablePromise<HangarGroup> {
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
     * @returns HangarGroup successful
     * @throws ApiError
     */
    public deprecateDupdateHangarGroup({
        id,
        requestBody,
    }: {
        /**
         * HangarGroup ID
         */
        id: string,
        requestBody: HangarGroupUpdateInput,
    }): CancelablePromise<HangarGroup> {
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
    public deprecateDsortHangarGroups(): CancelablePromise<{
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
