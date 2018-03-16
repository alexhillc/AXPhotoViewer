Pod::Spec.new do |s|
  s.name            = "AXPhotoViewer"
  s.version         = "1.4.0"
  s.license         = { :type  => 'MIT', :file => 'LICENSE.md' }
  s.summary         = "An iOS/tvOS photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/AXPhotoViewer"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/AXPhotoViewer.git", :tag => "v#{s.version}" }

  s.requires_arc    = true

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'

  s.subspec 'Core' do |cs|
    cs.ios.dependency  'AXStateButton', '>= 1.1.3'
    cs.ios.dependency  'FLAnimatedImage', '>= 1.0.0'
    cs.tvos.dependency 'FLAnimatedImage-tvOS', '>= 1.0.16'
    cs.resources     = 'Assets/*.{xcassets}'
    cs.source_files  = 'Source/*.{swift,h,m}',
                       'Source/Classes/**/*.{swift,h,m}',
                       'Source/Protocols/*.{swift,h,m}',
                       'Source/Extensions/*.{swift,h,m}',
                       'Source/Integrations/*.{swift,h,m}'
    cs.frameworks    = 'UIKit', 'MobileCoreServices', 'ImageIO'
  end

  s.subspec 'SDWebImage' do |ss|
    ss.dependency      'AXPhotoViewer/Core'
    ss.dependency      'SDWebImage', '>= 4.0.0'
  end

  s.subspec 'PINRemoteImage' do |ps|
    ps.dependency      'AXPhotoViewer/Core'
    ps.dependency      'PINRemoteImage', '~> 3.0.0-beta.9'
  end

  s.subspec 'AFNetworking' do |as|
    as.dependency      'AXPhotoViewer/Core'
    as.dependency      'AFNetworking/NSURLSession', '>= 3.1.0'
  end

  s.subspec 'Kingfisher' do |ks|
    ks.dependency      'AXPhotoViewer/Core'
    ks.dependency      'Kingfisher', '>= 3.10.0'
  end
end
