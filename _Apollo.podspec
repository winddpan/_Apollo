Pod::Spec.new do |s|
  s.name        = "_Apollo"
  s.version     = "1.0.0"
  s.summary     = "_Apollo"

  s.description = <<-DESC
                   dylib injection protector
                   DESC

  s.homepage    = "https://github.com/winddpan/_Apollo"
  s.license     = { :type => "MIT", :file => "LICENSE" }
  s.authors     = { "winddpan" => "winddpan@126.com" }

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source          = { :git => "https://github.com/winddpan/_Apollo.git" }
  s.source_files    = "_Apollo/*.{h,m}"
  s.requires_arc    = true
end
