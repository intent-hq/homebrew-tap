# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.23 and the
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
  version "0.1.23"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.23/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "399ec82b5413a1b477c7e1eaeab086a4fe21130e6373625a6a487f136623436b"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.23/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "be47caf253e3f6e3b3ac1ee783e32ee0b8424f510f46e0adf5fa714908c6f06d"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.23/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "44612b3414247fdd5cff144b91204749ac89b9f1558e13422e500ab32d209d98"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.23/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "ed9d1156df8ea677cb0e846f89ad422e392f3a7beb0b1e000641840f3ec1ebd0"
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
