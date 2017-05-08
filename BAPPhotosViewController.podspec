Pod::Spec.new do |s|
  s.name           = "BAPPhotosViewController"
  s.version        = "1.0"
  s.summary        = "An iPhone/iPad photo gallery viewer, useful for viewing a finite number of photos."
  s.homepage       = "https://github.com/alexhillc/BAPPhotosViewController"
  s.author         = { "Alex Hill" => "alexhill.c@gmail.com" }
  s.source         = { :git => "https://github.com/alexhillc/BAPPhotosViewController.git", :tag => "v#{s.version}" }

  s.platform       = :ios, '10.0'
  s.requires_arc   = true

  s.source_files   = 'Source/Classes/*.{swift}'
  s.framework      = 'UIKit'
end
