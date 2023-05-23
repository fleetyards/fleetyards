# FleetYards.net API v1

> “Strap into one of dozens of ships and embark on a life within the Star Citizen universe. Unbound by profession or skill sets, you choose the path of your own life.”

This API provides basic Information about All Ships / Components / Manufacturers for the upcomming Space Simulation Star Citizen.

NOTE: This document is a **work in progress**.

## Current Version

The Current Version is ```v1``` and is included in each Request like this:
```
https://api.fleetyards.net/v1/ships
```

## Schema

All API access is over HTTPS, and accessed from the https://api.fleetyards.net. All data is sent and received as JSON.

Blank fields are included as null instead of being omitted.

### Timestamps

All timestamps return in ISO 8601 format:

```
YYYY-MM-DDTHH:MM:SSZ
```

### Summary Representations

When you fetch a list of resources, the response includes a subset of the attributes for that resource. This is the "summary" representation of the resource.

Example: When you get a list of models, you get the summary representation of each model:

```
GET /v1/models
```

### Detailed Representations

When you fetch an individual resource, the response typically includes all attributes for that resource. This is the "detailed" representation of the resource.

Example: When you get an individual model, you get the detailed representation of the model. Here, we fetch Origins ```300i``` repository:

```
GET /v1/models/300i
```

The documentation provides an example response for each API method. The example response illustrates all attributes that are returned by that method.

## Client Errors

## Authentication

## Pagination

Requests that return multiple items will be paginated to ```30``` items by default. 
You can specify further pages with the ```?page``` parameter.
For some resources, you can also set a custom page size up to ```200``` with the ```?perPage``` parameter. Note that for technical reasons not all endpoints respect the ```?perPage``` parameter, see events for example.

curl 'https://api.fleetyards.net/models?page=2&perPage=200'
Note that page numbering is 1-based and that omitting the ```?page``` parameter will return the first page.

### Link Header

The Link header includes pagination information:

```
Link: <https://api.fleetyards.net/models?page=1&perPage=200>; rel="next",
  <https://api.fleetyards.net/models?page=2&perPage=200>; rel="last"
```

The example includes a line break for readability.

This Link response header contains one or more Hypermedia link relations, some of which may require expansion as URI templates.

The possible ```rel``` values are:

Name | Description                                                  
----:| ------------------------------------------------------------
next | The link relation for the immediate next page of results.    
last | The link relation for the last page of results.              
first| The link relation for the first page of results.             
prev | The link relation for the immediate previous page of results.

## Rate Limiting
