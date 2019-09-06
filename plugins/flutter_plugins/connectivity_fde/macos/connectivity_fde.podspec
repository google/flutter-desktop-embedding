#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'connectivity_fde'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for checking connectivity'
  s.description      = <<-DESC
  Temporary desktop implmentations of connectivity from flutter/plugins
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/flutter_plugins/connectivity_fde'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.dependency 'Reachability'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end
