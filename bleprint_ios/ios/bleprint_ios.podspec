#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'bleprint_ios'
  s.version          = '0.0.1-dev.1'
  s.summary          = 'Bluetooth thermal printer plugin for Flutter'
  s.description      = <<-DESC
  An iOS implementation of the bleprint plugin.
                       DESC
  s.homepage         = 'https://github.com/dewinjm/bleprint'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Dewin J. Martinez' => 'dewin.martinez@gmail.com' }
  s.source           = { :path => '.' }  
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
