#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'shared_preferences_fde'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for reading and writing simple key-value pairs.'
  s.description      = <<-DESC
  A temporary macOS implmentation of the shared_preferences plugin from flutter/plugins.
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins/shared_preferences_fde'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

