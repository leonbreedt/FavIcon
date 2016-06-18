def run(command)
  system(command) or raise "command failed: #{command}"
end

version = `git describe --tags`

task :doc do
  run "jazzy --author 'Leon Breedt' --swift-version 3.0 --module-version #{version}"
end

namespace "test" do
  desc "Run iOS unit tests"
  task :ios do |t|
    run "xcodebuild -project FavIcon.xcodeproj -scheme FavIcon-iOS -destination 'platform=iOS Simulator,name=iPhone 6s' clean test"
  end

  desc "Run OS X unit tests"
  task :osx do |t|
    run "xcodebuild -project FavIcon.xcodeproj -scheme FavIcon-OSX clean test"
  end
end

task default: ["test:ios", "test:osx"]
