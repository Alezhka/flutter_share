#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'share'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for sharing content from the Flutter app via the platform share sheet.'
  s.description      = <<-DESC
A Flutter plugin for sharing content from the Flutter app via the platform share sheet.
                       DESC
  s.homepage         = 'https://github.com/Alezhka/flutter_share'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Aleksei Sturov' => 'alezhk@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  
  s.ios.deployment_target = '8.0'
end

