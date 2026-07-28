# Python-Era Eden-Memory Skills Audit

**Date:** 2026-07-28  
**Auditor:** Abel (Hermes agent)  
**Scope:** `/home/yakov/.hermes/profiles/adam/skills/` — six named Python-era `eden-memory` skills plus the `agent-harness` packaging target.  
**Target repo:** `/home/yakov/eden-releases` (`https://github.com/yakovkhalinsky/eden-releases`)  
**Constraint:** No modification of `yakovkhalinsky/eden-memory` or the active skill library without explicit permission.

---

## Executive Summary

All six requested Python-era skills **still exist** in the active Adam profile. They are not missing, but they are all **at risk of semantic drift** because they are heavily bound to the private `yakovkhalinsky/eden-memory` Python implementation, while the public `eden-releases` repo is currently only a skeleton (README + LICENSE). The most urgent revival candidates are the sync and pairing skills: they contain hard-won, transferable correctness knowledge (LWW convergence, PAKE pairing, relay envelope signing, watermark/ack ordering) that would be expensive to rediscover. The coordination skill is valuable but too large and Adam-specific to drop unchanged into a generic `agent-harness` skills package.

---

## Skill Inventory

### 1. `eden-memory-concurrency`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-concurrency/`
- **Status:** **At risk / needs updating**
- **What it covers:** SQLite single-writer discipline, filelock + RLock ordering, async write queue, WAL settings, MCP graceful shutdown, plus Go-rewrite concurrency surfaces.
- **Findings:**
  - SKILL.md is well-structured and references are present (`priority7-implementation-notes.md`, `mcp-graceful-shutdown.md`, `uuidv7-test-migration.md`).
  - Half the body is now about a Go rewrite (`internal/mcp/server.go`, `internal/embedder/worker.go`, etc.). If the public `eden-releases` package is Python-only, the Go sections should be split into `eden-memory-go-store` or left behind.
  - Verification recipes assume `/home/yakov/eden-memory` and a local `.venv`; these paths will not exist for a generic agent-harness consumer.
  - The `ConcurrencyError`, `queue_*` API, and WAL advice remain transferable.
- **Recommended action:**
  - Extract Go-specific content into `eden-memory-go-store`.
  - Replace absolute `/home/yakov/eden-memory` paths with repo-relative placeholders.
  - Keep as a **narrow, focused skill** for SQLite concurrency in `eden-memory`.
- **Include in `agent-harness` package?** **Yes, after split and refresh.**

---

### 2. `eden-memory-schema-migrations`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-schema-migrations/`
- **Status:** **At risk / needs updating**
- **What it covers:** SQLite `_USER_VERSION`, `_MIGRATIONS`, clean-baseline vs table-rebuild, v6 UUIDv7 primary-key migration, v8 identity scoping, tombstone foreign-key ordering.
- **Findings:**
  - References are present and specific: TTL migration debug, v6 clean baseline, v8 identity scoping, tombstone forget implementation.
  - The skill couples tightly to `src/eden_memory/store.py` and `_MIGRATIONS` dict layout.
  - v8 identity scoping advice is still fresh and relevant (2026-07-26 reference).
  - Verification recipes again hard-code `/home/yakov/eden-memory`.
- **Recommended action:**
  - Generalize code snippets from concrete module paths to generic guidance.
  - Keep the v6/v8 migration decision matrix; it is reusable for any SQLite-backed local-first memory store.
  - Add a note that migration strategy must match the canonical repo's compatibility charter.
- **Include in `agent-harness` package?** **Yes, as a narrow SQLite-migration skill.**

---

