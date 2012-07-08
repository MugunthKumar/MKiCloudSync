Pod::Spec.new do |s|
  s.name     = 'MKiCloudSync'
  s.version  = '1.0.2'
  s.license  = 'MIT'
  s.summary  = 'Sync your NSUserDefaults to iCloud automatically.'
  s.homepage = 'https://github.com/pandamonia/MKiCloudSync'
  s.author   = { 'Alexsander Akers' => 'a2@pandamonia.us',
                 'Mugunth Kumar' => 'contact@mk.sg' }
  s.source   = { :git => 'https://github.com/pandamonia/MKiCloudSync.git', :tag => 'v1.0.2' }
  s.platform = :ios
  s.source_files = 'MKiCloudSync.{h,m}'
  s.requires_arc = true
end
