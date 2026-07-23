class Intentd < Formula
  desc "Intent backend daemon — local-first JSON-RPC daemon for the Intent domain model"
  homepage "https://github.com/intent-hq/intentd"
  version "0.2.1"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.1/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "bd597f02904872fbebc64ee4632d9d9c1bd73ed62e015a1d29ca547c25c6b44a"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.1/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "31a0ca99e3f183d5bcb3695a4778a92b5846f6dbdaa47cda36d931fe582de956"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.1/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "bbbd5824977d8b7295564e4abb9ec3d86908d2e6d49b009f7eae5caa4e60eda4"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.1/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "ba13e7152afbc421a1b156b2bd1f35f80df8062c8e80d91af2898061bb7c3ee5"
    end
  end

  BINARY_ALIASES = {
    "aarch64-apple-darwin":               {},
    "aarch64-unknown-linux-gnu":          {},
    "aarch64-unknown-linux-musl-dynamic": {},
    "aarch64-unknown-linux-musl-static":  {},
    "x86_64-apple-darwin":                {},
    "x86_64-pc-windows-gnu":              {},
    "x86_64-unknown-linux-gnu":           {},
    "x86_64-unknown-linux-musl-dynamic":  {},
    "x86_64-unknown-linux-musl-static":   {},
  }.freeze

  def target_triple
    cpu = Hardware::CPU.arm? ? "aarch64" : "x86_64"
    os = OS.mac? ? "apple-darwin" : "unknown-linux-gnu"

    "#{cpu}-#{os}"
  end

  def install_binary_aliases!
    BINARY_ALIASES[target_triple.to_sym].each do |source, dests|
      dests.each do |dest|
        bin.install_symlink bin/source.to_s => dest
      end
    end
  end

  def install
    bin.install "intentd" if OS.mac? && Hardware::CPU.arm?
    bin.install "intentd" if OS.mac? && Hardware::CPU.intel?
    bin.install "intentd" if OS.linux? && Hardware::CPU.arm?
    bin.install "intentd" if OS.linux? && Hardware::CPU.intel?

    install_binary_aliases!

    # Homebrew will automatically install these, so we don't need to do that
    doc_files = Dir["README.*", "readme.*", "LICENSE", "LICENSE.*", "CHANGELOG.*"]
    leftover_contents = Dir["*"] - doc_files

    # Install any leftover files in pkgshare; these are probably config or
    # sample files.
    pkgshare.install(*leftover_contents) unless leftover_contents.empty?
  end

  # `brew services start intentd` runs the daemon under launchd/systemd:
  # it starts now and at every user login (boot-level start is out of scope).
  # KeepAlive mirrors intentd's own LaunchAgent plist: relaunch on crash,
  # but a clean exit (`brew services stop intentd`) does not relaunch.
  # The Intent desktop app auto-detects and connects to the brew-managed
  # daemon on the default UDS socket. The WSS listener is governed by
  # config.toml (server.wsApi.enabled), not by CLI flags. --resume-all
  # auto-resumes interrupted agents, since this headless service has no
  # desktop app attached to resume them manually.
  service do
    run [opt_bin/"intentd", "serve", "--resume-all"]
    keep_alive crashed: true, successful_exit: false
    log_path var/"log/intentd.log"
    error_log_path var/"log/intentd.err.log"
  end
end
