#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'color_panel'
  s.version          = '0.0.2'
  s.summary          = 'Provides access to the macOS color picker.'
  s.description      = <<-DESC
Provides access to the macOS color picker.
                       DESC
  s.homepage         = 'https://github.com/google/flutter-desktop-embedding/tree/master/plugins/color_panel'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Flutter Desktop Embedding Developers' => 'flutter-desktop-embedding-dev@googlegroups.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx
  s.osx.deployment_target = '10.11'
end

