# passage-run

Inject secrets from [passage](https://github.com/FiloSottile/passage) into environment variables at runtime, then exec a command. No plaintext secrets on disk.

Inspired by [`op run`](https://developer.1password.com/docs/cli/reference/commands/run/) from 1Password and [`sops exec-env`](https://github.com/getsops/sops), but for passage (the age-backed password manager).

## Why

`.env` files store secrets in plaintext on disk. `passage-run` replaces them with a reference file that maps variable names to passage paths — safe to commit, no secrets exposed.

```
# .env              (secrets on disk — bad)
API_KEY=sk-1234567890abcdef

# .env.passage      (references only — safe to commit)
API_KEY=ai/openai/api_key
```

## Install

Copy `passage-run` somewhere in your `$PATH`:

```bash
cp passage-run ~/.local/bin/
```

Or with Nix (flake):

```bash
nix run github:vdemeester/passage-run -- --help
```

Requires: `bash`, `passage`

## Usage

### With an env file

Create a `.env.passage` file mapping variable names to passage paths:

```bash
# .env.passage
OPENAI_API_KEY=ai/openai/api_key
SYNTHETIC_API_KEY=ai/synthetic.new/api_key
DATABASE_URL=services/postgres/url
```

Run a command with those secrets injected:

```bash
passage-run .env.passage -- my-app serve
passage-run .env.passage -- npm start
passage-run .env.passage -- pi --provider synthetic
```

### With inline mappings

```bash
passage-run -e API_KEY=ai/openai/api_key -- curl -H "Authorization: Bearer $API_KEY" ...
```

### Combined

```bash
passage-run .env.passage -e EXTRA_SECRET=path/to/secret -- my-app
```

Inline `-e` flags override values from the file.

### Options

```
-e VAR=path    Add a single mapping (can be repeated)
-f <file>      Env file to load (alternative to positional argument)
-q             Quiet: don't print status messages to stderr
-n             Dry run: show what would be exported without running the command
-p             Parallel: fetch secrets concurrently (faster, noisier errors)
-h, --help     Show help
```

### Dry run

See what would be injected without running anything:

```bash
$ passage-run .env.passage -n
# passage-run: would export the following variables:
export OPENAI_API_KEY=<51 chars>
export SYNTHETIC_API_KEY=<32 chars>
# then exec: my-app
```

## Env file format

```bash
# Comments (lines starting with #)
VARIABLE_NAME=passage/path/to/secret

# Inline comments are stripped
API_KEY=ai/openai/key  # this is ignored

# Variable names must be valid shell identifiers
MY_VAR_123=some/path
```

- One mapping per line: `VARIABLE_NAME=passage/path`
- Lines starting with `#` are comments
- Blank lines are ignored
- Only the first line of each passage entry is used (the password line)

## Examples

### Pi coding agent with Synthetic

```bash
# .env.passage.pi
SYNTHETIC_API_KEY=ai/synthetic.new/api_key
GEMINI_API_KEY=redhat/google/osp/vdeemest-api-key

# Run pi with secrets injected
passage-run .env.passage.pi -- pi --provider synthetic
```

### Docker Compose

```bash
passage-run .env.passage -- docker compose up
```

### Shell scripts

```bash
# In a wrapper script
#!/usr/bin/env bash
exec passage-run "$HOME/.env.passage.myapp" -- myapp "$@"
```

## How it works

1. Reads variable-to-path mappings from file and/or `-e` flags
2. Calls `passage show <path>` for each mapping
3. Exports the resolved values as environment variables
4. Uses `exec` to replace itself with your command

Secrets exist only in the process environment — never written to disk.

## See also

- [passage](https://github.com/FiloSottile/passage) — age-backed password manager
- [Stop Putting Secrets in .env Files](https://jonmagic.com/posts/stop-putting-secrets-in-dotenv-files/) — the blog post that inspired this pattern
- [`op run`](https://developer.1password.com/docs/cli/reference/commands/run/) — 1Password's equivalent
- [`sops exec-env`](https://github.com/getsops/sops) — SOPS's equivalent

## License

MIT
