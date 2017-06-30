Pod::Spec.new do |s|
  s.name            = "AXPhotoViewer"
  s.version         = "1.0-beta.8"
  s.license         = { :type  => 'MIT', :file => 'LICENSE.md' }
  s.summary         = "An iPhone/iPad photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/AXPhotoViewer"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/AXPhotoViewer.git", :tag => "v#{s.version}" }

  s.platform        = :ios, '9.0'
  s.requires_arc    = true

  s.default_subspec = 'Lite'

  s.subspec 'Core' do |cs|
    cs.dependency      'FLAnimatedImage', '>= 1.0.0'
    cs.source_files  = 'Source/Classes/*.{swift,h,m}',
                       'Source/Protocols/*.{swift,h,m}',
                       'Source/Extensions/*.{swift,h,m}',
                       'Source/Integrations/NetworkIntegration.swift'
    cs.frameworks    = 'UIKit', 'MobileCoreServices'
  end

  s.subspec 'Lite' do |ls|
    ls.frameworks    = 'ImageIO'
    ls.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_LITE_SUPPORT' }
    ls.dependency      'AXPhotoViewer/Core'
    ls.source_files  = 'Source/Integrations/SimpleNetworkIntegration.swift'
  end

  s.subspec 'SDWebImage' do |ss|
    ss.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_SDWEBIMAGE_SUPPORT' }
    ss.dependency      'AXPhotoViewer/Core'
    ss.source_files  = 'Source/Integrations/SDWebImageIntegration.swift'
    ss.dependency      'SDWebImage', '>= 4.0.0'
  end

  s.subspec 'PINRemoteImage' do |ps|
    ps.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_PINREMOTEIMAGE_SUPPORT' }
    ps.dependency      'AXPhotoViewer/Core'
    ps.dependency      'PINRemoteImage/FLAnimatedImage', '~> 3.0.0-beta.9'
    ps.source_files  = 'Source/Integrations/PINRemoteImageIntegration.swift'
  end

  s.subspec 'AFNetworking' do |as|
    as.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_AFNETWORKING_SUPPORT' }
    as.frameworks    = 'ImageIO'
    as.dependency      'AXPhotoViewer/Core'
    as.dependency      'AFNetworking', '>= 3.1.0'
    as.source_files  = 'Source/Integrations/AFNetworkingIntegration.swift'
  end
end
