# eden-releases governance

This repository is the **public face** of the eden-memory project. It contains releases, documentation, and agent harness skills that are safe to share.

## Scope

Public repo (`yakovkhalinsky/eden-releases`) holds:

- Source code and published packages for the eden-memory public surface.
- Release notes, changelogs, and versioned GitHub releases.
- User-facing documentation, quickstarts, and reference guides.
- Issue and PR templates.
- Agent harness skills, conventions, and MCP tool contracts that are not secret.

Private repo (`yakovkhalinsky/eden-memory`) holds:

- Deployment manifests, Helm charts, and k3s/k8s configuration.
- Network topology, Tailscale names, internal endpoints, and host lists.
- Credentials, API keys, tokens, and any value that can authenticate to a service.
- Fleet Slack workspace details, per-profile Hermes configs, and internal runbooks.
- Production logs or dumps that may contain user data.

## Public/private boundary rules

1. **Never commit secrets.** No keys, tokens, passwords, or certificates in this repo. Even an expired key can leak information.
2. **No deployment topology.** Do not commit hostnames, IP addresses, port mappings, ingress rules, or load balancer details. Use placeholders such as `https://your-eden-instance.example.com` in docs.
3. **No internal comms details.** Fleet Slack workspace IDs, channel names, per-profile app names, and bot tokens stay private.
4. **No production data.** Logs, traces, database dumps, and exported memories that are not synthetic/test data stay private.
5. **No private repo internals.** Do not copy internal implementation files, unredacted CI configs, or deployment scripts into this repo.
6. **Keep harnesses abstract.** Agent harness skills describe interfaces, contracts, and public MCP tools. They do not encode instance URLs or credentials.
7. **Default to private, promote deliberately.** If a file's purpose is unclear, keep it in `eden-memory`. Promote it here only after review.

## Secrets hygiene checklist

Before every commit, run:

```bash
bash scripts/secret-guard.sh
```

This checks for common secret patterns and hardcoded network addresses. If it flags a file, resolve it before opening a PR.

What to look for manually:

- Strings that look like API keys, JWTs, bearer tokens, or base64 secrets.
- Private IP addresses (RFC 1918), Tailscale IPs, or internal DNS names.
- Email addresses or identifiers tied to internal accounts.
- `.env` files, `.pem`, `.key`, or `.p12` files.

## Contribution flow

1. Open an issue using the appropriate template.
2. Propose changes in a PR against `main`.
3. Ensure the secret guard passes and the PR template checklist is complete.
4. A maintainer will review and merge.

## Security reporting

If you believe you have found sensitive data in this public repository, do not open a public issue. Contact the maintainers through the private `eden-memory` repository's security process.
