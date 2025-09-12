class Tagcache < Formula
  desc "Lightweight, sharded, tag-aware in-memory cache server"
  homepage "https://github.com/aminshamim/tagcache"
  version "1.0.8"
  license "MIT"
  
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-x86_64.tar.gz"
      sha256 "f758717c58123b39f85f54ee87c410caf838043c5bd980c0c49eacefef3867b6"
    end
    if Hardware::CPU.arm?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-arm64.tar.gz"
      sha256 "42fc75f2da7bee044d0b8680fc11ed5325d041a9de3c5d9d2deb3139d8a527fe"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-linux-x86_64.tar.gz"
      sha256 "2cd7b3d12b23a1e48f50959781b787d7d0ca3b1aaaa76158f2a75d643bba0340"
    end
    if Hardware::CPU.arm? && Hardware::CPU.arch == :arm64
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-linux-arm64.tar.gz"
      sha256 "40d897590b278fb6aa0eda2a7f778dabf4e7a187b32a6478636da25f19566050"
    end
  end

  def install
    # Use pre-built binaries for all supported platforms
    bin.install "tagcache"
    bin.install "bench_tcp"
    
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
    # Test that the binaries exist and show help
    system "#{bin}/tagcache", "--help"
    system "#{bin}/bench_tcp", "--help"
    
    # Test that we can start the server and it responds
    port = free_port
    tcp_port = free_port
    
    # Start tagcache server in background
    pid = spawn "#{bin}/tagcache", 
                env: { "PORT" => port.to_s, "TCP_PORT" => tcp_port.to_s }
    sleep 3
    
    begin
      # Try to connect to the HTTP health endpoint
      system "curl", "-f", "http://localhost:#{port}/health"
    ensure
      Process.kill("TERM", pid)
      Process.wait(pid)
    end
  end
end
