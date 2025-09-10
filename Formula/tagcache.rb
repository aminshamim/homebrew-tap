class Tagcache < Formula
  desc "Lightweight, sharded, tag-aware in-memory cache server"
  homepage "https://github.com/aminshamim/tagcache"
  version "1.0.5"
  license "MIT"
  
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-x86_64.tar.gz"
      sha256 "6d8e4b20abd0c0d2ac17b938fbb032d0bada06022f2c2c47a25b2ace319a9e9f"
    end
    if Hardware::CPU.arm?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-arm64.tar.gz"
      sha256 "9ca5c0a242bfe151b7ccd739e56b58fb52b73ca49d7522116fe14bc55d1ed948"
    end
  end

  on_linux do
    # Linux binaries will be available in future releases
    # For now, build from source on Linux
    depends_on "rust" => :build
  end

  def install
    if OS.linux?
      # Build from source on Linux
      system "cargo", "build", "--release"
      bin.install "target/release/tagcache"
    else
      # Use pre-built binary on macOS
      bin.install "tagcache"
    end
    
    # Install example configuration
    (etc/"tagcache").mkpath
    (var/"lib/tagcache").mkpath
    (var/"log/tagcache").mkpath
  end

  service do
    run [opt_bin/"tagcache"]
    environment_variables PORT: "8080", TCP_PORT: "1984", NUM_SHARDS: "16"
    keep_alive true
    log_path var/"log/tagcache/tagcache.log"
    error_log_path var/"log/tagcache/tagcache.log"
    working_dir var/"lib/tagcache"
  end

  test do
    # Test that the binary exists and shows help
    system "#{bin}/tagcache", "--help"
    
    # Test that we can start the server and it responds
    port = free_port
    pid = spawn "#{bin}/tagcache", "PORT=#{port}", "TCP_PORT=#{port + 1}"
    sleep 2
    
    begin
      # Try to connect to the HTTP endpoint
      system "curl", "-f", "http://localhost:#{port}/stats"
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
