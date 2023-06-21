⚠️ As of 2023-06-21 this repository has been archived and is no longer maintained by the Pay team.

# pay_pr_flow_stats

This is a CLI utility we use on Pay to extract and record a variety of information regarding pull requests raised related to Pay and their build times on Concourse.

The concourse components of this can be found here: 

https://github.com/alphagov/pay-omnibus/blob/master/ci/pipelines/pr.yml#L81

## Containerisation

In our CI environment we run this inside a container, this is fetchable from Dockerhub with:

`docker pull govukpay/pay-pr-flow-stats`

We manually push new builds of the image which we have determined have significant enough changes for the container to need an update.

# Usage

If you run `./bin/flow_check` it will check all the PRs raised against https://github.com/alphagov/pay-connector and output relevant information about the pull request's build time.

## Specifying PRs

You can target the script against a specific PR or Repository with

`--repo $org_name/$repo_name --pr $pr_number`

## Filtering Manually Retriggered PRs

When a pull request is manually retriggered, some of the context of the intial pull request is destroyed, we can no longer entirely reconstruct the times at which certain actions relating to the build process occurred.

We avoid this by adding a flag to the execution of flow check

`--filter-manually-triggered`

## Quiet Output

The default output mode is relatively noisy, when we run this script inside a CI environment we want to limit this as we are largely interested with just certain metric values.

This is done by adding a quiet flag: 

`--quiet`

## Sending Metrics to Hosted Graphite

If a user wishes to record the metrics gathered by this script in hosted graphite they can do so by setting the correct environment variables:

`HOSTED_GRAPHITE_ACCOUNT_ID`

`HOSTED_GRAPHITE_API_TOKEN`

Then they should pass in the flag:

`--send-to-hg`
