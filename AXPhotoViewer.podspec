Pod::Spec.new do |s|
  s.name            = "AXPhotoViewer"
  s.version         = "1.4.3"
  s.license         = { :type  => 'MIT', :file => 'LICENSE.md' }
  s.summary         = "An iOS/tvOS photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/AXPhotoViewer"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/AXPhotoViewer.git", :tag => "v#{s.version}" }

  s.requires_arc    = true

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.default_subspec = 'Lite'

  s.subspec 'Core' do |cs|
    cs.ios.dependency  'AXStateButton', '>= 1.1.3'
    cs.ios.dependency  'FLAnimatedImage', '>= 1.0.0'
    cs.tvos.dependency 'FLAnimatedImage-tvOS', '>= 1.0.16'
    cs.resources     = 'Assets/*.{xcassets}'
    cs.source_files  = 'Source/*.{swift,h,m}',
                       'Source/Classes/**/*.{swift,h,m}',
                       'Source/Protocols/*.{swift,h,m}',
                       'Source/Extensions/*.{swift,h,m}',
                       'Source/Utilities/*.{swift,h,m}'
    cs.frameworks    = 'MobileCoreServices', 'UIKit', 'QuartzCore'
  end

  s.subspec 'Lite' do |ls|
    ls.frameworks    = 'ImageIO'
    ls.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_DEFAULT' }
    ls.dependency      'AXPhotoViewer/Core'
    ls.source_files  = 'Source/Integrations/SimpleNetworkIntegration.swift'
  end

  s.subspec 'SDWebImage' do |ss|
    ss.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_SDWEBIMAGE' }
    ss.dependency      'AXPhotoViewer/Core'
    ss.dependency      'SDWebImage', '>= 4.0.0'
    ss.source_files  = 'Source/Integrations/SDWebImageIntegration.swift'
  end

  s.subspec 'PINRemoteImage' do |ps|
    ps.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_PINREMOTEIMAGE' }
    ps.dependency      'AXPhotoViewer/Core'
    ps.dependency      'PINRemoteImage', '~> 3.0.0-beta.9'
    ps.source_files  = 'Source/Integrations/PINRemoteImageIntegration.swift'
  end

  s.subspec 'AFNetworking' do |as|
    as.frameworks    = 'ImageIO'
    as.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_AFNETWORKING' }
    as.dependency      'AXPhotoViewer/Core'
    as.dependency      'AFNetworking/NSURLSession', '>= 3.1.0'
    as.source_files  = 'Source/Integrations/AFNetworkingIntegration.swift'
  end

  s.subspec 'Kingfisher' do |ks|
    ks.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_KINGFISHER' }
    ks.dependency      'AXPhotoViewer/Core'
    ks.dependency      'Kingfisher', '>= 3.10.0'
    ks.source_files  = 'Source/Integrations/KingfisherIntegration.swift'
  end

  s.subspec 'Nuke' do |nk|
    nk.ios.deployment_target = '9.0'
    nk.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D USE_NUKE' }
    nk.dependency      'AXPhotoViewer/Core'
    nk.dependency      'Nuke', '>= 7.0'
    nk.source_files  = 'Source/Integrations/NukeIntegration.swift'
  end
end
