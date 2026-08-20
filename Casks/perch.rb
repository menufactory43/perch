cask "perch" do
  version "1.0.0"
  sha256 "17f98c5bea58b2a5fbc4ec27d9d00dd3fa281099eeaf38c5c5a03dd2b48322a3"

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
