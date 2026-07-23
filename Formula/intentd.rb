class Intentd < Formula
  desc "Intent backend daemon — local-first JSON-RPC daemon for the Intent domain model"
  homepage "https://github.com/intent-hq/intentd"
  version "0.2.0"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.0/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "49e1093144926adff7748532c47f4bbef01635625b5516b2973bb0f793d2bfdb"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.0/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "ca9ee7ac9f2b6576850cd7fa1eb1c45da0e8f5b8d6be5469ba9d21c38f46cef8"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.0/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "e65ce3fc4aa608df59c1fe82fdca1d90b232af5026dc5dcab2d77b8a5b75c1cf"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.2.0/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "eac9532fac30847865134260aa9045f5159eca3a9c374b3ff1cb16d87deec4ed"
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