### 3. `eden-memory-sync-verification`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-sync-verification/`
- **Status:** **Needs revival / high value**
- **What it covers:** Sync compatibility gate, `apply_delta` merge logic, `TwoDeviceHarness`, LWW convergence, tombstone/delete/delete convergence, transport-client gap audit, quota/subscription wiring, Ed25519/X25519 envelope auth.
- **Findings:**
  - This is the **densest correctness skill** in the set. It contains dozens of specific pitfalls (per-memory Lamport clocks, re-embed path, peer replay windows, watermark/ack ordering, PyNaCl Ed25519→X25519 conversion, signature timestamp mismatch, etc.).
  - Strong reference set: P4/P7 implementation notes, transport gap audit, P9 sync status polish, identity scoping checklist, subscription enforcement notes.
  - Heavily references `store.py`, `sync_client.py`, `sync_transport.py`, `relay_server.py`, and private `eden-memory` test modules.
  - The first numbered workflow step is misnumbered (two step-3s) — cosmetic but should be fixed.
- **Recommended action:**
  - Revive as a priority. The transport/envelope/auth knowledge is broadly applicable beyond the old Python repo.
  - Refactor body into sub-sections: compatibility gate, merge logic, harness, transport gap, quota.
  - Replace concrete file paths with module-relative names.
  - Fix numbering.
- **Include in `agent-harness` package?** **Yes — one of the strongest candidates.**

---

### 4. `eden-memory-sync-integration`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-sync-integration/`
- **Status:** **Needs revival / high value, high test-path dependency**
- **What it covers:** End-to-end fleet sync integration testing through the `eden-relay` HTTP server: ephemeral relay subprocess, pairing, convergence, right-to-forget, pricing-unit counters, CI-portable fixtures.
- **Findings:**
  - Excellent operational detail: relay subprocess startup race, signature timestamp mismatch over HTTP, revoked device behavior, account sync key mismatch, allow-empty signature trap, CI fixture portability.
  - Tightly coupled to `tests/test_sync_integration.py`, `tests/test_sync_pairing_network.py`, `packages/eden-relay`, `.venv` paths, and the private repo's package layout.
  - References are rich but use absolute station paths.
- **Recommended action:**
  - Extract the integration-test patterns into a standalone recipe that does not require the old monorepo layout.
  - Decide whether `eden-relay` remains in scope for `eden-releases`; if not, archive or split relay-specific content into a separate `eden-relay` skill.
  - Keep the right-to-forget and pricing-unit counter guidance if those features carry forward.
- **Include in `agent-harness` package?** **Yes, but only after decoupling from the private monorepo paths and clarifying relay scope.**

---

### 5. `eden-memory-pairing-and-root-key`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-pairing-and-root-key/`
- **Status:** **Needs revival / high value**
- **What it covers:** Root key derivation (HKDF), deterministic Ed25519/X25519 device keys, encrypted sidecar, PAKE/SPAKE2 pairing, pairing UX state machine, local-only default, manual pairing fallback, mnemonic backup.
- **Findings:**
  - Strong, transferable guidance: never store root key in SQLite, deterministic key derivation, passphrase handling, local-only default.
  - Contains precise pitfalls (root seed threading through `register_device`, `sync_peers` column additions, `.get()` on `sqlite3.Row`, in-memory pairing manager state across CLI invocations).
  - Reference set is complete and recent (2026-07-25).
  - UX state machine and QR placeholder guidance are broadly useful for any local-first pairing flow.
- **Recommended action:**
  - Refresh path references from `/home/yakov/eden-memory/...` to generic module names.
  - Keep the SPAKE2 and PAKE sections; they are implementation-agnostic.
  - Clarify which parts are Python-specific (`cryptography`, `spake2`, `pynacl`) vs general design.
- **Include in `agent-harness` package?** **Yes — strong candidate, but split general design from Python library specifics.**

---

### 6. `eden-memory-coordination`

- **Location:** `/home/yakov/.hermes/profiles/adam/skills/software-development/eden-memory-coordination/`
- **Status:** **At risk / not suitable for generic package as-is**
- **What it covers:** Adam fleet coordination for the eden-memory runtime: sibling task scoping, green-baseline rule, spike gate assessment, safety gate pattern, backlog management, options briefs, pre-implementation audits.
- **Findings:**
  - This is a **meta/coordination skill** for Adam, not an implementation skill. It is large (517 lines), references many fleet-specific memories and retired spikes, and presumes the private `eden-memory` repo structure.
  - Contains reusable patterns (options brief, safety audit, spike gate template, acceptance criteria) that could be generalized.
  - Most operational detail (ONNX spike, GoatDB, cr-sqlite, vector backend selection, identity scoping defaults) is highly specific to the July 2026 Python/Go prototyping period.
