We can use GCP Artifact Registry as a VM image repo


== Creating Service Account Key
- https://docs.cloud.google.com/artifact-registry/docs/docker/authentication#json-key
- Created labs-artifact-registry@instruqt-kula.iam.gserviceaccount.com 

== Make Artifact Registry
- https://github.com/instruqt/lab-sdk/blob/2b4531cee60c6d6ce2fcfa9f64c41933e73ab655/build/images/publish.sh#L21
  - We use `REGISTRY="europe-west1-docker.pkg.dev/instruqt/instruqt-sandbox"`
  - The URL changes based on how you access it, so we have to make a "Docker" registry
    - Created in europe-west-1, disabled vuln scanning
  - https://console.cloud.google.com/artifacts/docker/instruqt-kula/europe-west1/lab-images?project=instruqt-kula
  - So `REGISTRY="europe-west1-docker.pkg.dev/instruqt-kula/lab-images"`
  - Give the service account respository-specific role https://docs.cloud.google.com/artifact-registry/docs/access-control#grant-repo - gave Artifact Registry Reader

== How we publish things to our built-in registry
- Add the following to ~/.docker/config.json:
  ```
  {
    "credHelpers": {
      "europe-west1-docker.pkg.dev": "gcloud"
    }
  }
  ```
- Push with
    ```
    $ oras push --artifact-type "text/plain" "europe-west1-docker.pkg.dev/instruqt-kula/lab-images/hello.world:latest" "hello.world:text/plain"
    ✓ Uploaded  hello.world                                                                          14/14  B 100.00%     1s
      └─ sha256:d9014c4624844aa5bac314773d6b689ad467fa4e1d1a50a1b8a99d5a95f72ff5                                            
    ✓ Uploaded  application/vnd.oci.empty.v1+json                                                      2/2  B 100.00%  718ms
      └─ sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a                                            
    ✓ Uploaded  application/vnd.oci.image.manifest.v1+json                                         537/537  B 100.00%  330ms
      └─ sha256:58a29a8a6d35a32fd9dacce7b7135ef995dcdf9ab3e542795446ecca29e8fac0                                            
    Pushed [registry] europe-west1-docker.pkg.dev/instruqt-kula/lab-images/hello.world:latest
    ArtifactType: text/plain
    Digest: sha256:58a29a8a6d35a32fd9dacce7b7135ef995dcdf9ab3e542795446ecca29e8fac0
    ```

== Other useful stuff
- https://github.com/instruqt/lab-sdk/blob/06999bdbaae0343e33cfa918d29be9413c93efbb/pkg/clients/oci/oci.go
- https://github.com/instruqt/infrastructure/blob/7b0553a50b0a8d607308c48b69d7cb2ac1c198e7/infra/bootstrap/artifact_registry.tf#L192-L219 --- how we create the internal registry
- https://github.com/instruqt/technical-designs/blob/9313c1b93af73e179bb3495b375c0c555f61eb1d/TD-003/README.md - VM Support in Labs

