# chart-library
Library Helm Chart

Note: `We still support v1 templates only till we test and rollout v2 templates`

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
 `{{- $languageValues := (deepCopy .Values | merge (pluck .Values.language .Values | first) ) }}`
- Add the template you expect to  [results](tests/results)
- Add a simple manifest which includes the template in [tests](tests)
- Modify the [script](tests/test-templates.sh) to add to list of manifests being tested
- Run the script and verify the generated templates match.
- Generated manifests can be installed on a cluster if you want to see they are working as expected.
- Make sure language specific cases are covered in the tests [see](ci-values-lang.yaml)

### Limitations
 - Currently, if we set boolean properties to true by default, we are not able to override to false in language specific values. 
