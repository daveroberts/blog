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
      @templates[name] = ERB.new(File.read("./templates/#{name}"))
      return @templates[name]
    end
  end

  class Executor
    def build
      posts = []
      Dir['posts/*'].each do |filename|
        begin
        post = process(filename, File.read(filename))
        next if post[:draft]
        posts.push post
        rescue => e
          puts "Error found when processing #{filename}"
          raise e
        end
      end
      tags = {}
      posts.each do |post|
        post[:tags].each do |tag|
          tags[tag] = [] if !tags.has_key? tag
          tags[tag].push post
        end
      end
      posts = posts.sort{|a,b|a[:date]<=>b[:date]}.reverse
      posts.each do |post|
        html = Page.new.render('post.html.erb', {
          title: post[:title],
          post: post,
          all_posts: posts }, 'layout.html.erb')
        File.write("dist/posts/#{post[:filename]}", html)
      end
      tags.keys.each do |tag|
        html = Page.new.render('tag.html.erb', {
          all_posts: posts,
          title: "`#{tag}` posts",
          tagged_posts: tags[tag],
          tag: tag, }, 'layout.html.erb')
        File.write("dist/tags/#{tag}.html", html)
      end
      html = Page.new.render('index.html.erb', {
          all_posts: posts,
          title: "Blog" }, 'layout.html.erb')
      File.write("dist/index.html", html)
      rss = Page.new.render('rss.xml.erb', {
          all_posts: posts, })
      File.write("dist/rss.xml", rss)
    end

    def process(filename, content)
      front_matter = content[0..(content.index('----')-1)]
      content = content[(content.index('----')+5)..-1]
      post = TomlRB.parse(front_matter, symbolize_keys: true)
      post[:filename] = filename[filename.rindex('/')+1..-1]
      post[:content] = content
      post[:formatted_date] = post[:date].strftime("%B %e, %Y")
      post[:formatted_short_date] = post[:date].strftime("%Y-%m-%d")
      post[:pub_date] = post[:date].strftime("%a, %d %b %Y %H:%M:%S %Z")
      #Sun, 19 May 2002 15:21:36 GMT
      return post
    end
  end
end
