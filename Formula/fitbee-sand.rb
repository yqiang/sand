class FitbeeSand < Formula
  desc "Sand with additional Tart disks and a host free-space preflight"
  homepage "https://github.com/yqiang/sand"
  url "https://github.com/yqiang/sand/archive/e789f36d311ee0b12a9f5a1ff0dc5ec7f2840ca6.tar.gz"
  version "20261026.1"
  sha256 "7d2facab9e22c5d6fbe8cecd0ec13767b2b6e421326b7e6e02bc2c933a58a944"
  license "MIT"

  depends_on :macos
  depends_on "sshpass"
  depends_on "openai/tools/tart"

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release"
    bin.install ".build/release/sand" => "fitbee-sand"
  end

  service do
    run [opt_bin/"fitbee-sand", "run", "--config", "#{Dir.home}/.config/sand/config.yml"]
    keep_alive true
    process_type :interactive
    working_dir Dir.home
    log_path "#{Dir.home}/Library/Logs/fitbee-sand.log"
    error_log_path "#{Dir.home}/Library/Logs/fitbee-sand.log"
    environment_variables PATH: std_service_path_env, TART_NO_AUTO_PRUNE: "1"
  end

  test do
    system bin/"fitbee-sand", "--help"
  end
end
