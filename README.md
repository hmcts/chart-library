# chart-library

This repository is the foundation to most other templated application specific helm charts used across the project:
- [chart-java](https://github.com/hmcts/chart-java)
- [chart-nodejs](https://github.com/hmcts/chart-nodejs)
- [chart-job](https://github.com/hmcts/chart-job)
- [chart-function](https://github.com/hmcts/chart-function)
- [chart-base](https://github.com/hmcts/chart-base)
- [chart-blobstorage](https://github.com/hmcts/chart-blobstorage)
- [chart-postrgesql](https://github.com/hmcts/chart-postgresql)
- [chart-neuvector](https://github.com/hmcts/chart-neuvector)
- [chart-servicebus](https://github.com/hmcts/chart-servicebus)


The [library chart](https://helm.sh/docs/topics/library_charts/) contains [named helm templates](https://helm.sh/docs/chart_template_guide/named_templates/) that are manipulated through Values files in the application helm charts, to provide structured, reusable and consistent YAML files that are deployed to our AKS clusters holding common Kubernetes resource configurations.

Using a central library chart allows us to roll out changes to resources across the estate in a scalable and efficient way. It is explicitly different to an application chart, and is not installable.

## Making a change to chart-library

Because this is the foundational level of all our templated helm charts, it's critical that changes made to this repo are well tested with feature flagged changes. A breaking change in chart-library will be inherited by all charts that consume it as a dependency. 

**Because renovate is used across the estate, as soon as a new chart-xyz version is released, it will be raised as a Pull Request and potentially automerged by renovate to team application repositories**, this is why feature flagging and testing is so important when making changes to this repo.

When you release a new version of chart-library, it's ideal to ensure all consuming application charts are updated to include the change, with new releases also made for each of them. This ensures we are as up to date as possible with central template changes across the board.

### How is chart-library used by application charts?

It is included as a helm dependency, so all template definitions are made available to any application chart.

```yaml
dependencies:
  - name: library
    version: 2.2.1
    repository: https://hmctspublic.azurecr.io/helm/v1/repo/
```
Each application chart can pick and choose which templates to add by [defining them](https://github.com/hmcts/chart-java/blob/master/java/templates/configmap.yaml).

Application charts can manipulate the template logic by including and manipulating variables in their [values.yaml](https://github.com/hmcts/chart-java/blob/master/java/values.yaml).

### Feature Flagging
We should avoid making breaking changes to this repository wherever possible. To keep things as compatible as possible, any new functionality or changed functionality should always be behind a feature flag (a variable that gets checked from values.yaml in this case), so teams can toggle features or functionality in their `values.yaml` file.

A good simple example of this is [CPU autoscaling](https://github.com/hmcts/chart-library/blob/48a0176cdb6dc30907e0cdfa4a5c000c13e3cb1c/library/templates/v2/_hpa.tpl#L19-L27)
```yaml
  {{- if $languageValues.autoscaling.cpu.enabled }}
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ $languageValues.autoscaling.cpu.averageUtilization }}
  {{- end }}
```

If an application chart defines the following their `values.yaml` file, the feature `CPU autoscaling` will be enabled. But we are not forcing people to accept the change.
```yaml
autoscaling:
  cpu:
    enabled: true
```

This concept can be extended to any new feature or change in the library, it allows people to consume Library Chart updates, without having to accept every single feature which might not suit their use case.

For situations where we **need** to make a breaking change, a new major version of chart-library should be released with clear documentation in the release notes.

### Release Pattern and Testing Functionality
chart-library uses semantic versioning via GitHub releases to publish versioned Library Charts. Releases are generally handled by an automated process called [Release Drafter](https://github.com/hmcts/chart-library/blob/master/.github/workflows/release-drafter.yml).

As well as feature flagging, you should be testing your code changes by creating a new alpha or beta release from your PR branch, this adds another layer of detection for potential issues. For example [2.1.3-alpha](https://github.com/hmcts/chart-library/releases/tag/2.1.3-alpha). It's important that you mark this as a pre-release version and not the latest version. This stops the likes of Renovate thinking a new version is available and raising a PR to upgrade it.

<img src="release-drafter.png" alt="image showing what checkbox marks an alpha release as pre-release" width="750" height="750"/>


You can then draft a pre-release version of an application chart like chart-java, by raising a PR that bumps the library dependency to the alpha release you created, and test with plum or toffee that the new chart-library works and is deployable to AKS without issues.


#### Example of testing 2.1.3-alpha chart-library release: 
- [PR which points to alpha release](https://github.com/hmcts/chart-java/commit/35234f39c8cea7e22bb0c70b8869dbfb809c3c23)
- [Alpha pre-release of chart-java](https://github.com/hmcts/chart-java/releases/tag/5.2.1-alpha) - created as a draft release from your PR branch
- Test this version with plum or toffee works on AKS as expected, expirement with different values.yaml changes

**For particularly complex or potentially breaking changes, you should be toggling features on and off and seeing that things work as expected in the plum/toffee deployment using these alpha pre-release charts**, this allows you to fully test the helm templates on AKS and spot things our other tests may miss.

Only once you've done this and ensured there will be no breaking changes in your chart-library update, you can get your PR reviewed by a member of Platform Operations.
When a PR has been approved and merged, you also need to publish a new release for consumption by dependent application charts.
Once your PR is merged, the [releases tab](https://github.com/hmcts/chart-library/releases) will show a new draft release. You should ensure the release description is accurate and detailed, and contains any relevant labels.
There is a [KT session](https://justiceuk.sharepoint.com/sites/DTSPlatformOperations/_layouts/15/stream.aspx?id=%2Fsites%2FDTSPlatformOperations%2FShared%20Documents%2FGeneral%2Fknowledge%2Dsharing%2FAn%20intro%20to%20chart%2Dlibrary%20and%20release%20drafter%2Emp4&referrer=StreamWebApp%2EWeb&referrerScenario=AddressBarCopied%2Eview%2E21e9590c%2D4de1%2D41ed%2Dbff9%2Dd65eb9e3284c) which details this process, and how to ideally take a PR through from conception to the latest published release.
You can then mark it as the latest release.

You can read more about this [draft release process](https://hmcts.github.io/ops-runbooks/Testing-Changes/drafting-a-release.html) in more depth

## Template Configuration

### Language

- Default values can be overridden over normal defaults for a specific language.

  Example:  
    ```yaml
    <new-lang>:
      applicationPort : 5000
      memoryLimits: "256Mi"
    ```
- Applications using the template can just choose default recommended settings for a language by setting `language` property

    ```yaml
    language: <new-lang>
    ```
- This is supported in all v2 templates in the library.
- Currently, if we set boolean properties to `true` by default, we are not able to override to `false` in language specific values.

### Release Name

Behaviour is applicable for all templates

| Parameter                   | Description                                                                                                                         | 
|-----------------------------|-------------------------------------------------------------------------------------------------------------------------------------|
| `releaseNameOverride`       | Will override the default resource name - It supports templating, example:`releaseNameOverride: {{ .Release.Name }}-my-custom-name` |
| `releaseNamePrefix`         | Prefix for the release name                                                                                                         |
| `.global.releaseNamePrefix` | Global Prefix for the release name                                                                                                  |
| `releaseNameSuffix`         | Suffix for the release name                                                                                                         |
| `.global.releaseNameSuffix` | Global Suffix for the release name                                                                                                  |

The applied order is: `global prefix + prefix + name + suffix + global suffix`

### Deployment


| Parameter  | Description            |
|------------|------------------------|
| `replicas` | Number of pod replicas |

It includes below templates :

- [PodTemplate spec](#PodTemplate)

### PodTemplate

| Parameter                 | Description                                                                                                 |
|---------------------------|-------------------------------------------------------------------------------------------------------------|
| `saEnabled`               | Flag to Enable Service Account                                                                              |
| `affinity`                | Pod/Node affinity and anti-affinity set as `yaml` |

It includes below templates :
- [Metadata](#Metadata)
- [DNS Config](#DNS-Config)
- [Container](#Container)

### Metadata

| Parameter            | Description                               |
|----------------------|-------------------------------------------|
| `aadIdentityName`    | Added as a label for binding pod identity |
| `prometheus.enabled` | Enables adding prometheus annotations     |
| `prometheus.path`    | Path for scraping prometheus metrics      |

### DNS Config

| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `dnsConfig.ndots` | Threshold for the number of dots which must appear in a name given to a dns query before an initial absolute query will be made
| `dnsConfig.singleRequestTcp` | Use `single-request-reopen` + `use-vc` options of resolver. If A and AAAA requests from the same port are not handled correctly the resolver will close the socket and open a new one before sending the second request. Also DNS queries use TCP protocol. Solves https://github.com/kubernetes/kubernetes/issues/56903

### Container

| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `applicationPort`          | The port your app runs on in its container |
| `image`                    | Full image url | `hmctssandbox.azurecr.io/hmcts/spring-boot-template`<br>(but overridden by pipeline) |
| `environment`              |  A map containing all environment values you wish to set. <br> **Note**: environment variables (the key in KEY: value) must be uppercase and only contain letters,  "_", or numbers and value can be templated |
| `configmap`                | A config map, can be used for environment specific config.| 
| `envFromSecret`            | Maps all key-value pairs in a Secret as container environment variables| 
| `devmemoryRequests`        | Requests for memory, set when `global.devMode` is set to true |
| `devcpuRequests`           | Requests for cpu, set when `global.devMode` is set to true |
| `devmemoryLimits`          | Memory limits, set when `global.devMode` is set to true| 
| `devcpuLimits`             | CPU limits, set when `global.devMode` is set to true | 
| `memoryRequests`           | Requests for memory, set when `global.devMode` is set to false | 
| `cpuRequests`              | Requests for cpu, set when `global.devMode` is set to false |
| `memoryLimits`             | Memory limits, set when `global.devMode` is set to false|
| `cpuLimits`                | CPU limits, set when `global.devMode` is set to false |
| `readinessPath`            | Path of HTTP readiness probe |
| `readinessDelay`           | Readiness probe initial delay (seconds)|
| `readinessTimeout`         | Readiness probe timeout (seconds)|
| `readinessPeriod`          | Readiness probe period (seconds) |
| `livenessPath`             | Path of HTTP liveness probe |
| `livenessDelay`            | Liveness probe initial delay (seconds)  |
| `livenessTimeout`          | Liveness probe timeout (seconds) |
| `livenessPeriod`           | Liveness probe period (seconds) | 
| `livenessFailureThreshold` | Liveness failure threshold |
| `startupPath`              | Path of HTTP startup probe |
| `startupDelay`             | Startup probe initial delay (seconds)  |
| `startupTimeout`           | Startup probe timeout (seconds) |
| `startupPeriod`            | Startup probe period (seconds) | 
| `startupFailureThreshold`  | Startup failure threshold |
| `args`                     | Arguments to pass to the container |
| `command`                  | Commands to pass to the container |

It includes below templates :
- [Key Vault Secrets](#KeyVault-Secret-CSI-Volumes)
- [Kubernetes Secrets As Environment Variables](#kubernetes-secrets-as-environment-variables)

### KeyVault Secret CSI Volumes
| Parameter          | Description                                                                                                                     |
|--------------------|---------------------------------------------------------------------------------------------------------------------------------|
| `disableKeyVaults` | Disables key vault support, useful in pull requests if you don't need any secrets (usually because you're using an embedded DB) |
| `keyVaults`        | Mappings of keyvaults to be mounted as CSI Volumes (see Example Configuration)                                                  | 
| `aadIdentityName`  | Pod identity binding for accessing the key vaults                                                                               |
| `mountPath`        | (Optional) Custom path to mount the secrets to the pod. Default: `/mnt/secrets/<VAULT_NAME>`                                    |

#### Example for adding Azure Key Vault Secrets
Key vault secrets can be mounted to the container filesystem using what's called a [secrets-store-csi-driver-provider-azure](https://github.com/Azure/secrets-store-csi-driver-provider-azure). This means that the keyvault secrets are accessible as files after they have been mounted.
To do this you need to add the **keyVaults** section to the configuration.
```yaml
aadIdentityName: <Identity Binding>
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      disabled: true
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
    <VAULT_NAME_2>:
      secrets:
        - <SECRET_NAME>
        - <SECRET_NAME2>
```

#### Example for adding Azure Key Vault Secrets using aliases
In some cases, you may want to alias the secrets to a different name (An environment variable for example), you can configure it using

```yaml
aadIdentityName: <Identity Binding>
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      secrets:
        - name: <SECRET_NAME>
          alias: <SECRET_ALIAS>
        - name: <SECRET_NAME2>
          alias: <SECRET_ALIAS2>
```

#### Example for adding Environment Name to Azure Key Vault Secrets
In some cases, you may want to have the environment name in the secret name, you can configure it by adding `<ENV>` in the secret name

```yaml
aadIdentityName: <Identity Binding>
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      secrets:
        - name: example-secret-<ENV>
          alias: <SECRET_ALIAS>
        - name: secret-<ENV>-example
```


#### Example for adding Azure Key Vault Certificates
Key vault certificates can be mounted to the container filesystem using what's called a [secrets-store-csi-driver-provider-azure](https://github.com/Azure/secrets-store-csi-driver-provider-azure). This means that the keyvault certificates are accessible as files after they have been mounted.
To do this you need to add the **keyVaults** section to the configuration.
```yaml
aadIdentityName: <Identity Binding>
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      disabled: true
      certs:
        - <CERT_NAME>
        - <CERT_NAME2>
    <VAULT_NAME_2>:
      certs:
        - <CERT_NAME>
        - <CERT_NAME2>
```

#### Example for adding Azure Key Vault Certificates using aliases
In some cases, you may want to alias the certificates to a different name (An environment variable for example), you can configure it using

```yaml
aadIdentityName: <Identity Binding>
keyVaults:
    <VAULT_NAME>:
      excludeEnvironmentSuffix: true
      certs:
        - name: <CERT_NAME>
          alias: <CERT_ALIAS>
        - name: <CERT_NAME2>
          alias: <CERT_ALIAS2>
```


**Where**:
- *<VAULT_NAME>*: Name of the vault to access without the environment tag i.e. `s2s` or `bulkscan`.
- *<SECRET_NAME>*: Secret name as it is in the vault. Note this is case and punctuation sensitive. i.e. in s2s there is the `microservicekey-cmcLegalFrontend` secret.
- *<SECRET_ALIAS>*: Alias name for the secret.
- *excludeEnvironmentSuffix*: This is used for the global key vaults 
- *<CERT_NAME>*: Certificate name as it is in the vault. Note this is case and punctuation sensitive. i.e. in s2s there is the `microservicekey-cmcLegalFrontend` certificate.
- *<CERT_ALIAS>*: Alias name for the certificate.
- *excludeEnvironmentSuffix*: This is used for the global key vaults where there is not environment suffix ( e.g `-aat` ) required. It defaults to false if it is not there and should only be added if you are using a global key-vault.
- *disabled*: This is an optional field used to disable a specific key vault, useful when overriding defaults.
- When not using Jenkins, explicitly set global.enableKeyVaults to `true` .

### Ingress

| Parameter                                  | Description                                                                                                                                                                                                    | Default |
|--------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|
| `ingressHost`                              | Host for ingress controller to map the container to. It supports templating, Example : {{.Release.Name}}.service.core-compute-preview.internal                                                                 | `nil`   |
| `registerAdditionalDns.enabled`            | If you want to use this chart as a secondary dependency - e.g. providing a frontend to a backend, and the backend is using primary ingressHost DNS mapping.                                                    | `false` |
| `registerAdditionalDns.primaryIngressHost` | The hostname for primary chart. It supports templating, Example : {{.Release.Name}}.service.core-compute-preview.internal                                                                                      | `nil`   |
| `registerAdditionalDns.prefix`             | DNS prefix for this chart - will resolve as: `prefix-{registerAdditionalDns.primaryIngressHost}`                                                                                                               | `nil`   |
| `disableTraefikTls`                        | Boolean value to enable or disable TLS on application specific HTTP router created on Traefik ingress controller. This will usually be set by Jenkins through global which takes precedence over app settings. | `false` |
| `additionalIngressHosts`                   | List of string values for additional ingress hosts. For example ["one.domain.com", "two.domain.com"]                                                                                                           | `nil`   |

### Pod Disruption Budget

| Parameter            | Description                                                                                                                                                                                                                                                     | Default                                                                                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `pdb.enabled`        | To enable PodDisruptionBudget on the pods for handling disruptions                                                                                                                                                                                              | `true`                                                                                                                                                    |
| `pdb.maxUnavailable` | To configure the number of pods from the set that can be unavailable after the eviction. It can be either an absolute number or a percentage. pdb.minAvailable takes precedence over this if not nil                                                            | `50%` means evictions are allowed as long as no more than 50% of the desired replicas are unhealthy. It will allow disruption if you have only 1 replica. |
| `pdb.minAvailable`   | To configure the number of pods from that set that must still be available after the eviction, even in the absence of the evicted pod. minAvailable can be either an absolute number or a percentage. This takes precedence over pdb.maxUnavailable if not nil. | `nil`                                                                                                                                                     |

### Kubernetes Secrets as Environment Variables

| Parameter | Description                                                                               | Default |
|-----------|-------------------------------------------------------------------------------------------|---------|
| `secrets` | Mappings of environment variables to service objects or pre-configured kubernetes secrets | nil     |

To map existing kubernetes secrets such as passwords to environment variable in the container. e.g :

```yaml
secrets: 
  CONNECTION_STRING:
      secretRef: some-secret-reference
      key: connectionString
      disabled: false
```

Where:

CONNECTION_STRING is the environment variable to set to the value of the secret ( this has to be capitals and can contain numbers or "_" ).
secretRef is the service instance ( as in the case of PaaS wrappers ) or reference to the secret volume. It supports templating in values.yaml . Example : secretRef: some-secret-reference-{{ .Release.Name }}
key is the named secret in the secret reference.
disabled is optional and used to disable setting this environment value. This can be used to override the behaviour of default chart secrets.


### Startup Probes

Startup probes are intended to provide a mechanism for allowing slow starting applications perform the relevant checks to determine the application has fully started before commencement of higher level liveness and readiness probes.  

Prior to the availability of startup probes, such applications have liveness probes configured with a relatively long (more than 60s) livenessDelay as a means of allowing sufficient time to startup before probes become active.  

Whilst this achieves intended effect, it also means timely detection of deadlocks does not occur during the period the container successfully starts up much faster than the specified initialDelaySeconds.

To use startup probes, refer to instructions for the relevant dependant charts below:   
- [chart-java](https://github.com/hmcts/chart-java/tree/master#startup-probes)    
- [chart-nodejs](https://github.com/hmcts/chart-nodejs/tree/master#startup-probes)

### HPA Horizontal Pod Auto scaler
To adjust the number of pods in a deployment depending on CPU utilization AKS supports horizontal pod autoscaling. To enable horizontal pod autoscaling you can enable the autoscaling section. https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale#autoscale-pods

| Parameter                               | Description                                                              | Default |
|-----------------------------------------|--------------------------------------------------------------------------|---------|
| `autoscaling.enabled`                   | Enable horizontal pod autoscaling.                                       | `false` |
| `autoscaling.enabledForDevMode`         | Additional flag needed to enable horizontal pod autoscaling in Dev mode. | `false` |
| `autoscaling.maxReplicas`               | Max replica count. Optional, will use value of `replicas` + 2 if not set | ``      |
| `autoscaling.minReplicas`               | Min replica count. Optional, will use value of `replicas` if not set     | ``      |
| `autoscaling.cpu.enabled`               | Enable CPU based Autoscaling                                             | `true`  |
| `autoscaling.cpu.averageUtilization`    | Average CPU utilization                                                  | `80`    |
| `autoscaling.memory.enabled`            | Enable Memory based Autoscaling                                          | `true`  |
| `autoscaling.memory.averageUtilization` | Average memory utilization                                               | `80`    |


Example Config:

```yaml
autoscaling:        
  enabled: true     # Default is false
  maxReplicas: 5    # Optional setting, will use the value of replicas + 2 if not set
  minReplicas: 2    # Optional setting, will use the value of replicas if not set
  cpu:
    averageUtilization: 80 # Default is 80% Average CPU utilization 
  memory:
    averageUtilization: 80 # Default is 80% Average memory utilization  
```

### Smoke and functional tests

| Parameter                            | Description                                                                                                                       | Default                                       |
|--------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------|
| `testsConfig.keyVaults`              | Tests keyvaults config [here](#example-for-adding-azure-key-vault-secrets-using-aliases). Shared by all tests pods                | `nil`                                         |
| `testsConfig.environment`            | Tests environment variables. Shared by all tests pods. Merged, with duplicate variables overridden, by specific tests environment | `nil`                                         |
| `testsConfig.memoryRequests`         | Tests Requests for memory. Applies to all test pods. Can be overridden by single test pods                                        | `256Mi`                                       |
| `testsConfig.cpuRequests`            | Tests Requests for cpu. Applies to all test pods. Can be overridden by single test pods                                           | `100m`                                        |
| `testsConfig.memoryLimits`           | Tests Memory limits. Applies to all test pods. Can be overridden by single test pods                                              | `1024Mi`                                      |
| `testsConfig.cpuLimits`              | Tests CPU limits. Applies to all test pods. Can be overridden by single test pods                                                 | `1000m`                                       |
| `smoketests.enabled`                 | Enable smoke tests single run after deployment.                                                                                   | `false`                                       |
| `smoketests.image`                   | Full smoke tests image url.                                                                                                       | `hmctspublic.azurecr.io/spring-boot/template` |
| `smoketests.environment`             | Smoke tests environment variables. Merged with testsConfig.environment. Overrides duplicates.                                     | `nil`                                         |  
| `smoketests.memoryRequests`          | Smoke tests Requests for memory                                                                                                   | `256Mi`                                       |
| `smoketests.cpuRequests`             | Smoke tests Requests for cpu                                                                                                      | `100m`                                        |
| `smoketests.memoryLimits`            | Smoke tests Memory limits                                                                                                         | `1024Mi`                                      |
| `smoketests.cpuLimits`               | Smoke tests CPU limits                                                                                                            | `1000m`                                       |
| `functionaltests.enabled`            | Enable functional tests single run after deployment.                                                                              | `false`                                       |
| `functionaltests.image`              | Full functional tests image url.                                                                                                  | `hmctspublic.azurecr.io/spring-boot/template` |
| `functionaltests.environment`        | Functional tests environment variables. Merged with testsConfig.environment. Overrides duplicates.                                | `nil`                                         |  
| `functionaltests.memoryRequests`     | Functional tests Requests for memory                                                                                              | `256Mi`                                       |
| `functionaltests.cpuRequests`        | Functional tests Requests for cpu                                                                                                 | `100m`                                        |
| `functionaltests.memoryLimits`       | Functional tests Memory limits                                                                                                    | `1024Mi`                                      |
| `functionaltests.cpuLimits`          | Functional tests CPU limits                                                                                                       | `1000m`                                       |
| `smoketestscron.enabled`             | Enable smoke tests cron job. Runs tests at scheduled times                                                                        | `false`                                       |
| `smoketestscron.schedule`            | Cron expression for scheduling smoke tests cron job                                                                               | `20 0/1 * * *`                                |
| `smoketestscron.image`               | Full cron smoke tests image url.                                                                                                  | `hmctspublic.azurecr.io/spring-boot/template` |
| `smoketestscron.environment`         | Smoke cron tests environment variables. Merged with testsConfig.environment. Overrides duplicates.                                | `nil`                                         |  
| `smoketestscron.memoryRequests`      | Smoke cron tests Requests for memory                                                                                              | `256Mi`                                       |
| `smoketestscron.cpuRequests`         | Smoke cron tests Requests for cpu                                                                                                 | `100m`                                        |
| `smoketestscron.memoryLimits`        | Smoke cron tests Memory limits                                                                                                    | `1024Mi`                                      |
| `smoketestscron.cpuLimits`           | Smoke cron tests CPU limits                                                                                                       | `1000m`                                       |
| `functionaltestscron.enabled`        | Enable functional tests cron job. Runs tests at scheduled times                                                                   | `false`                                       |
| `smoketestscron.schedule`            | Cron expression for scheduling functional tests cron job                                                                          | `30 0/6 * * *`                                |
| `functionaltestscron.image`          | Full functional tests image url.                                                                                                  | `hmctspublic.azurecr.io/spring-boot/template` |
| `functionaltestscron.environment`    | Functional cron tests environment variables. Merged with testsConfig.environment. Overrides duplicates.                           | `nil`                                         |  
| `functionaltestscron.memoryRequests` | Functional cron tests Requests for memory                                                                                         | `256Mi`                                       |
| `functionaltestscron.cpuRequests`    | Functional cron tests Requests for cpu                                                                                            | `100m`                                        |
| `functionaltestscron.memoryLimits`   | Functional cron tests Memory limits                                                                                               | `1024Mi`                                      |
| `functionaltestscron.cpuLimits`      | Functional cron tests CPU limits                                                                                                  | `1000m`                                       |

### Service

Adds a Kubernetes service based on the pod's properties.

## How to test changes

As library charts are not installable, you can use [this script](tests/test-templates.sh) to generate templates and validate your changes.

### Changing existing templates

- You will need to install the UnitTest plugin for Helm:

```shell
helm plugin install https://github.com/helm-unittest/helm-unittest.git
```

- Add the change you want to see in the code and run [the tests](tests/test-templates.sh)
- The snapshot tests will fail and tell you that there are differences. 
- Make sure language specific cases are covered in the tests [see](ci-values-lang.yaml)
- If you are happy with these changes run:
  ``helm unittest -v ci-values.yaml library -u -q -f'tests/snapshot-tests/*.yaml'``
  the -u flag updates the cache.
- Commit your changes to both the cache and the tests

To read about testing your changes in more depth, we have a [written guide](https://hmcts.github.io/ops-runbooks/Testing-Changes/test-chart-library-changes.html)

### Adding new templates
- To support language specific defaults in base charts, all the templates should give precedence to values under `language:` over the default values.
- This can be achieved by using values from below in the templates:
 `{{- $languageValues := deepCopy .Values}}
  {{- if hasKey .Values "language" -}}
  {{- $languageValues = (deepCopy .Values | merge (pluck .Values.language .Values | first) )}}
  {{- end -}}`
- Add the template you expect to  [results](tests/results)
- Add a simple manifest which includes the template in [tests](tests)
- Modify the [script](tests/test-templates.sh) to add to list of manifests being tested
- Run the script and verify the generated templates match.
- Generated manifests can be installed on a cluster if you want to see they are working as expected.
- Make sure language specific cases are covered in the tests [see](ci-values-lang.yaml)
- Once you release the chart , include the new template in applicable base charts [see](https://github.com/hmcts/chart-java/pull/115)

### Bumping template versions

When you make a change to a template file and push it to GitHub in a pull request, an action will run that will run a python script to automatically bump the version of the template you have edited.

For example, if you make changes to `affinity.tpl` the version of the template will be updated from:

```
{{- define "hmcts.affinity.v1" }}
```

to:

```
{{- define "hmcts.affinity.v2" }}
```

The [script](./scripts/bump-tpl.py) will also search for references to the edited template in other files and update them accordingly.

This is needed because if there is an app with dependencies and those dependencies are both pulling chart-library on different versions, then the one downloaded last is used as helm has no native versioning system for the template files besides the naming. This causes multiple conflicts and it's tough to resolve. 

This means we can't be sure which code we are using from which dependency if they were each published in different chart-library versions but under the same template name.

Making sure we bump the template version when editing it helps avoid this problem.

For consuming charts, the pipelines should fail if the library dependency is updated without updating any of the downstream templates which rely on it.

For example, in chart-java:

```
{{- template "hmcts.configmap.v2.tpl" . -}}
```

This version should match the version in chart-library. If the version in chart-library is updated and the library version in chart-java is not updated, the pipeline for chart-java will fail because the version of configmap needs to be updated to v3:

```
{{- template "hmcts.configmap.v3.tpl" . -}}
```

**Note** 

The nature of this action can mean there are cascading increments. If you push to your branch in GitHub and changes are detected in the template files, the versions will be incremented in other files which will, in turn, have their references updated in other files. You will need to run `git pull` to pull the latest changes from GitHub to your local branch.

If changes are made by the action, on the next push, there may be further changes that cause increments. This is unlikely but it is something to be aware of.