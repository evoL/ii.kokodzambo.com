#-*- coding: utf-8 -*-
require 'kramdown'
require 'pygments.rb'
require 'tilt/template'

class HighlightedHTML < Kramdown::Converter::Html
  HIGHLIGHTING_AVAILABLE = false

  def convert_codeblock(el, indent)
    attr = el.attr.dup
    code = el.value

    data = code.partition("\n")
    matches = /^#!(\w+)/.match(data.first)

    if matches
      content = Pygments.highlight(data.last, :lexer => matches[1], :options => {:encoding => 'utf-8', :nowrap => true}).chomp << "\n"
      %Q{#{' '*indent}<pre#{html_attributes(attr)}><code class="language-#{matches[1]}">#{content}</code></pre>\n}
    else
      "#{' '*indent}<pre#{html_attributes(attr)}><code>#{code}\n</code></pre>\n"
    end
  end
end

class HighlightedKramdownTemplate < Tilt::Template
  DUMB_QUOTES = [39, 39, 34, 34]

  def self.engine_initialized?
    defined? ::Kramdown
  end

  def initialize_engine
    require_template_library 'kramdown'
  end

  def prepare
    options[:smart_quotes] = DUMB_QUOTES unless options[:smartypants]
    @engine = Kramdown::Document.new(data, options)
    @output = nil
  end

  def evaluate(scope, locals, &block)
    @output ||= HighlightedHTML.convert(@engine.root).first
  end

  def allows_script?
    false
  end
end
