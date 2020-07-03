# chart-library
Library Helm Chart

## How to test changes

As library charts are not installable, you can use [this script](tests/test-templates.sh) to generate templates and validate your changes.

### Changing existing templates
 - Add the change you want to see in [results](tests/results/) 
 - Run the [script](tests/test-templates.sh) to see if the generated templates match.
 - Generated manifests can be installed on a cluster if you want to see they are working as expected.

### Adding new templates
- Add the template you expect to  [results](tests/results)
- Add a simple manifest which includes the template in [tests](tests)
- Modify the [script](tests/test-templates.sh) to add to list of manifests being tested
- Run the script and verify the generated templates match.
- Generated manifests can be installed on a cluster if you want to see they are working as expected.