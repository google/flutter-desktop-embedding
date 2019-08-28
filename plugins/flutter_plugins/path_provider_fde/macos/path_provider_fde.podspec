#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'path_provider_fde'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin for getting commonly used locations on the filesystem.'
  s.description      = <<-DESC
  A temporary macOS implmentation of the path_provider plugin from flutter/plugins.
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins/path_provider_fde'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

