class Intentd < Formula
  desc "Intent backend daemon — local-first JSON-RPC daemon for the Intent domain model"
  homepage "https://github.com/intent-hq/intentd"
  version "0.1.2"
  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.1.2/intentd-aarch64-apple-darwin.tar.xz"
      sha256 "6ec58cac9120df7f4a947e56f805da0ee5cf80cd2db88cf42abaf3f3ad1b040e"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.1.2/intentd-x86_64-apple-darwin.tar.xz"
      sha256 "f0140e815347227305379c2d637243554ba83dd1f6720f0ffcc740840c481663"
    end
  end
  if OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/intent-hq/intentd/releases/download/v0.1.2/intentd-aarch64-unknown-linux-musl.tar.xz"
      sha256 "6756888ffccfb5aebb1a2c8ac92b0a077c077f6be18cdbbe3ec421a2bf589f1c"
    end
    if Hardware::CPU.intel?
      url "https://github.com/intent-hq/intentd/releases/download/v0.1.2/intentd-x86_64-unknown-linux-musl.tar.xz"
      sha256 "fc618bb49a8a328a5e9c3c73f26756a589f37a609212c68f95f1f2820c2354c9"
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
  # daemon on the default UDS socket.
  service do
    run [opt_bin/"intentd", "serve", "--listen", "uds"]
    keep_alive crashed: true, successful_exit: false
    log_path var/"log/intentd.log"
    error_log_path var/"log/intentd.err.log"
  end
end
