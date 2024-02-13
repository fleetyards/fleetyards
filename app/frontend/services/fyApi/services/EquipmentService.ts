/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { Equipment } from '../models/Equipment';
import type { EquipmentQuery } from '../models/EquipmentQuery';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class EquipmentService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Equipment list
     * @returns Equipment successful
     * @throws ApiError
     */
    public equipment({
        page = '1',
        perPage = '50',
        q,
        cacheId,
    }: {
        page?: string,
        perPage?: string,
        q?: EquipmentQuery,
        cacheId?: string,
    }): CancelablePromise<Array<Equipment>> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/equipment',
            query: {
                'page': page,
                'perPage': perPage,
                'q': q,
                'cacheId': cacheId,
            },
        });
    }
}
