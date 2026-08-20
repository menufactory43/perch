cask "perch" do
  version "1.0.1"
  sha256 "04712a680e75bf5abadecac8128a86891ce1015f1faf12e2e7e3fb445e95ecae"

  url "https://github.com/menufactory43/perch/releases/download/v#{version}/Perch-#{version}.dmg"
  name "Perch"
  desc "Share local speech models across Mac apps using APFS clones"
  homepage "https://github.com/menufactory43/perch"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Perch.app"

  zap trash: [
    "~/Library/Application Support/Perch",
    "~/Library/Preferences/com.fauconnier.perch.plist",
  ]

  caveats <<~EOS
    Grant Full Disk Access to Perch (System Settings → Privacy & Security).
    Click + to add Perch; it does not appear in the list until you do.
  EOS
end
