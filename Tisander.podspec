Pod::Spec.new do |s|
  s.name             = 'Tisander'
  s.version          = '1.0.0'
  s.summary          = 'A pure Swift ordered JSON parser.'
  s.description      = <<-DESC
A JSON parsing library written in pure Swift. It's all stored in a structure of arrays so it's ordered, and convertable to a String.
                       DESC

  s.homepage         = 'https://mikezs.github.io/Tisander'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Mike Bignell' => 'mike@mbignell.com' }
  s.source           = { :git => 'https://github.com/mikezs/Tisander.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mikebignell'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.1'

  s.source_files = 'Source/*.swift'
  
end
