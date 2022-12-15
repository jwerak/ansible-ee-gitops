# Deploy Ansible EE pipeline

This is an example of setting up OpenShift Pipeline for building Ansible Execution Environment.

Based on great work from this [blog post](https://cloud.redhat.com/blog/how-to-build-ansible-execution-environments-with-openshift-pipelines).

## Setup

- Get Git repo with [Execution Environment definition](https://github.com/jwerak/ansible-execution-environments)
  - Ideally fork the repo, so that you may push changes to it.
- login to OCP cluster with OpenShift pipelines installed
- create new namespace
  - `oc new-project ansible-ees`
- Create dockerconfig file 
  - either login to container registries you will need based on Execution Environment. In this [EE](https://github.com/jwerak/ansible-execution-environments) we will need registry.redhat.io (to pull base image) and quay.io (to push image to)
    - `podman login registry.redhat.io`
    - `podman login quay.io`
- create [dockerconfig secret](https://docs.openshift.com/container-platform/4.11/openshift_images/managing_images/using-image-pull-secrets.html#images-allow-pods-to-reference-images-from-secure-registries_using-image-pull-secrets) if secrets from podman login are to be used, upload */run/user/1000/containers/auth.json*:

        oc create secret generic pull-and-push \
        --from-file=.dockerconfigjson=/run/user/1000/containers/auth.json \
        --type=kubernetes.io/dockerconfigjson

  - Link secret to pipeline service account
    - `oc secret link pipeline pull-and-push --for=pull,mount`

- Create GitHub webhook secret

        oc create secret generic ansible-ee-trigger-secret \
        --from-literal secretToken=123

- Create secret with contents of ansible.cfg
  - 

Setup Tekton to OCP:

- Create Ansible-Builder task
  - `oc apply -f https://raw.githubusercontent.com/jwerak/catalog/main/task/ansible-builder/0.2/ansible-builder.yaml`
- Apply Pipeline Manifests
  - Edit the Trigger Template *listener/4-trigger-template.yaml* and change the PipelineRun *NAME* parameter to set the image repository name.
  - `oc -n ansible-ees apply -f ../ansible-ee-gitops/listener`

Configure GitHub:

- Get Webhook route url
  - `oc -n ansible-ees get route ansible-ee-el -o jsonpath="{.spec.host}"`
- configure Webhook on GitHub, go to 
  - go to Repo -> Settings -> Webhooks -> Add Webhooks -> Add new882

## Run pipeline

- Go to repo with Execution Environment and push new commit
  - `cd ../ansible-execution-environments/`
  - `git commit --allow-empty -m "Empty commit, trigger the pipeline"`
  - `git push origin main`

## To Solve

- [x] Pass *ansible.cfg* for *automation-hub* to buildah run?
  - [x] Create ansible.cfg as secret
  - [x] Modify ansible-builder task to optionally load ansible.cfg from secret
- [ ] Create complex EE
  - [ ] supported - 
- [ ] Have Git structure to build multiple image kinds
  - [ ] branch based model
  - [ ] configurable from file in repository
  - [ ] images
    - [ ] minimal
    - [ ] supported
    - [ ] full

## Customizations

### Custom ansible.cfg

- Create secret
  - `oc create secret generic custom-ansible-config --from-file=ansible.cfg=./ansible.cfg.local`