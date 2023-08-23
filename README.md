# k8s-dtap-blue-green

## Overview

This repo contains various ways to deploy [DTAP](https://en.wikipedia.org/wiki/Development,_testing,_acceptance_and_production) environments with [Blue Green](https://en.wikipedia.org/wiki/Blue%E2%80%93green_deployment) deployments to [Kubernetes](https://en.wikipedia.org/wiki/Kubernetes).

## DTAP

Acronym for development,testing,acceptance,production environments often referred to as dev,test,stage,prod.

Changes are progressed through each DTAP environment with some form of change control.

## Blue Green 

A method of deploying changes to a system by swapping the active deployment. If we deploy v1 to Blue, we then deploy v2 to Green, with users accessing a common endpoint which routes traffic to either Blue or Green. In case of an issue with v2 we can redirect users from Green back to Blue.

## [Terraform](https://en.wikipedia.org/wiki/Terraform_(software))

Terraform is Infrastrcture as Code [IaC](https://en.wikipedia.org/wiki/Infrastructure_as_code) software which uses providers to configure various backends.

See the READ.md in the tf directory.
