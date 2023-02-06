# chart-library
Library Helm Chart

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

| Parameter                  | Description                                | 
| -------------------------- | ------------------------------------------ |
| `releaseNameOverride`          | Will override the default resource name - It supports templating, example:`releaseNameOverride: {{ .Release.Name }}-my-custom-name`      |
| `releaseNamePrefix`          | Prefix for the release name |
| `.global.releaseNamePrefix`          | Global Prefix for the release name |
| `releaseNameSuffix`          | Suffix for the release name |
| `.global.releaseNameSuffix`          | Global Suffix for the release name |

The applied order is: `global prefix + prefix + name + suffix + global suffix`

### Deployment


| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `replicas`          | Number of pod replicas |

It includes below templates :

- [PodTemplate spec](#PodTemplate)

### PodTemplate

| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `saEnabled`          | Flag to Enable Service Account |
| `useInterpodAntiAffinity` | Always schedule replicas on different nodes | 

It includes below templates :
- [Metadata](#Metadata)
- [DNS Config](#DNS-Config)
- [Container](#Container)

### Metadata

| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `aadIdentityName`          | Added as a label for binding pod identity |
| `prometheus.enabled`          | Enables adding prometheus annotations |
| `prometheus.path`          | Path for scraping prometheus metrics |

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
| Parameter                  | Description                                |
| -------------------------- | ------------------------------------------ |
| `disableKeyVaults`         | Disables key vault support, useful in pull requests if you don't need any secrets (usually because you're using an embedded DB) |
| `keyVaults`                | Mappings of keyvaults to be mounted as CSI Volumes (see Example Configuration) | 
| `aadIdentityName`          | Pod identity binding for accessing the key vaults  |
| `mountPath`                | (Optional) Custom path to mount the secrets to the pod. Default: `/mnt/secrets/<VAULT_NAME>`  |

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

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `ingressHost`              | Host for ingress controller to map the container to. It supports templating, Example : {{.Release.Name}}.service.core-compute-preview.internal   | `nil`|
| `registerAdditionalDns.enabled`            | If you want to use this chart as a secondary dependency - e.g. providing a frontend to a backend, and the backend is using primary ingressHost DNS mapping.                            | `false`      
| `registerAdditionalDns.primaryIngressHost`            | The hostname for primary chart. It supports templating, Example : {{.Release.Name}}.service.core-compute-preview.internal                           | `nil`      
| `registerAdditionalDns.prefix`            | DNS prefix for this chart - will resolve as: `prefix-{registerAdditionalDns.primaryIngressHost}`                         | `nil`     
| `disableTraefikTls`            | Boolean value to enable or disable TLS on application specific HTTP router created on Traefik ingress controller. This will usually be set by Jenkins through global which takes precedence over app settings.                           | `false`
| `enableOAuth`            | Boolean value to enable or disable OAuth2 proxy. Setting to `true` will force signing into Azure AD when navigating to application frontend            | `false`
| `additionalIngressHosts`            | List of string values for additional ingress hosts. For example ["one.domain.com", "two.domain.com"]            | `nil`

### Pod Disruption Budget

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `pdb.enabled` | To enable PodDisruptionBudget on the pods for handling disruptions | `true` |
| `pdb.maxUnavailable` |  To configure the number of pods from the set that can be unavailable after the eviction. It can be either an absolute number or a percentage. pdb.minAvailable takes precedence over this if not nil | `50%` means evictions are allowed as long as no more than 50% of the desired replicas are unhealthy. It will allow disruption if you have only 1 replica.|
| `pdb.minAvailable` |  To configure the number of pods from that set that must still be available after the eviction, even in the absence of the evicted pod. minAvailable can be either an absolute number or a percentage. This takes precedence over pdb.maxUnavailable if not nil. | `nil`|

### Kubernetes Secrets as Environment Variables

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `secrets`                  | Mappings of environment variables to service objects or pre-configured kubernetes secrets |  nil |

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

| Parameter                               | Description                                                | Default |
|-----------------------------------------|------------------------------------------------------------|---------|
| `autoscaling.enabled`                   | Enable horizontal pod autoscaling.                         | `false` |
| `autoscaling.maxReplicas`               | Max replica count. Required if autoscaling.enabled is true | ``      |
| `autoscaling.cpu.enabled`               | Enable CPU based Autoscaling                               | `true`  |
| `autoscaling.cpu.averageUtilization`    | Average CPU utilization                                    | `80`    |
| `autoscaling.memory.enabled`            | Enable Memory based Autoscaling                            | `true`  |
| `autoscaling.memory.averageUtilization` | Average memory utilization                                 | `80`    |


Example Config:

```yaml
autoscaling:        
  enabled: true     # Default is false
  maxReplicas: 5    # Required setting
  cpu:
    averageUtilization: 80 # Default is 80% Average CPU utilization 
  memory:
    averageUtilization: 80 # Default is 80% Average memory utilization  
```

### Smoke and functional tests

| Parameter                  | Description                                | Default  |
| -------------------------- | ------------------------------------------ | ----- |
| `testsConfig.keyVaults`      | Tests keyvaults config [here](#example-for-adding-azure-key-vault-secrets-using-aliases). Shared by all tests pods  | `nil` |
| `testsConfig.environment`    | Tests environment variables. Shared by all tests pods. Merged, with duplicate variables overridden, by specific tests environment  | `nil` |
| `testsConfig.memoryRequests` | Tests Requests for memory. Applies to all test pods. Can be overridden by single test pods | `256Mi`|
| `testsConfig.cpuRequests`    | Tests Requests for cpu. Applies to all test pods. Can be overridden by single test pods | `100m`|
| `testsConfig.memoryLimits`   | Tests Memory limits. Applies to all test pods. Can be overridden by single test pods | `1024Mi`|
| `testsConfig.cpuLimits`      | Tests CPU limits. Applies to all test pods. Can be overridden by single test pods | `1000m`|
| `smoketests.enabled`         | Enable smoke tests single run after deployment. | `false` |
| `smoketests.image`           | Full smoke tests image url. | `hmctspublic.azurecr.io/spring-boot/template` |
| `smoketests.environment`     | Smoke tests environment variables. Merged with testsConfig.environment. Overrides duplicates. | `nil` |  
| `smoketests.memoryRequests`  | Smoke tests Requests for memory | `256Mi`|
| `smoketests.cpuRequests`     | Smoke tests Requests for cpu | `100m`|
| `smoketests.memoryLimits`    | Smoke tests Memory limits | `1024Mi`|
| `smoketests.cpuLimits`       | Smoke tests CPU limits | `1000m`|
| `functionaltests.enabled`         | Enable functional tests single run after deployment. | `false` |
| `functionaltests.image`           | Full functional tests image url. | `hmctspublic.azurecr.io/spring-boot/template` |
| `functionaltests.environment`     | Functional tests environment variables. Merged with testsConfig.environment. Overrides duplicates. | `nil` |  
| `functionaltests.memoryRequests`  | Functional tests Requests for memory | `256Mi`|
| `functionaltests.cpuRequests`     | Functional tests Requests for cpu | `100m`|
| `functionaltests.memoryLimits`    | Functional tests Memory limits | `1024Mi`|
| `functionaltests.cpuLimits`       | Functional tests CPU limits | `1000m`|
| `smoketestscron.enabled`         | Enable smoke tests cron job. Runs tests at scheduled times | `false` |
| `smoketestscron.schedule`         | Cron expression for scheduling smoke tests cron job | `20 0/1 * * *` |
| `smoketestscron.image`           | Full cron smoke tests image url. | `hmctspublic.azurecr.io/spring-boot/template` |
| `smoketestscron.environment`     | Smoke cron tests environment variables. Merged with testsConfig.environment. Overrides duplicates. | `nil` |  
| `smoketestscron.memoryRequests`  | Smoke cron tests Requests for memory | `256Mi`|
| `smoketestscron.cpuRequests`     | Smoke cron tests Requests for cpu | `100m`|
| `smoketestscron.memoryLimits`    | Smoke cron tests Memory limits | `1024Mi`|
| `smoketestscron.cpuLimits`       | Smoke cron tests CPU limits | `1000m`|
| `functionaltestscron.enabled`         | Enable functional tests cron job. Runs tests at scheduled times | `false` |
| `smoketestscron.schedule`             | Cron expression for scheduling functional tests cron job | `30 0/6 * * *` |
| `functionaltestscron.image`           | Full functional tests image url. | `hmctspublic.azurecr.io/spring-boot/template` |
| `functionaltestscron.environment`     | Functional cron tests environment variables. Merged with testsConfig.environment. Overrides duplicates. | `nil` |  
| `functionaltestscron.memoryRequests`  | Functional cron tests Requests for memory | `256Mi`|
| `functionaltestscron.cpuRequests`     | Functional cron tests Requests for cpu | `100m`|
| `functionaltestscron.memoryLimits`    | Functional cron tests Memory limits | `1024Mi`|
| `functionaltestscron.cpuLimits`       | Functional cron tests CPU limits | `1000m`|

### Service

Adds a Kubernetes service based on the pod's properties.

## How to test changes

As library charts are not installable, you can use [this script](tests/test-templates.sh) to generate templates and validate your changes.

### Changing existing templates
 - Add the change you want to see in [results](tests/results/) 
 - Run the [script](tests/test-templates.sh) to see if the generated templates match.
 - Generated manifests can be installed on a cluster if you want to see they are working as expected.
 - Make sure language specific cases are covered in the tests [see](ci-values-lang.yaml) 

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
