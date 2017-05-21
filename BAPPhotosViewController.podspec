# BAPPhotosViewController.podspec
Pod::Spec.new do |s|
  s.name            = "BAPPhotosViewController"
  s.version         = "1.0"
  s.license         = 'MIT'
  s.summary         = "An iPhone/iPad photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/BAPPhotosViewController"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/BAPPhotosViewController.git", :tag => "v#{s.version}" }

  s.platform        = :ios, '10.0'
  s.requires_arc    = true

  s.source_files    = 'Source/Classes/*.{swift}'
  s.framework       = 'UIKit'
  s.dependency        'FLAnimatedImage', '~> 1.0.12'
  s.default_subspec = 'Lite'

  s.subspec 'Lite' do |lite|
    # subspec for users who don't want the added bloat of `SDWebImage`
    # or `AFNetworking` integrations; this can be useful if the developer
    # wishes to write their own async image downloading/caching logic
  end

  s.subspec 'SDWebImage' do |sdwi|
    sdwi.xcconfig      = { 'OTHER_CFLAGS' => '$(inherited) -BAP_SDWI_SUPPORT' }
    sdwi.source_files  = 'Source/Classes/*.{swift}', 'Source/Integrations/SDWebImageIntegration.swift'
    sdwi.dependency      'SDWebImage', '~> 4.0.0'
  end

  s.subspec 'AFNetworking' do |afn|
    afn.xcconfig      = { 'OTHER_CFLAGS' => '$(inherited) -BAP_AFN_SUPPORT' }
    afn.source_files  = 'Source/Classes/*.{swift}', 'Source/Integrations/AFNetworkingIntegration.swift'
    afn.dependency      'AFNetworking', '~> 3.1.0'
  end
end
