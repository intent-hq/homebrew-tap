# homebrew-tap
Homebrew tap for Intent tools (intentd)

## Usage

```sh
brew tap intent-hq/homebrew-tap
brew install intentd
```

### Running as a service

```sh
brew services start intentd
```

This starts the daemon now **and** at every user login (launchd on macOS,
systemd on Linux). Boot-level (pre-login) start is out of scope. The service
relaunches the daemon if it crashes, but a clean exit — including
`brew services stop intentd` — does not relaunch it, mirroring intentd's own
LaunchAgent semantics. The Intent desktop app auto-detects and connects to the
brew-managed daemon on the default UDS socket.

## Maintenance

`Formula/intentd.rb` is regenerated and pushed by intentd's release CI
(cargo-dist), which overwrites hand-maintained edits such as the `service`
block. The [Ensure service block](.github/workflows/ensure-service-block.yml)
workflow re-inserts the block (via `scripts/ensure-service-block.rb`) whenever
the formula changes on `main`; running it when the block is present is a no-op.
