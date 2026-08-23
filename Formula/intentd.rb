# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.7 and the
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
  version "0.1.7"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.7/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "05e440b18b4bf35279e3f405928bfcbdca3da9999fe5bd1904e2b93c3aa9a11c"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.7/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "efd27e8154b104ff8bc0bfab6aa1958ef3774ff52c05513584844ee36ddb52cb"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.7/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "311d7503098856c092b978403af6af99d925b96da8dce4a66326a613c02cc043"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.7/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "90623c4e01dea51edb2de28299b9ca04f641006f4bb34c9d489758d8e1b03635"
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
