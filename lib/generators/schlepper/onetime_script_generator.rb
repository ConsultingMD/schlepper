class SchlepperTask < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def onetime_script
    @now = Time.now
    template 'onetime_script.rb.erb', "script/schleppers/#{stringified_timestamp}_#{file_name}.rb"
  end

  def stringified_timestamp
    @now.strftime '%Y%m%d%H%M%S'
  end
end
