#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'path_provider_fde'
  s.version          = '0.0.1'
  s.summary          = 'No-op implementation of path_provider_fde desktop plugin to avoid build issues on iOS'
  s.description      = <<-DESC
temp fake path_provider_fde plugin
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/path_provider_fde'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.deployment_target = '8.0'
end

