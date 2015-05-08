Requirements:

* RPMs signed using a HSM on a secure server that does not expose any public services.
* Builds automatically trigger the staging of RPMs on the signing server.
* Signatures are not applied until manually authorized by a signing admin.

Implementation:

* Server polls for new builds and signing requests. This means all actions are pull not push, and no services are exposed.
* The server keeps a list of authorized GPG keys. Signing requests consist of the build ID to be signed in a message clearsigned by the signing admin.
* Signing requests are transmitted via email. The security of the email account is not important, because only signing requests that are signed by an authorized signing admin will be acted on.

Workflow:

 1. Server: Poll Jenkins build server looking for new builds (poll-build.sh)
 2. Server: Download build and notify signing admin(s) via email (poll-build.sh)
 3. Client: Verify that the build should be signed, construct signing email (generate-signing-email.sh)
 4. Client: Send signing email to cloudroutersign@gmail.com 
 5. Server: Poll gmail for new messages (poll-email.py)
 6. Download message, check it contains a clearsigned message from an authorized user. The body of the clearsigned message is the build ID. If valid, sign the build artifacts (process-email.sh)

All server-side actions are triggered by cron jobs run every minute. Client-side actions are manual.
