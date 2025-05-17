# flakes

*A single repo that gives you everything you need to **develop**, **test**, and **run** the Acme open‑source platform.*

> If you’re new, **clone this first**. One command will install all tools and clone every other repo you’ll touch.

---

## Why this repo exists

| What you get                                                       | Why it matters                                                                              |
| ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| **Reproducible tool‑chain** (Rust, Haskell, OCaml, JS, Terraform…) | No “works‑on‑my‑machine” issues – everyone builds with the same bits.                       |
| **Helper CLIs** (`onboard`, `sync-repos`, language shells)         | Zero‑friction onboarding and daily repo sync.                                               |
| **Repo catalogue** (`catalog/repos.yaml`)                          | Single source of truth for every service, library, and tool repo.                           |
| **Environment blueprints** (`infra/`)                              | Declarative specs (Proxmox, AWS, k8s) anyone can deploy if they want to run the full stack. |
| **Living documentation** (Org files)                               | Explanations + runnable examples side‑by‑side.                                              |

Everything is built, cached, and distributed by **one Nix flake** so workstations, computers, sensors, CI runners, servers, and clusters stay in lock‑step.

---

## Quick start

### 1. Developer workstation (≈3 min)

```bash
# clone the toolbox
git clone git@github.com:acme/nix-flake ~/code/toolbox && cd $_

# build tool‑chain and helper CLIs
nix run .#activate

# interactive onboarding (SSH key + GitHub login)
onboard

# clone / update all repos into ~/code/<kind>/<lang>/<repo>
sync-repos
```

### 2. Try the all‑in‑one Proxmox demo (≈10 min)

```bash
nix run .#provision.proxmox -- \
  --token $PM_TOKEN --target-node pve01
```

*(Full cloud deploy how‑to is in the docs.)*

---

## Directory map

```text
nix-flake/
├─ flake.{nix,lock}      ← all build definitions
├─ catalog/repos.yaml    ← repo list (kind + lang + path)
├─ pkgs/                 ← pure Nix packages & devShells
├─ infra/                ← environment blueprints (proxmox, aws, k8s)
├─ scripts/              ← post‑Nix wrappers & systemd timers
└─ docs/                 ← living documentation
```

---

## Documentation

| File                      | What you’ll find                                     |
| ------------------------- | ---------------------------------------------------- |
| **docs/01-overview\.org** | Big‑picture architecture & why this repo exists.     |
| **docs/02-workflows.org** | Step‑by‑step: bootstrap, daily update, contributing. |
| **docs/03-reference.org** | CLI flags, env vars, CI path filters.                |
| **docs/04-roadmap.org**   | Upcoming work & open ideas.                          |

Open the Org files in Emacs for runnable blocks (`C-c C-c`) or read the rendered HTML (updated nightly).

---

## Updating

1. **Tool‑chain change?** `git pull && nix run .#activate`
2. **Repo list change?** `git pull && sync-repos`
3. **Blueprint tweak?** `git pull && nix run .#provision.<env>`

Path-filtered CI ensures each commit runs only the jobs it needs.

---

## Contributing

1. Fork, branch, commit.
2. CI lints YAML and, if the flake files changed, runs `nix flake check`.<br>CI also dry‑runs `infra/` plans (no apply).
3. One approval from **@tooling‑owners** → merge.

Please keep catalogue edits and tool‑chain bumps in separate commits for easy rollback.

---

## License

MIT © Acme Corp – tooling & blueprints only. Individual service repos have their own licences; check each one.
