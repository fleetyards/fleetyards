/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { VehicleQuery } from '../models/VehicleQuery';
import type { Vehicles } from '../models/Vehicles';
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';
export class VehiclesService {
    constructor(public readonly httpRequest: BaseHttpRequest) {}
    /**
     * Vehicles list
     * @returns Vehicles successful
     * @throws ApiError
     */
    public vehicles({
        page = '1',
        perPage = '30',
        s,
        q,
    }: {
        page?: string,
        perPage?: string,
        /**
         * Sorting
         */
        s?: Array<string>,
        q?: VehicleQuery,
    }): CancelablePromise<Vehicles> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles',
            query: {
                'page': page,
                'perPage': perPage,
                's': s,
                'q': q,
            },
            errors: {
                401: `unauthorized`,
            },
        });
    }
}
