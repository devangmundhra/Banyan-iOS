platform :ios, '7.0'

pod 'BNSwipeableView', :git => 'https://github.com/devangmundhra/BNSwipeableView.git'
pod 'MBProgressHUD', '>= 0.8'
#pod 'RestKit', :git => 'https://github.com/RestKit/RestKit.git', :branch => 'development'
pod 'RestKit', :path => '~/Developer/RestKit', :branch => 'paginator_fixes'
pod 'SDWebImage', :git => 'https://github.com/rs/SDWebImage.git', :commit => '282e8179193a49867575cd658ae64883aedbce7b'
pod 'VCTransitionsLibrary'
pod 'URBMediaFocusViewController', :git => 'https://github.com/u10int/URBMediaFocusViewController.git'
pod 'ECSlidingViewController'
pod 'MZFormSheetController'
pod 'ios-image-editor'
pod 'SPGooglePlacesAutocomplete', :git => 'https://github.com/devangmundhra/SPGooglePlacesAutocomplete.git', :commit => '24c94888a1892e7be7cc16275821663ec9fce8dd'
pod 'uservoice-iphone-sdk', '~> 3.0'
pod 'AFNetworking-TastyPie', :git => "https://github.com/rhfung/AFNetworking-TastyPie.git", :tag => "0.0.1"
pod 'TWMessageBarManager', '~> 1.3.2'
pod 'CMPopTipView', '~> 2.1.0'
pod 'MYBlurIntroductionView'
pod 'TTTAttributedLabel'
pod 'GoogleAnalytics-iOS-SDK'

# Testing and Search are optional components
# pod 'RestKit/Testing',  :git => 'https://github.com/RestKit/RestKit.git'
# pod 'RestKit/Search',  :git => 'https://github.com/RestKit/RestKit.git'

post_install do |installer_representation|
  installer_representation.project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ARCHS'] = 'armv7 armv7s'
    end
  end
end
