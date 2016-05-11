
Pod::Spec.new do |s|
  s.name         = "MXDataBasePoolManager"
  s.version      = "0.0.2"
  s.summary      = "MXDataBasePoolManager is a wrapper of FMDB"
  s.homepage     = "http://mmmmmax.wang/"
  s.license      = "MIT"
  s.author       = { "Max Wang" => "446964321@qq.com" }
  s.source       = { :git => "https://github.com/PangPangPangPangPang/MXDataBasePoolManager.git", :commit => "350b4604c2a5fac9996255106866700238d2fb87", :tag => "0.0.2" }
  s.source_files = "source/*.{h,m}"
  s.requires_arc = true
  s.platform     = :ios, '6.0'
  s.dependency "FMDB"
end