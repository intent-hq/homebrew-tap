# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.20 and the
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
  version "0.1.20"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.20/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "5b34eca6fa043fcbac2be0e07988a95fda1d8b657e4a14c8c95e21023a177d93"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.20/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "50fb8dcd8039208ae7fbeaa86630031c18917a8f836eb9408c15f01af63969bc"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.20/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "cacac5e8616737da2be9566a28a3c328c51061dad3cfc555e44a6ec5899b9869"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.20/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "23e527ff13e6b851acd4347cedf074edea3b768b48f1ef70f87a922df31f0432"
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
