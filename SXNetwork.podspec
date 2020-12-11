Pod::Spec.new do |s|
  s.name         = "SXNetwork"
  s.version      = "0.0.4"
  s.ios.deployment_target = '9.0'
  s.summary      = "基于AFNetworking再次封装的网络请求框架"
  s.homepage     = "https://github.com/LKeBing/SXNetwork"
  s.license      = "MIT"
  s.author       = { "LKeBing" => "13568922114@163.com" }
  s.source       = { :git => 'https://github.com/LKeBing/SXNetwork.git', :tag => s.version}
  s.requires_arc = true
  s.source_files = 'SXNetwork/*'
  s.dependency "AFNetworking"
end
