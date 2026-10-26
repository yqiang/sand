class FitbeeSand < Formula
  desc "Sand with additional Tart disks and a host free-space preflight"
  homepage "https://github.com/yqiang/sand"
  url "https://github.com/yqiang/sand/archive/355557ec9e5dd68c69b6b08849d5224fd541399b.tar.gz"
  version "20261026.1"
  sha256 "82f03d820cb7630117d4121f8da0e879f47f53db9119cb62862d0a17c3555e43"
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
