require 'pry'
require 'toml-rb'
require 'erb'

module PageBuilder
  class Page
    def initialize
      @templates = {}
    end
    
    def render(name, locals={}, layout=nil)
      locals.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      if layout != nil
        @child = template(name).result(binding)
        return template(layout).result(binding)
      else
        return template(name).result(binding)
      end
    end

    def template(name)
      return @templates[name] if @templates.has_key? name
      #@templates[name] = ERB.new(File.read("./templates/#{name}.html.erb"), nil, nil, name)
      @templates[name] = ERB.new(File.read("./templates/#{name}.html.erb"))
      return @templates[name]
    end
  end

  class Executor
    def build
      posts = []
      Dir['posts/*'].each do |filename|
        begin
        post = process(filename, File.read(filename))
        posts.push post
        rescue => e
        end
      end
      tags = {}
      posts.each do |post|
        post[:tags].each do |tag|
          tags[tag] = [] if !tags.has_key? tag
          tags[tag].push post
        end
      end
      posts.each do |post|
        html = Page.new.render('post', {
          content: post[:content],
          title: post[:title],
          post: post,
          all_posts: posts }, 'layout')
        File.write("dist/posts/#{post[:filename]}", html)
      end
      tags.keys.each do |tag|
        html = Page.new.render('tag', {
          all_posts: posts,
          title: "`#{tag}` posts",
          tagged_posts: tags[tag],
          tag: tag, }, 'layout')
        File.write("dist/tags/#{tag}.html", html)
      end
    end

    def process(filename, content)
      front_matter = content[0..(content.index('----')-1)]
      content = content[(content.index('----')+5)..-1]
      post = TomlRB.parse(front_matter, symbolize_keys: true)
      post[:filename] = filename[filename.rindex('/')+1..-1]
      post[:content] = content
      post[:formatted_date] = post[:date].strftime("%B %e, %Y")
      return post
    end
  end
end
