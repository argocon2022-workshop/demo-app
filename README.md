# Demo Appication

Demo application is a simple Golang application that is used to demostrate how to integrate Argo CD driven GitOps process and CI.

## Preparation

Please execute the following steps:
* [Fork](https://github.com/argocon2022-workshop/demo-app/fork) the repository.
* [Create](https://github.com/settings/tokens/new) personal access token (PAT) with repository and packages write access.
  Yes, personal access token is less safe but we are going to use it during the workshop for simplicity.

```
    Don't forget to select `repo` and `write:packages` scopes:

    ☑ repo Full control of private repositories
      ☑ repo:status Access commit status
      ☑ repo_deployment Access deployment status
      ☑ public_repo Access public repositories
      ☑ repo:invite Access repository invitations
      ☑ security_events Read and write security events
    ☐ workflow Update GitHub Action workflows
    ☑ write:packages Upload packages to GitHub Package Registry
      ☑ read:packages Download packages from GitHub Package Registry
```
* Add PAT to the repository secrets as `DEPLOY_PAT`:
    * Navigate to `https://github.com/<USERNAME>/demo-app/settings/secrets/actions`
    * Click `New repository secret`
    * Add `DEPLOY_PAT` as a name and paste PAT as a value
* Enable Github Actions for the repository:
    * Navigate to `https://github.com/<USERNAME>/demo-app/settings/secrets/actions`
    * Click `Enable local and third party Actions for this repository`


## Build An Image

In order, to deploy an application using Argo CD we need to produce a container image. It would be too boring if everyone deploy the same image, so you are going to build your own.
We are going to leverage CI to build an image and push it to the GitHub Container Registry. The Github Actions workflow is already defined in the repository, so you just need to
make a small change to trigger the workflow.

Please go ahead and edit the `main.go` file and replace the `USERNAME` placeholder with your github name:

```go
    package main

    import (
        "time"

        "github.com/common-nighthawk/go-figure"
    )

    func main() {
        myFigure := figure.NewColorFigure("<USERNAME> is Awesome!!!", "larry3d", "yellow", true)
        myFigure.Print()
        time.Sleep(10 * time.Hour)
    }
```

Push the changes and wait for the workflow to complete. The image is avaiable at `ghcr.io/<USERNAME>/demo-app:<sha>`.

## Getting Ready To Deploy The Application

The image is ready, but we need to create a Kubernetes manifest that will be used to deploy the application. The simplest thing we can do is to just prepare a YAML file with a Deployment and a Service.
That however is not going to scale well in real life, and we need to leverage a config management tool. We are going to use [Kustomize](https://kustomize.io/) to define application the manifests.
Please navigate to https://github.com/argocon2022-workshop/demo-app-deploy to continue.

## Automating Image Updates

No one likes to make trivial tag image changes manually. In order to make the process more efficient we are going to automate
changes in dev environment using Github Actions. Add the following snipped to the `.github/workflows/ci.yaml` file:

```yaml
  deploy-dev:
    runs-on: ubuntu-latest
    needs: build-image
    steps:
    - uses: imranismail/setup-kustomize@v1

    - name: Kustomize
      run: |
        git config --global user.name "Deploy Bot"
        git config --global user.email "no-reply@akuity.io"
        git clone https://bot:${{ secrets.DEPLOY_PAT }}@github.com/${{ github.repository_owner }}/demo-app-deploy.git
        cd demo-app-deploy/env/dev
        kustomize edit set image ghcr.io/argocon2022-workshop/demo-app=ghcr.io/${{ github.repository_owner }}/demo-app:${{ github.sha }}
        git commit -a -m "Deploy dev: ghcr.io/${{ github.repository_owner }}/demo-app:${{ github.sha }}"
        git notes append -m "image: ghcr.io/${{ github.repository_owner }}/demo-app:${{ github.sha }}"
        git push origin "refs/notes/*" --force && git push --force
```

Once changes are pushed that CI will build a new image and update the `dev` environment with the correspinding image tag. Developers no longer
need to manually change deployment manifests to update the dev environment. Upgrade of staging and production deployment usually requires
more carefull process but also can be automated. Lets switch [back](https://github.com/argocon2022-workshop/demo-app-deploy#automating-staging-and-production-environments)
to depoyment repository and automate the staging and production environments changes.