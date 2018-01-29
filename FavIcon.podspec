Pod::Spec.new do |s|
  s.name             = 'FavIcon'
  s.version          = '2.0.0'
  s.summary          = 'Library for downloading the icon representing a website.'

  s.description      = <<-DESC
Downloads the icon representing a website, supporting the various ad-hoc standards that exist for
such icons.

- /favicon.ico
- <link> or <meta> tags that use Apple, Google, or Microsoft conventions
- discovery and parsing of Web Application manifest JSON files
- discovery of browser configuration XML files
                       DESC

  s.homepage         = 'https://github.com/leonbreedt/FavIcon'
  s.license          = { :type => 'Apache', :file => 'LICENSE' }
  s.author           = { 'leonbreedt' => 'leon@sector42.io' }
  s.source           = { :git => 'https://github.com/leonbreedt/FavIcon.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/oberstal'

  s.ios.deployment_target = '10.0'

  s.source_files = 'FavIcon/**/*'
end
