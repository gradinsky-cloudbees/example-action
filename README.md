# This is an example custom action for the CloudBees Platform

Custom actions in platform rely on building an executable that takes CLI arguments, packaging it with a Dockerfile, and using that in the action.yaml

This example uses GO with Cobra for CLI input, Dockerfile for when being built by the platform, and Makefile for testing/publishing new versions. The action.yaml defines what the custom action does when utilized in a workflow. Additionally, you will need a public ECR to store the images. Creating custom actions with code can be done with your preferred language.



### Needed items

* A public AWS ECR to store the images to be used by the action
* A public Github repository (at the time of writing this private custom actions were not supported)
* Create a job in the platform to build the custom action/publish to AWS ECR

### Init

The [root.go](./cmd/root.go) inside of the cmd package is the command line interface along with being responsible for writing job output to the file that the platform uses as output params. This will also initialize the config with all the input parameters.
Output Parameters
Any job that needs to write an output file needs to write to the environment variable CLOUDBEES_OUTPUTS/nameHere and specified in the actions.yaml

#### Example writing a string (bodyString) to the output file called "response". 
````go
os.WriteFile(filepath.Join(os.Getenv("CLOUDBEES_OUTPUTS"), "response"), []byte(bodyString), 0666)
````



#### Example from [action.yaml](action.yaml) to set a usable output parameter:
````yaml
outputs:
  response:
    value: ${{ steps.rest.outputs.response }}
    description: 'The JSON response from the API request'
````


### Action
The action.yaml defines the inputs, outputs, and what is run by the custom action when executed. Note that both the CLI run and the action definition are in the same project. Because this is a GO based action it will download the image built from the Dockerfile and defined in [my-workflow.yaml](.cloudbees/workflows/my-workflow.yaml).


