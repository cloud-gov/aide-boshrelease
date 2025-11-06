# AIDE bosrelease

A boshrelease for the Advanced Intrusion Detection Environment

## Using it

This release is made with the following assumptions:

- you're using the [node_exporter](https://github.com/bosh-prometheus/node-exporter-boshrelease) bosh release to export stats to prometheus
- node_exporter is loading /var/vcap/data/node_exporer/config/.&ast;.prom

The release will schedule AIDE to check and report hourly, by dropping a file into `/etc/cron.hourly`.

Extra rules can be applied via the `append_rules` property, which should be just raw text rules:

```yaml
append_rules: |
  /path/to/tacos R # don't mess with my tacos

```
Extra ignore rules can be applied via the `prepend_rules` property, which should be just raw text rules - if you're ignoring a sub file/directory either in a default rule or under an above `append_rules` place your ignore syntax here:

```yaml
prepend_rules: |
  !/something/i/do/not/care/about

```

## What it does

 - `pre-start` script ensures the AIDE db has been initialized.
 - `post-deploy` script updates the database calling `update-aide-db`, accepting all changes and schedules a cron job to hourly run aide checks.
 - `run-report` runs aide --check, calling functions in `lock-functions` and `calculate-changes`,  and exports the results to prometheus

## Running tests

There are a subset of files and conditions which are ignored when an `aide --check` command is executed because of `bosh ssh`.  Details on this are located at https://github.com/cloud-gov/internal-docs/blob/main/docs/runbooks/Platform/aide.md#adding-files-to-be-ignored---alerting-only

To test the function which calculates the number of changes, execute the file `jobs/aide/templates/bin/test-calculate-changes.sh` which should be located in the same folder is `calculate-changes`.  The output should be similar to:

```bash
./test-calculate-changes
Running calculate_changes tests...
======================================
=== Testing scenario: scenario1_bosh_changes_only ===
✓ PASS: Scenario 1: bosh_ changes only - Result: 0 (expected: 0)

=== Testing scenario: scenario2_non_bosh_changes ===
✓ PASS: Scenario 2: non-bosh changes - Result: 1 (expected: 1)

=== Testing scenario: scenario3_outside_allowed_list ===
✓ PASS: Scenario 3: files outside allowed list - Result: 3 (expected: 3)

=== Testing scenario: scenario4_zero_changes ===
✓ PASS: Scenario 4: zero changes - Result: 0 (expected: 0)

=== Testing scenario: scenario5_invalid_report ===
✓ PASS: Scenario 5: invalid report format - Result: 0 (expected: 0)

=== Testing scenario: scenario6_mixed_changes ===
✓ PASS: Scenario 6: mixed bosh_ and non-bosh_ changes - Result: 1 (expected: 1)

======================================
         TEST SUMMARY
======================================
Total tests:  6
Passed:       6
Failed:       0

All tests passed!
```