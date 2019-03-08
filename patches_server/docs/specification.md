# Patches-Server 1.0 Specification

Patches-Server, as a solution, has the responsibility of serving
vulnerabilities from a variety of sources to Patches-Scanners.  These scanners
will periodically poll Patches-Server, leaving the latter with time to retrieve
vulnerabilities and take time to manage server resources to avoid having to
retrieve the same vulnerabilities for each scanner that requests them.  When a
scanner requests vulnerabilities, it reports the platform that it is scanning,
such as Ubuntu 18.04, which Patches-Server uses to determine from where to
retrieve vulnerabilities and specifically which ones to request.

## Terminology

**Active Session**

> An active session is one that Patches-Server is actively serving
> vulnerabilities to.  A subset of sessions are activated at a time, taken on a
> first-come, first-served basis, so that Patches-Server can guarantee each
> active scanner will receive all vulnerabilities relevant to them.

**Queued Session**

> When a new session is opened for a scanner, it starts in a "queued" state
> within which it will not be served vulnerabilities.  Requests for vulns
> will result in a non-error response with an empty array of vulns.

## Conventions

### Types

* All input and output parameters at API boundaries will be annotated with
types using
[typescript](https://www.typescriptlang.org/docs/handbook/advanced-types.html)
notation.

### GET Requests

* All parameters to GET requests will be passed as query parameters.

### Non-GET requests (e.g. PUT, POST, etc.)

* All parameters to PUT, POST, etc. requests must be encoded as JSON in the
body of the request.

### Responses

* All response data will be returned as JSON in the body of the response.
* Appropriate status codes will be written to indicate success or
client/server failure.

## Design Challenges

Patches-Server is designed to address the following challenges:

1. A single server should be able to serve several thousand scanners at a time.
2. Any given vulnerability source may produce several gigabytes of data that
must be handled efficiently.
3. The server should be able to resume serving vulnerabilities between crashes.

## Architecture

The Patches-Server architecture is segmented into three components in order to address 
the design challenges outlined above.

### Vulnerability Source Readers

A single vulnerability source reader has the responsibility of retrieving
vulnerabilities for a specific platform, queueing them for ingestion by the
Patches-Server as well as maintaining a cache. This cache must be maintained
until the reader is informed that all cached vulnerabilities have been
processed and distributed to scanners.

### Vulnerability Source Manager

The vulnerability source manager facilitates communication between
Patches-Server and active vulnerability source readers.  In particular,
Patches-Server will send job requests and notifications of process completion
to the manager.  In response, the manager will forward jobs and notifications
to the appropriate reader.

### Patches Server

Patches-Server handles requests from Patches-Scanners.  It maintains a registry
tracking active and queued sessions as well as a cache of vulnerabilities
retrieved so that they can be dispensed to all relevant scanners with active
sessions.

## Protocol

### Patches-Server <-> Patches-Scanner

#### Opening a session

```
GET /?platform=<platform>
```

When a Patches-Scanner opens a session with Patches-Server, it must send a
`GET` request containing the name of the platform it is scanning in a query
parameter.  Accepted platform names are listed in the **Supported Platforms**
section of this document.

**Parameters**

* platform: `str`, a valid supported platform name

**Response**

* error: `null | str`, a string explaining any error that occurred trying
to process the request, or null if no error was encountered.
* session: `undefined | str`, a string of hex characters (a-f, 0-9) uniquely
identifying the session opened for the scanner.

Example request:

```
GET http://patches.server?platform=ubuntu:18.04
```

Example response body:

```json
{
    "error" null,
    "session": "abc123def456..." 
}
```

#### Retrieving prepared vulnerabilities

```
GET /?session=<session>
```

After a Patches-Scanner has opened a session, it may make requests to retrieve
any vulnerabilities prepared for it.

**Parameters**

* session: `str`, the unique session identifier provided to the scanner.

**Response**

* error: `null | str`, a string explaining any error that occurred trying
to process the request, or null if no error was encountered.
* vulnerabilities: `undefined | Array<Vulnerability>`, a list of
vulnerabilities prepared for the scanner.

Here, a `Vulnerability` has the following type, expressed using
[typescript](https://www.typescriptlang.org/docs/handbook/advanced-types.html)
notation.

```typescript
type Vulnerability = {
    name: str,
    affectedPlatform: str,
    detailsHref: str,
    severity: Severity,
    fixedIn: Array<Platform>
}

type Severity
    = 0 // Unknown
    | 1 // Negligible
    | 2 // Low
    | 3 // Medium
    | 4 // High
    | 5 // Urgent
    | 6 // Critical

type Platform = {
    name: str,
    version: str
}
```

Example request:

```
GET http://patches.server?session=abcdef0123456789
```

Example response body:

```json
{
    "error": null,
    "vulnerabilities": [
        {
            "name": "CVE-number",
            "affectedPlatform": "ubuntu:18.04",
            "detailsHref": "https://vulns.info/CVE-number",
            "severity": 3,
            "fixedIn": [
                {
                    "name": "vulnerablepackage",
                    "version": "1.2.3-alpha"
                }
            ]
        },
        {
            "name": "CVE-number",
            "affectedPlatform": "ubuntu:18.04",
            "detailsHref": "https://vulns.info/CVE-number2",
            "severity": 5,
            "fixedIn": [
                {
                    "name": "otherpackage",
                    "version": "1.0.0"
                },
                {
                    "name": "otherpackage",
                    "version": "0.9.1"
                }
            ]
        }
    ]
}
```

### Patches-Server <-> Vulnerability Source Manager

#### Requesting vulnerabilities

```
POST /jobs
```

When Patches-Server activates sessions, it will request that the VSM send a job
to the appropriate Vunerability Source Reader.  The Patches-Server must
indicate the platform for which vulnerabilities must be retrieved.

**Parameters**

* platform: `str`, the name of the platform to fetch vulnerabilities for.

**Response**

* job: `str`, an identifier for the job created to process this request.

Example request:

```json
POST /jobs
{
    "platform": "ubuntu:18.04"
}
```

Example response body:

```json
{
    "job": "abcdef0123456789"
}
```

#### Indicating the status of vuln ingestion

```
PUT /jobs/status
```

In any scenario in which Patches-Server crashes, it expects to be able to pick
up serving vulnerabilities from where it left off without having to retrieve
vulnerabilities already served a second time. To do this, Patches-Server will
indicate to the VSM when it has processed all of the vulns queued for a job.
Upon receiving such a status notification, the VSM will indicate to VSRs that
they may invalidate their caches, retrieve more vulnerabilities and then queue
those new vulns.

**Parameters**

* job: `str`, the unique identifer for a job being processed by a VSR.
* status: `'done' | 'restart'`
    * when the string "done" is sent, the VSM will indicate to the VSR
    processing the job that it should queue more vulnerabilities.
    * When the string "restart" is sent, the VSM will indicate to the
    appropriate VSR that it should resend its currently-cached vulns.

**Response**

* error: `null | str`, if the VSR processing the job identified has crashed or
is otherwise unable to continue processing the job, an error message indicating
such will be returned.

Example request:

```json
PUT /jobs/status
{
    "job": "abcdef0123",
    "status": "done"
}
```

Example response body:

```json
{
    "error": "The connection to the vulnerability source has been lost."
}
```