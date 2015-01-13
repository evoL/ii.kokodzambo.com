require 'sinatra'
require 'haml'
require 'virtualfs'
require 'dotenv'
require 'mime/types'
require_relative 'codehighlight'
Dotenv.load

module Sinatra
  Tilt.register HighlightedKramdownTemplate, 'markdown', 'mkd', 'md'
end

Tilt.prefer HighlightedKramdownTemplate

def client; settings.client; end

configure do
  cache = VirtualFS::DalliCache.new(
    host: ENV['MEMCACHIER_SERVERS'],
    username: ENV['MEMCACHIER_USERNAME'],
    password: ENV['MEMCACHIER_PASSWORD'],
    expires_after: 1209600
  )
  set :client, VirtualFS::Github.new(user: ENV['GITHUB_USER'], repo: ENV['GITHUB_REPO'], cache: cache)
end

helpers do
  def toc
    entries = client.glob("*/*.md").reduce({}) do |hash, entry|
      category, article = entry.path.rpartition('.').first[1..-1].split('/')

      if hash.has_key? category
        hash[category] << article
      else
        hash[category] ||= [article]
      end

      hash
    end

    haml :toc, locals: {entries: entries}
  end
end

get '/' do
  file = client['index.md'].first
  markdown file.read, layout_engine: :haml
end

get '/*' do
  filename = params[:splat].first
  filename << '.md' unless filename =~ /\.[a-zA-Z]{1,6}\Z/

  file = client[filename].first

  return halt 404 if file.nil?
  return halt 403 if file.directory?

  @title, _, extension = file.name.rpartition('.')

  if extension == 'md'
    markdown file.read, layout_engine: :haml
  else
    types = MIME::Types::type_for(file.name)
    content_type (types.empty? ? 'text/plain' : types.first.to_s)

    file.read
  end
end
