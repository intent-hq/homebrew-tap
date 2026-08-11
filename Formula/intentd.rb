# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.3 and the
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
  version "0.1.3"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.3/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "ac0c04d28cb23180e37bc531efb013555930035e0d438e2145619af2661cfe6a"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.3/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "7b0bf264ae779ae8ebcac13e77cdeacdb7987b027725eca953e898c0bb55643a"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.3/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "387f34a8364d1be2d3f6244e7027d7b91ee6f12b48a948c9acb3eed388f82c34"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.3/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "0d58020a62335fe11e278ec797c59b8f70c57d1d68e77e7fd5027965cf3d52af"
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
  # mirrors with exit 0) does not relaunch. --resume-all auto-resumes
  # interrupted agents, since this headless service has no desktop app
  # attached to resume them manually.
  service do
    run [opt_bin/"intentd", "serve", "--resume-all"]
    keep_alive crashed: true, successful_exit: false
    log_path var/"log/intentd.log"
    error_log_path var/"log/intentd.err.log"
  end

  test do
    system bin/"intentd", "--sitter-version"
  end
end
