# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.0 and the
# four {{SHA256_*}} values, computed from the built release archives.
#
# The archives ship the sitter — a self-updating supervisor shim renamed to
# `intentd` — which downloads, verifies, and runs the real daemon, forwarding
# all CLI args verbatim.
class Intentd < Formula
  desc "Self-updating supervisor shim for the Intent backend daemon"
  homepage "https://github.com/intent-hq/intentd"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd/releases/download/sitter-v0.1.0/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "ddc880d411d081a45fc2a38338e56d6a5eed46806d91bae38f4fd143e5d71714"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd/releases/download/sitter-v0.1.0/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "c29907b792965de7a435818502b1ec3057ae51c00e6d29c4800801553c84f583"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd/releases/download/sitter-v0.1.0/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "5edf282739486ee9d0a8d2f12fdb01567aa934971f97880332fa611ed048e164"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd/releases/download/sitter-v0.1.0/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "c696aa470070a311cc6f778e040a6bec6542934d334931cdc506ae934e2cfcd7"
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
