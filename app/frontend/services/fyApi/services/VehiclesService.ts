/* generated using openapi-typescript-codegen -- do no edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { CancelablePromise } from '../core/CancelablePromise';
import type { BaseHttpRequest } from '../core/BaseHttpRequest';

export class VehiclesService {

    constructor(public readonly httpRequest: BaseHttpRequest) {}

    /**
     * @deprecated
     * list vehicles
     * @returns any successful
     * @throws ApiError
     */
    public getVehicles(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles',
        });
    }

    /**
     * create vehicle
     * @returns any successful
     * @throws ApiError
     */
    public postVehicles(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/vehicles',
        });
    }

    /**
     * update vehicle
     * @returns any successful
     * @throws ApiError
     */
    public patchVehicles({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PATCH',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * update vehicle
     * @returns any successful
     * @throws ApiError
     */
    public putVehicles({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * delete vehicle
     * @returns any successful
     * @throws ApiError
     */
    public deleteVehicles({
        id,
    }: {
        /**
         * id
         */
        id: string,
    }): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/vehicles/{id}',
            path: {
                'id': id,
            },
        });
    }

    /**
     * fleetchart vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesFleetchart(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/fleetchart',
        });
    }

    /**
     * export vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesExport(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/export',
        });
    }

    /**
     * import vehicle
     * @returns any successful
     * @throws ApiError
     */
    public putVehiclesImport(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/import',
        });
    }

    /**
     * update_bulk vehicle
     * @returns any successful
     * @throws ApiError
     */
    public putVehiclesBulk(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/bulk',
        });
    }

    /**
     * destroy_bulk vehicle
     * @returns any successful
     * @throws ApiError
     */
    public putVehiclesDestroyBulk(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'PUT',
            url: '/vehicles/destroy-bulk',
        });
    }

    /**
     * destroy_all vehicle
     * @returns any successful
     * @throws ApiError
     */
    public deleteVehiclesDestroyAll(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'DELETE',
            url: '/vehicles/destroy-all',
        });
    }

    /**
     * embed vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesEmbed(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/embed',
        });
    }

    /**
     * hangar_items vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesHangarItems(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/hangar-items',
        });
    }

    /**
     * hangar vehicle
     * @returns any successful
     * @throws ApiError
     */
    public getVehiclesHangar(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'GET',
            url: '/vehicles/hangar',
        });
    }

    /**
     * check_serial vehicle
     * @returns any successful
     * @throws ApiError
     */
    public postVehiclesCheckSerial(): CancelablePromise<any> {
        return this.httpRequest.request({
            method: 'POST',
            url: '/vehicles/check-serial',
        });
    }

}
