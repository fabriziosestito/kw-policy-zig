# Kubewarden policy written in Zig

This is a simple [Kubewarden](https://www.kubewarden.io/) policy that acts as an example of how to write a policy in Zig.
The policy looks at the name of a Kubernetes Pod and rejects the request if the name is on a deny list.

A major inspiration was taken from [this tutorial](https://docs.kubewarden.io/writing-policies/rust/create-policy).

Since Zig uses LLVM, the wasm32 target architecture is officially supported.
This project uses an updated fork of the [waPC Guest Library for Zig](https://github.com/fabriziosestito/wapc-guest-zig).

# Usage

## Settings

Settings containing a list of invalid names are required.

```json
{ "invalid_names": ["bad-name", "another-bad-name"] }
```

## Example

Create a policy:

```bash
$ kubectl apply -f - <<EOF
---
apiVersion: policies.kubewarden.io/v1
kind: ClusterAdmissionPolicy
metadata:
  name: kw-policy-zig
spec:
  module: registry://ghcr.io/fabriziosestito/kw-policy-zig:v0.1.0
  settings:
    invalid_names:
      - bad-name
      - another-bad-name
  rules:
    - apiGroups:
        - ""
      apiVersions:
        - v1
      resources:
        - pods
      operations:
        - CREATE
        - UPDATE
  mutating: false
EOF
```

Create a Pod with a valid name:

```
$ kubectl apply -f examples/pod.yaml
pod/nginx created
```

Create a Pod with an invalid name:

```
$ kubectl apply -f examples/bad_pod.yaml
Error from server: error when creating "examples/bad_pod.yaml": admission webhook "clusterwide-kw-policy-zig
.kubewarden.admission" denied the request: Pod name: bad-name is not accepted.
```

# Bulding

This project is built using Zig [0.10.1](https://ziglang.org/download/#release-0.10.1).

Zig is still young, so expect the build to break when newer versions are released.

[kwctl](https://github.com/kubewarden/kwctl) is required to annotate and push the policy to a registry.

Since Zig doesn't have an official package manager, dependencies are provided as git submodules.

Clone the project:

```
git clone git@github.com:fabriziosestito/kw-policy-zig
cd kw-policy-zig
git submodule update --init --recursive
```

Build the policy:

```
make
```

Annotate the policy:

```
make annotated-policy.wasm
```

Push the policy to a registry:

```
kwctl push annotated-policy.wasm ghcr.io/fabriziosestito/kw-policy-zig:v0.1.0
```

# Testing

Run tests:

```
make test
```

Install [bats-core](https://github.com/bats-core/bats-core) to run end-to-end tests.

Run E2E tests:

```
make e2e-tests
```
