# Project A — Live demo runbook

Copy-paste sequence for the live demo. Run from `project-a-cicd-pipeline/` (a git repo, remote
`new-user888/ci-cd-tutorial-sample-app`) unless noted. Assumes infra is currently destroyed —
step 0 redeploys it.

## 0. Deploy the target VM

```sh
cd infra
terraform init
terraform apply -auto-approve
cd ..
```

## 1. Set GitHub repo secrets from Terraform outputs

```sh
terraform -chdir=infra output -raw vm_ssh_key > /tmp/vm_key.pem

gh secret set VM_HOST --body "$(terraform -chdir=infra output -raw vm_host)"
gh secret set VM_USER --body "$(terraform -chdir=infra output -raw vm_user)"
gh secret set VM_PORT --body "$(terraform -chdir=infra output -raw vm_port)"
gh secret set VM_SSH_KEY < /tmp/vm_key.pem
rm /tmp/vm_key.pem
```

`TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` are assumed already set (not infra-dependent).

```sh
gh secret list
```

## 2. CI: push a release-worthy commit

```sh
echo "# demo bump $(date -u)" >> CHANGELOG_NOTE.md
git add CHANGELOG_NOTE.md
git commit -m "feat: demo change to trigger a new release"
git push origin master
```

Watch the run (test -> semantic-release -> build-and-push to GHCR -> Telegram notify):

```sh
gh run watch $(gh run list --workflow=ci.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

Note the new version tag (e.g. `v1.1.0`) from the run output / CHANGELOG.md / Telegram message.

## 3. CD: deploy the new version

```sh
VERSION=v1.1.0   # use the version from step 2
gh workflow run cd.yml -f version=$VERSION
gh run watch $(gh run list --workflow=cd.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

## 4. Verify the deployed version

```sh
VM_HOST=$(terraform -chdir=infra output -raw vm_host)
curl http://$VM_HOST:8000/
# {"status": "ok", "version": "v1.1.0"}
```

## 5. Rollback demo

```sh
gh workflow run cd.yml -f version=v1.0.1
gh run watch $(gh run list --workflow=cd.yml --limit 1 --json databaseId --jq '.[0].databaseId')
curl http://$VM_HOST:8000/
# {"status": "ok", "version": "v1.0.1"} -- rolled back, no rebuild needed
```

## 5b. Auto-rollback on failed deployment (show the mechanism)

`cd.yml` now tracks the last known-good version in `~/.peex-current-version` on the VM. If the
new container fails its health check (`curl -f http://localhost:8000/`), the script automatically
redeploys that previous version before failing the job — no manual rollback step needed.

Show the logic in the workflow file (`.github/workflows/cd.yml`, `deploy_version()` function +
the `if curl -f ...; then ... else ... fi` block).

To force-test end-to-end, push a deliberately broken commit (e.g., make `/` return a 500 or
remove the route), let CI build+push it as a new version, then deploy it:

```sh
gh workflow run cd.yml -f version=v1.2.0-broken
gh run watch $(gh run list --workflow=cd.yml --limit 1 --json databaseId --jq '.[0].databaseId')
```

Run output will show: health check fails on the new version --> script automatically redeploys
the previous version from `~/.peex-current-version` --> re-verifies it --> job still reports
**failure** (so the bad deploy is visible) but the service is already back to a working state by
the time anyone looks.

```sh
curl http://$VM_HOST:8000/
# {"status": "ok", "version": "v1.1.0"} -- already rolled back automatically, before this check
```

## 6. Telegram notifications

Check the Telegram chat for the CI message (step 2) and the two CD messages (steps 3 and 5) —
success/failure, version, actor, and a link to the run.

## 7. Teardown

```sh
cd infra
terraform destroy -auto-approve
cd ..
```
