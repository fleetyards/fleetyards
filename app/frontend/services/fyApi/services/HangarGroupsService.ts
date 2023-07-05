/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class HangarGroupsService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * list hangar_groups
     * @returns any successful
     * @throws ApiError
     */
    public getHangarGroups(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/hangar-groups',
        });
    }

    /**
     * create hangar_group
     * @returns any successful
     * @throws ApiError
     */
    public postHangarGroups(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/hangar-groups',
        });
    }

    /**
     * update hangar_group
     * @returns any successful
     * @throws ApiError
     */
    public patchHangarGroups({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/hangar-groups/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * update hangar_group
     * @returns any successful
     * @throws ApiError
     */
    public putHangarGroups({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar-groups/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * delete hangar_group
     * @returns any successful
     * @throws ApiError
     */
    public deleteHangarGroups({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/hangar-groups/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * sort hangar_group
     * @returns any successful
     * @throws ApiError
     */
    public putHangarGroupsSort(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/hangar-groups/sort',
        });
    }

}
