git_source = "git@gitlab.corp.21cake.com:iOS_Pods/LSNetworking.git"

Pod::Spec.new do |s|

  s.name         = "LSNetworking"
  s.version      = "0.0.1"
  s.summary      = "A short description of LSNetworking."

  s.description  = <<-DESC
                   A longer description of LSNetworking in Markdown format.

                   * Think: Why did you write this? What is the focus? What does it do?
                   * CocoaPods will be using this to generate tags, and improve search results.
                   * Try to keep it short, snappy and to the point.
                   * Finally, don't worry about the indent, CocoaPods strips it!
                   DESC

  s.homepage     = git_source
  s.license      = "MIT (example)"

  s.author       = { "张青宇" => "zhangqingyv@gmail.com" }

  s.platform     = :ios, "7.0"

  s.ios.deployment_target = "7.0"

  s.source       = { :git => git_source, :tag => "0.0.1" }

  s.requires_arc = true

  s.source_files = '*/{LS}*.{h,m}','*/{AF}*.{h,m}'

end
