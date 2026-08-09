# Hand-maintained template for the `intentd` Homebrew formula, rendered by
# scripts/render-sitter-homebrew-formula.sh and pushed to
# intent-hq/homebrew-tap by .github/workflows/release-sitter.yml (replacing
# the cargo-dist generated daemon formula). Placeholders: 0.1.1 and the
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
  version "0.1.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.1/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "993bd8dbec468a7fb21e314611a823d1094cca623d4fbf7ca8db7c732f3fdf8e"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.1/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "d31f7b781f099ce63e855e4f61720e811df19d79cea662b0aef45ff24e6f6317"
    end
  end

  # The musl archives are fully static, so they run on any Homebrew-on-Linux
  # host regardless of glibc version.
  on_linux do
    on_arm do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.1/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "569b2c466425830900157751334a8bfd0fbb63ab26113129d01456f23fc9d586"
    end
    on_intel do
      url "https://github.com/intent-hq/intentd-releases/releases/download/sitter-v0.1.1/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "aba5f6efd74529d6d194a5304b1a44a4c16c809b713ef8e2613a5fcab7b8bff4"
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
