class FitbeeSand < Formula
  desc "Sand with additional Tart disks and a host free-space preflight"
  homepage "https://github.com/yqiang/sand"
  url "https://github.com/yqiang/sand/archive/d80e1b959fcb338e885f167274ee9ea7b8f697e1.tar.gz"
  version "20261026.2"
  sha256 "4d003e8bd78ef495f0233320b7982c15efdd77729dcb37a708fe1ce21b2b3869"
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
