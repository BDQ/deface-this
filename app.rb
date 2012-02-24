#bundle exec ruby app.rb 
require 'bundler/setup'
require 'sinatra'
require 'erb'
require 'haml'
require 'deface'
require 'deface/haml_converter' #is conditionally loaded by deface
require 'coderay'
require 'json'
require 'nokogiri'
require 'rspec/mocks'
# require 'ruby-debug/debugger'

RSpec::Mocks::setup(self)
Rails = mock 'Rails'
Rails.stub :application => mock('application')
Rails.application.stub :config => mock('config')
Rails.application.config.stub :cache_classes => true
Rails.application.config.stub :deface => ActiveSupport::OrderedOptions.new
Rails.application.config.stub :deface => Deface::Environment.new
Rails.stub(:logger)
Rails.logger.stub(:info)
Rails.logger.stub(:error)

get '/' do
  erb :index
end

post '/deface' do
  html_highlighter = CodeRay::Duo[:html, :div]
  xml_highlighter = CodeRay::Duo[:xml, :div]
  ruby_highlighter = CodeRay::Duo[:rhtml, :div]


  original = if params["original_format"] == 'haml'
    haml_engine = Deface::HamlConverter.new( params["original"].clone)
    haml_engine.render
  else
    params["original"].clone
  end

  escaped = Deface::Parser.erb_markup!(original.clone)

  doc = if escaped =~ /<html.*?(?:(?!>)[\s\S])*>/
    Nokogiri::HTML::Document.parse(escaped)
  elsif escaped =~ /<body.*?(?:(?!>)[\s\S])*>/
    Nokogiri::HTML::Document.parse(escaped).css('body').first
  else
    Nokogiri::HTML::DocumentFragment.parse(escaped)
  end

  escaped = doc.to_s
  escaped.scan(/<code [\w\-]*>(.*)<\/code>/).each do |match|
    escaped.gsub!(match[0]) { |m| m = CGI.unescapeHTML match[0] }
  end

  result = {:escaped => ruby_highlighter.encode(escaped) }


  unless params["selector"].blank?
    open_selector = params["selector"].strip
    begin
      matches = doc.css(open_selector)
      result[:count] = matches.size
    rescue
      matches = []
      result[:count] = "Error"
    end

    unless params["closing_selector"].blank?
      begin
        combined_selector = "#{open_selector} ~ #{params["closing_selector"].strip}"
        matches = doc.css(combined_selector)
        result[:closing_count] = matches.size
      rescue
        matches = []
        result[:closing_count] = "Error"
      end
    end
  end

  if params["selector"].present?

    source = if params["replacement_format"] == 'haml'
      haml_engine = Deface::HamlConverter.new( params["source"].clone)
      haml_engine.render
    else
      params["source"].clone
    end

    if params["closing_selector"].present?
      Deface::Override.new(:virtual_path => "fake", :name => "fake",
                            params["action"].to_sym => params["selector"].strip,
                           :closing_selector => params["closing_selector"].strip,
                           :text => source)
    elsif params["action"].to_sym == :set_attributes
      attrs = Hash.new
      source.strip!
      source.gsub!(/\A\{/, '')
      source.gsub!(/\}\z/, '')

      source.split(',').each do |entry| 
        entryMap=entry.split(/=>/)

        value = entryMap[1].strip
        value.gsub!(/\A['"]/, '')
        value.gsub!(/['"]\z/, '')

        key = entryMap[0].strip.gsub(/\A:/, '')

        attrs[key.to_sym] = value
      end


      Deface::Override.new(:virtual_path => "fake", :name => "fake",
                            params["action"].to_sym => params["selector"].strip,
                           :attributes => attrs)

    else
      Deface::Override.new(:virtual_path => "fake", :name => "fake",
                            params["action"].to_sym => params["selector"].strip,
                           :text => source)
    end
    output = Deface::Override.apply(original, {:virtual_path => "fake"})


    result[:result] = ruby_highlighter.encode(output)

  end

  result.to_json
end
