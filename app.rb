require 'rubygems'
require 'sinatra'
require 'erb'
require 'deface'
require 'coderay'
require 'json'

get '/' do
  erb :index
end

post '/deface' do
  html_highlighter = CodeRay::Duo[:html, :div]
  ruby_highlighter = CodeRay::Duo[:rhtml, :div]

  escaped = Deface::Parser.erb_markup!(params["original"])
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

  if !params["action"].blank? && (!params["source"].blank? || params["action"] == "remove") && matches.count > 0
    matches.each do |match|
      replacement = case params["action"].to_sym
        when :remove
          ""
        when :replace
          params["source"].clone
        when :insert_before
          params["source"].clone << match.to_s
        when :insert_after
          match.to_s << params["source"].clone
      end

      match.replace Deface::Parser.convert_fragment replacement

    end

    result[:result] = ruby_highlighter.encode(Deface::Parser.undo_erb_markup!(doc.to_s))

  end

  result.to_json
end
