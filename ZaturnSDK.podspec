Pod::Spec.new do |spec|
  spec.name                  = "ZaturnSDK"
  spec.version               = "0.0.1"
  spec.summary               = "."
  spec.homepage              = "https://github.com/airgap-it/zaturn-ios-sdk"
  spec.license               = { :type => "MIT", :file => "LICENSE" }
  spec.author                = { "Julia Samol" => "j.samol@papers.ch" }
  spec.ios.deployment_target = '13.0'
  spec.swift_version         = '5.0'
  spec.source                = { :git => "https://github.com/airgap-it/zaturn-ios-sdk", :tag => "#{spec.version}" }
  spec.source_files          = "Sources/**/*.{swift}"
  spec.dependency            'Sodium', '~> 0.9.1'
  spec.dependency            'SwiftySSS', '~> 0.0.1'
  spec.dependency            'GoogleSignIn', '~> 6.0.0'
  
  spec.compiler_flags        = '-Xswiftc COCOAPODS'
end

