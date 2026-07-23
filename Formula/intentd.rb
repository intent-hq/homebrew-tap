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
end
