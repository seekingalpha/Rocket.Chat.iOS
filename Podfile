source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!
inhibit_all_warnings!

def shared_pods
  # Crash Report
  pod 'Fabric'
  pod 'Crashlytics'

  # Code utilities
  pod 'SwiftyJSON'
  pod 'semver'

  # UI
  pod 'SideMenuController', :git => 'https://github.com/rafaelks/SideMenuController.git'
  pod 'SlackTextViewController'
  pod 'MobilePlayer'
  pod 'URBMediaFocusViewController'

  # Text Processing
  pod 'TSMarkdownParser'

  # Database
  pod 'RealmSwift'

  # Network
  pod 'SDWebImage', '~> 3.8'
  pod 'Starscream', '~> 2.0.0'

  # Authentication SDKs
  pod '1PasswordExtension'
  pod 'Google/SignIn'
  pod 'Typhoon'
  pod 'AFNetworking', '~> 3.0'
end

target 'Rocket.Chat' do
  # Shared pods
  shared_pods
  pod 'RxSwift',    '~> 3.0'
  pod 'RxCocoa',    '~> 3.0'
end

target 'Rocket.ChatTests' do
  # Shared pods
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.1'
    end
  end
end
