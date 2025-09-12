class Tagcache < Formula
  desc "Lightweight, sharded, tag-aware in-memory cache server"
  homepage "https://github.com/aminshamim/tagcache"
  version "1.0.8"
  license "MIT"
  
  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-x86_64.tar.gz"
      sha256 "c0cdf954c7f3c3b0f6798dd2c33b39f22170a0d9593fa61441b698c8c21f6e61"
    end
    if Hardware::CPU.arm?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-macos-arm64.tar.gz"
      sha256 "ba3fa5478942964c33c286e5b8061b406db3133b4ed8609b5450fa6788c8a0ad"
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-linux-x86_64.tar.gz"
      sha256 "500665f82d6b8b9dbe375872f6d99335bf296ae5fe02c513e3d5b5e7a2cefb14"
    end
    if Hardware::CPU.arm? && Hardware::CPU.arch == :arm64
      url "https://github.com/aminshamim/tagcache/releases/download/v#{version}/tagcache-linux-arm64.tar.gz"
      sha256 "4cdbffc5d9beebf3a10497f21a25503354dcb1465784ea437b2d7bbba396a96c"
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
