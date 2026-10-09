# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.24 and the
# four {{SHA256_*}} values, computed from the built release archives.
#
# The archives ship the sitter — a self-updating supervisor shim renamed to
# `intentd` — which downloads, verifies, and runs the real daemon, forwarding
# all CLI args verbatim.
#
# Download URLs point at the public intent-hq/intentd-releases mirror (the
# temporary public home for release assets until intent-hq/intentd is
# open-sourced); release-sitter.yml mirrors the identical archives there, so
# the sha256s computed from the built artifacts still match.
class Intentd < Formula
  desc "Self-updating supervisor shim for the Intent backend daemon"
  homepage "https://github.com/intent-hq/intentd"
  version "0.1.24"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.24/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "3a96fb42aae0b273cc8583dd45d278aef3c0f214e067d662588df4b5378bf19c"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.24/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "212d18d91ab5ad1ad8761e97e8398fe710c8fcecd7db25eb581ef48d3efc7ed8"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.24/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "97c746c8cad0263f2423a4a91e6019bb1fd0247cd11f58762da6bdff8e3a0611"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.24/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "a5cfc17935698fc0a142131e06f34ec16401c5acfaead77c0e5fff9b59913335"
    end
  end

  def install
    bin.install "intentd"
  end

  # `brew services start intentd` runs the sitter under launchd/systemd: it
  # starts now and at every user login, matching the previous daemon formula.
  # The sitter supervises the daemon itself (updates + crash respawn);
  # keep_alive covers the sitter process: relaunch on crash, but a clean exit
  # (`brew services stop intentd`, or a clean daemon shutdown the sitter
  # mirrors with exit 0) does not relaunch. Startup auto-resume of interrupted
  # agents is governed by the agents.resumeInterruptedOnStart setting (default
  # auto: resume only on headless hosts, so servers keep resuming while desktop
  # hosts leave it to the app's prompt) — toggle it with
  # `intentd settings agents.resumeInterruptedOnStart on|off`. Note: on Linux
  # the brew service is a systemd user unit that runs without the session's
  # DISPLAY/WAYLAND_DISPLAY, so `auto` treats it as headless and resumes even
  # on a desktop (use `off` to opt out); macOS launchd agents count as having
  # a display.
  service do
    run [opt_bin/"intentd", "serve"]
    keep_alive crashed: true, successful_exit: false
    log_path var/"log/intentd.log"
    error_log_path var/"log/intentd.err.log"
  end

  test do
    system bin/"intentd", "--sitter-version"
  end
end
