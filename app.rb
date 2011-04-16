require 'rubygems'
require 'sinatra'
require 'erb'
require 'deface'
require 'coderay'
require 'json'
require 'ruby-debug'

get '/' do
  erb :index
end

post '/deface' do
  html_highlighter = CodeRay::Duo[:html, :div]
  ruby_highlighter = CodeRay::Duo[:rhtml, :div]

  escaped = Deface::Parser.erb_markup!(params["original"].clone)
  doc = Nokogiri::HTML::DocumentFragment.parse(escaped)

  result = {:escaped => html_highlighter.encode(escaped) }

  unless params["selector"].blank?
    begin
      matches = doc.css(params["selector"].strip)
      result[:count] = matches.size
    rescue
      matches = []
      result[:count] = "Error"
    end
  end

  if !params["selector"].blank?

    Deface::Override.new(:virtual_path => "fake", :name => "fake",
                          params["action"].to_sym => params["selector"].strip,
                         :text => params["source"])

    output = Deface::Override.apply(params["original"], {:virtual_path => "fake"})


    result[:result] = ruby_highlighter.encode(output)

  end

  result.to_json
end
