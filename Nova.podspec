Pod::Spec.new do |s|
  s.name         = "Nova"
  s.version      = "0.0.8"
  s.summary      = "A lightweight HTML container."
  s.description  = "Nova is a lightweight HTML container for iOS that provides some native abilities to JavaScript in WKWebView."
  s.homepage     = "https://github.com/xnth97/Nova"
  s.license      = "MIT"
  s.author       = { "Yubo Qin" => "xnth97@live.com" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/xnth97/Nova.git", :tag => "#{s.version}" }
  s.source_files = "Nova", "Nova/**/*.{h,m}"
  s.frameworks   = "UIKit", "WebKit"
end
