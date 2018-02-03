Pod::Spec.new do |s|
  s.name         = 'FavIcon'
  s.version      = '2.0.0'
  s.summary      = 'A library for downloading website icons'
  s.homepage     = 'https://github.com/leonbreedt/FavIcon'
  s.license      = { :type => 'Apache', :file => 'LICENSE' }
  s.author       = { 'Leon Breedt' => 'leon@sector42.io' }

  s.source       = {
    :git => "https://github.com/leonbreedt/FavIcon.git",
    :tag => "#{s.version}"
  }

  s.source_files  = "Sources/FavIcon/*.{h,swift}"
  s.libraries = 'xml2'

  s.preserve_path = 'Sources/Clibxml2/module.modulemap'
  s.module_map = 'Sources/Clibxml2/module.modulemap'

  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"

  s.requires_arc = true

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '4.0', 
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/FavIcon/Clibxml2'
  }
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2 $(PODS_ROOT)/FavIcon/Clibxml2'
  }
end
