Pod::Spec.new do |s|
  s.name            = "AXPhotoViewer"
  s.version         = "1.7.1"
  s.license         = { :type  => 'MIT', :file => 'LICENSE.md' }
  s.summary         = "An iOS/tvOS photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/AXPhotoViewer"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/AXPhotoViewer.git", :tag => "v#{s.version}" }

  s.requires_arc    = true

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |cs|
    cs.ios.dependency  'AXStateButton', '>= 1.1.3'
    cs.ios.dependency  'FLAnimatedImage', '>= 1.0.0'
    cs.tvos.dependency 'FLAnimatedImage-tvOS', '>= 1.0.16'
    cs.resources     = 'Assets/*.{xcassets}'
    cs.source_files  = 'Source/*.{swift,h,m}',
                       'Source/Classes/**/*.{swift,h,m}',
                       'Source/Protocols/*.{swift,h,m}',
                       'Source/Extensions/*.{swift,h,m}',
                       'Source/Utilities/*.{swift,h,m}',
                       'Source/Integrations/SimpleNetworkIntegration.swift'
    cs.frameworks    = 'ImageIO', 'UIKit', 'QuartzCore'
  end

  s.subspec 'SDWebImage' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.tvos.deployment_target = '9.0'
    ss.dependency      'AXPhotoViewer/Core'
    ss.dependency      'SDWebImage', '>= 4.0.0'
    ss.source_files  = 'Source/Integrations/SDWebImageIntegration.swift'
  end

  s.subspec 'PINRemoteImage' do |ps|
    ps.ios.deployment_target = '8.0'
    ps.tvos.deployment_target = '9.0'
    ps.dependency      'AXPhotoViewer/Core'
    ps.dependency      'PINRemoteImage', '~> 3.0.0-beta.9'
    ps.source_files  = 'Source/Integrations/PINRemoteImageIntegration.swift'
  end

  s.subspec 'AFNetworking' do |as|
    as.ios.deployment_target = '8.0'
    as.tvos.deployment_target = '9.0'
    as.dependency      'AXPhotoViewer/Core'
    as.dependency      'AFNetworking/NSURLSession', '>= 3.1.0'
    as.source_files  = 'Source/Integrations/AFNetworkingIntegration.swift'
  end

  s.subspec 'Kingfisher' do |ks|
    ks.ios.deployment_target = '10.0'
    ks.tvos.deployment_target = '10.0'
    ks.dependency      'AXPhotoViewer/Core'
    ks.dependency      'Kingfisher', '>= 3.10.0'
    ks.source_files  = 'Source/Integrations/KingfisherIntegration.swift'
  end

  s.subspec 'Nuke' do |nk|
    nk.ios.deployment_target = '10.0'
    nk.tvos.deployment_target = '10.0'
    nk.dependency      'AXPhotoViewer/Core'
    nk.dependency      'Nuke', '>= 7.0'
    nk.source_files  = 'Source/Integrations/NukeIntegration.swift'
  end
end
