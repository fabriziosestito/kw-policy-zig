#!/usr/bin/env bats

@test "settings not specified" {
  run kwctl run annotated-policy.wasm -r test_data/pod.json 

  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request rejected
  [ "$status" -eq 1 ]
  [ $(expr "$output" : '.*valid.*false*') -ne 0 ]
  [ $(expr "$output" : '.*MissingField.*') -ne 0 ]
}

@test "settings not valid" {
  run kwctl run annotated-policy.wasm -r test_data/pod.json  --settings-json '{"invalid_names": []}'

  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request rejected
  [ "$status" -eq 1 ]
  [ $(expr "$output" : '.*valid.*false*') -ne 0 ]
  [ $(expr "$output" : '.*No invalid name specified.*') -ne 0 ]
}

@test "accept pod name" {
  run kwctl run annotated-policy.wasm -r test_data/pod.json --settings-json '{"invalid_names": ["bad-name"]}' 

  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request rejected
  [ "$status" -eq 0 ]
  [ $(expr "$output" : '.*allowed.*true*') -ne 0 ]
}

@test "reject pod name" {
  run kwctl run annotated-policy.wasm -r test_data/pod_bad_name.json --settings-json '{"invalid_names": ["bad-name"]}' 

  # this prints the output when one the checks below fails
  echo "output = ${output}"

  # request rejected
  [ "$status" -eq 0 ]
  [ $(expr "$output" : '.*allowed.*false*') -ne 0 ]
  [ $(expr "$output" : '.*Pod name: bad-name is not accepted.*') -ne 0 ]
}
