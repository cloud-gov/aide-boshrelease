# AIDE bosrelease

A boshrelease for the Advanced Intrusion Detection Environment

## Using it

This release is made with the following assumptions:

- you're using the [node_exporter](https://github.com/bosh-prometheus/node-exporter-boshrelease) bosh release to export stats to prometheus
- node_exporter is loading /var/vcap/data/node_exporer/config/.&ast;.prom

The release will schedule AIDE to check and report hourly, by dropping a file into `/etc/cron.hourly`.

Extra rules can be applied via the `aide_rules` property, which should be just raw text rules:

```yaml
aide_rules: |
  /path/to/tacos R # don't mess with my tacos
  !/something/i/do/not/care/about

```

## What it does

Pre-start scripts ensure the AIDE db has been initialized.
Post-start scripts update the database, accepting all changes.
run-report.sh runs aide --check and exports the results to prometheus


