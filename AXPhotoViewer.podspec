Pod::Spec.new do |s|
  s.name            = "AXPhotoViewer"
  s.version         = "1.0"
  s.license         = 'MIT'
  s.summary         = "An iPhone/iPad photo gallery viewer, useful for viewing a large number of photos."
  s.homepage        = "https://github.com/alexhillc/AXPhotoViewer"
  s.author          = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source          = { :git => "https://github.com/alexhillc/AXPhotoViewer.git", :tag => "v#{s.version}" }

  s.platform        = :ios, '10.0'
  s.requires_arc    = true

  s.source_files    = 'Source/Classes/*.{swift}',
                      'Source/Protocols/*.{swift}',
                      'Source/Extensions/*.{swift}',
                      'Source/Integrations/NetworkIntegration.swift'
  s.framework       = 'UIKit'
  s.dependency        'FLAnimatedImage', '~> 1.0.12'
  s.default_subspec = 'Lite'

  s.subspec 'Lite' do |lite|
    # subspec for users who don't want the added bloat of `SDWebImage`
    # or `AFNetworking` integrations; this can be useful if the developer
    # wishes to write their own async image downloading/caching logic
  end

  s.subspec 'SDWebImage' do |sdwi|
    sdwi.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_SDWI_SUPPORT' }
    sdwi.source_files  = 'Source/Classes/*.{swift}',
                         'Source/Protocols/*.{swift}',
                         'Source/Extensions/*.{swift}',
                         'Source/Integrations/SDWebImageIntegration.swift', 'Source/Integrations/NetworkIntegration.swift'
    sdwi.dependency      'SDWebImage', '~> 4.0.0'
  end

  s.subspec 'AFNetworking' do |afn|
    afn.xcconfig      = { 'OTHER_SWIFT_FLAGS' => '$(inherited) -D AX_AFN_SUPPORT' }
    afn.source_files  = 'Source/Classes/*.{swift}',
                        'Source/Protocols/*.{swift}',
                        'Source/Extensions/*.{swift}',
                        'Source/Integrations/AFNetworkingIntegration.swift', 'Source/Integrations/NetworkIntegration.swift'
    afn.dependency      'AFNetworking', '~> 3.1.0'
  end
end
