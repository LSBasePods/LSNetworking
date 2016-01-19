git_source = "git@gitlab.corp.21cake.com:iOS_Pods/LSNetworking.git"

Pod::Spec.new do |s|

  s.name         = "LSNetworking"
  s.version      = "0.0.1"
  s.summary      = "A short description of LSNetworking."

  s.homepage     = git_source
  s.license      = "MIT (example)"

  s.author       = { "张青宇" => "zhangqingyv@gmail.com" }

  s.platform     = :ios, "7.0"

  s.ios.deployment_target = "7.0"

  s.source       = { :git => git_source, :tag => "0.0.1" }

  s.requires_arc = true

  s.subspec 'AFNetworking' do |ss|
    ss.source_files = 'AFNetworking/*.{h,m}'
  end

  s.subspec 'LSNetworking' do |ss|
    ss.source_files = 'LSNetworking/*.{h,m}'
  end

end
