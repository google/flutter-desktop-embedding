#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'url_launcher_fde'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for launching a URL.'
  s.description      = <<-DESC
  A temporary macOS implmentation of the url_launcher plugin from flutter/plugins.
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins/url_launcher_fde'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