- **Recommended action:**
  - Do **not** include wholesale.
  - Extract reusable governance patterns into a smaller skill (e.g., `spike-gate-assessment`, `pre-implementation-safety-audit`) if those do not already exist.
  - Retire or archive the eden-memory-specific coordination content; link to it from `eden-releases` docs rather than shipping it as an active skill.
- **Include in `agent-harness` package?** **No, not as-is.** Extract generic patterns only.

---

## Agent-Harness Packaging Target

- **Current state in `eden-releases`:** only `README.md`, `LICENSE`, `.gitignore`, and `.git` metadata.
- **There is no existing `agent-harness/skills/` directory or package manifest.**
- **Recommended `agent-harness` skills package structure:**

```text
eden-releases/
  agent-harness/
    skills/
      eden-memory-concurrency/
        SKILL.md
        references/
      eden-memory-schema-migrations/
        SKILL.md
        references/
      eden-memory-sync-verification/
        SKILL.md
        references/
      eden-memory-sync-integration/
        SKILL.md
        references/
      eden-memory-pairing-and-root-key/
        SKILL.md
        references/
    README.md
```

- **Should `eden-memory-coordination` go in?** No — archive its reusable patterns separately.

---

## Summary Table

| Skill | Status | Needs updating | Include in `agent-harness` package |
|---|---|---|---|
| `eden-memory-concurrency` | At risk | Split Go content; replace absolute paths | Yes, after refresh |
| `eden-memory-schema-migrations` | At risk | Generalize from `store.py` specifics | Yes |
| `eden-memory-sync-verification` | Needs revival | Refactor sections; fix numbering; de-path | Yes — priority |
| `eden-memory-sync-integration` | Needs revival | Decouple from monorepo/relay paths | Yes, after scope clarify |
| `eden-memory-pairing-and-root-key` | Needs revival | Separate general design from Python libs | Yes — priority |
| `eden-memory-coordination` | At risk / Adam-specific | Extract generic patterns only | No (as-is) |

---

## Key Findings

1. **Nothing is missing.** All six requested skills are present with rich reference directories.
2. **Python-era skills are not dead, but they are coupled to a private repo.** Every skill references `src/eden_memory/...`, `/home/yakov/eden-memory`, or the `eden-memory` Python package layout.
3. **Sync and pairing skills are the highest-value revival targets.** They encode hard-won distributed-systems correctness knowledge (LWW, PAKE, envelope auth, watermark/ack ordering) that is expensive to recreate.
4. **The coordination skill is the weakest fit for a generic package.** It is Adam-specific fleet governance, not agent-harness runtime guidance.
5. **`eden-releases` is a blank slate.** There is no pre-existing `agent-harness/skills` package; any inclusion requires creating the directory structure and deciding the package manifest format.
6. **No source modifications were made** to either `yakovkhalinsky/eden-memory` or the active skill library.

---

## Recommended Next Steps

1. Confirm with Yakov whether `eden-releases/agent-harness/skills/` is the intended destination and what package manifest format (Hermes native, npm-style, etc.) should be used.
2. Decide whether the Go-rewrite content stays in `eden-memory-concurrency` or moves to `eden-memory-go-store`.
3. Decide whether `eden-relay` integration tests remain in scope; if the relay is not part of `eden-releases`, split that content out.
4. Revive `eden-memory-sync-verification` and `eden-memory-pairing-and-root-key` first — they provide the most transferable value.
5. Extract generic governance patterns from `eden-memory-coordination` rather than including the whole skill.
6. Update all absolute paths and private-repo references before committing to `eden-releases`.

---

*Report generated by Abel. No modifications were made to `yakovkhalinsky/eden-memory` or the active Adam skill library.*
