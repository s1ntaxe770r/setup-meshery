# Setup Meshery Github Action 

An action that Deploys Meshery on Kubernetes using [Kind](https://kind.sigs.k8s.io/) and [Helm](https://helm.sh)


## Usage  

```yaml
name: Install Meshery
on:
  push:
    branches:
      'master'
jobs:
  job1:
    name: Run Performance Test
    runs-on: ubuntu-latest
    steps:
      - name: checkout
        uses: actions/checkout@v2

      - name: Install Meshery
        uses: s1ntaxe770r/setup-meshery@master

     -  name: Verify Install
        run: mesheryctl version 

```


## Todo 
- [ ] Support versioned Installs

- [ ] Deploy Meshery in existing clusters
